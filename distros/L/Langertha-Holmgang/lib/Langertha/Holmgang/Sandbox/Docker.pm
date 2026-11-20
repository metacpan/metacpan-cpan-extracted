package Langertha::Holmgang::Sandbox::Docker;
# ABSTRACT: Runs one real program on a copy of a device's files in a locked-down container

use Moose;
use namespace::autoclean;
use Archive::Tar ();
use Archive::Tar::Constant ();
use Carp qw( croak );
use File::Temp ();
use JSON::MaybeXS ();
use POSIX ();
use Time::HiRes ();

our $VERSION = '0.002';


my $JSON = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

has image => ( is => 'ro', isa => 'Str', default => 'langertha-holmgang-sandbox:1' );


has docker => ( is => 'ro', isa => 'ArrayRef[Str]', default => sub { ['docker'] } );


has timeout => ( is => 'ro', isa => 'Int', default => 10 );


has memory => ( is => 'ro', isa => 'Str', default => '512m' );
has cpus   => ( is => 'ro', isa => 'Str', default => '1' );
has pids   => ( is => 'ro', isa => 'Int', default => 128 );


has max_output => ( is => 'ro', isa => 'Int', default => 262144 );
has max_file   => ( is => 'ro', isa => 'Int', default => 1048576 );
has max_new    => ( is => 'ro', isa => 'Int', default => 200 );


has log => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );


sub take_log {
  my ( $self ) = @_;
  my @l = splice @{ $self->log };
  return @l;
}


# the scan roots for new files: where a program of a server writes, never the
# system directories of the image
my @SCAN = qw( /etc /srv /opt /home /root /tmp /var /usr/local /run /mnt /data );

# The driver inside the container. Plain perl of perl-base: no module beyond
# the core of a minimal Debian.
my $DRIVER = <<'DRIVER';
use strict; use warnings;
my %J; { open my $h, q{<}, q{/.hg/job} or die "job: $!"; while (<$h>) { chomp; my ( $k, $v ) = split /=/, $_, 2; $J{$k} = pack q{H*}, $v // q{} } }
my @argv = split /\0/, $J{argv};
my @scan = grep { -d } split /\0/, $J{scan};
my %sent = map { $_ => 1 } split /\0/, ( $J{sent} // '' );
sub listing {
  my %f; my @todo = @scan;
  while ( defined( my $d = shift @todo ) ) {
    opendir my $dh, $d or next;
    for my $n ( readdir $dh ) {
      next if $n eq '.' || $n eq '..';
      my $p = "$d/$n";
      if ( -l $p ) { $f{$p} = 'l' } elsif ( -d _ ) { push @todo, $p } elsif ( -f _ ) { $f{$p} = 'f' }
    }
  }
  return \%f;
}
sub finish {
  my (%r) = @_;
  open my $h, '>', '/.hg/result' or die "result: $!";
  print $h map { "$_=" . unpack( q{H*}, $r{$_} // q{} ) . "\n" } grep { !/\A_/ } sort keys %r;
  close $h;
  my @list = ( '/.hg/result', ( -e '/.hg/out' ? '/.hg/out' : () ), @{ $r{_files} || [] } );
  open my $l, '>', '/.hg/list' or die "list: $!";
  print $l join( "\0", @list );
  close $l;
  exec 'tar', '-cf', '-', '--null', '-P', '--no-recursion', '-T', '/.hg/list';
  die "tar: $!";
}
my ($prog) = $argv[0] =~ m{/} ? ( -x $argv[0] ? $argv[0] : () ) : grep { -x && !-d _ } map { "$_/$argv[0]" } split /:/, $J{path};
finish( unavailable => "$argv[0] is not in the image" ) unless defined $prog;
my $pre = listing();
my ($fake) = glob '/usr/lib/*/faketime/libfaketime.so.1';
my $pid = fork // die "fork: $!";
if ( !$pid ) {
  chdir $J{cwd} or chdir '/';
  open STDIN, '<', '/.hg/stdin' or die "stdin: $!";
  open STDOUT, '>', '/.hg/out' or die "out: $!";
  open STDERR, '>&', \*STDOUT or die "err: $!";
  %ENV = ( PATH => $J{path}, HOME => '/root', USER => 'root', LOGNAME => 'root', SHELL => '/bin/bash', LANG => q{C.UTF-8}, PYTHONUNBUFFERED => 1,
    HOSTNAME => $J{host}, TZ => $J{tz}, map { split /=/, $_, 2 } grep { /=/ } split /\0/, ( $J{env} // '' ) );
  if ( defined $fake && length $J{now} ) { $ENV{LD_PRELOAD} = $fake; $ENV{FAKETIME} = '@' . $J{now}; $ENV{FAKETIME_DONT_RESET} = 1 }
  exec {$prog} @argv or do { print "bash: $argv[0]: cannot execute\n"; exit 126 };
}
my $rc;
my $done = eval {
  local $SIG{ALRM} = sub { die "timeout\n" };
  alarm $J{timeout};
  waitpid $pid, 0;
  alarm 0;
  $rc = $? & 127 ? 128 + ( $? & 127 ) : $? >> 8;
  1;
};
if ( !$done ) { kill 'KILL', $pid; waitpid $pid, 0; $rc = 124 }
my $post = listing();
my ( @files, @deleted, $new );
for my $p ( sort keys %$post ) {
  next unless $sent{$p} || !$pre->{$p};
  $new++ unless $sent{$p};
  finish( unavailable => "the program left more than $J{max_new} new files" ) if ( $new // 0 ) > $J{max_new};
  finish( unavailable => "the program left a file of more than $J{max_file} bytes: $p" ) if $post->{$p} eq 'f' && -s $p > $J{max_file};
  push @files, $p;
}
@deleted = grep { !-e $_ && !-l $_ } sort keys %sent;
finish( rc => $rc, deleted => join( "\0", @deleted ), clock => ( defined $fake && length $J{now} ? 'sim' : 'real' ), _files => \@files );
DRIVER

sub _job {
  my (%j) = @_;
  return join( q{}, map { $_.q{=}.unpack( q{H*}, _bytes( $j{$_} ) )."\n" } sort keys %j );
}

sub _unjob {
  my ( $t ) = @_;
  return map { my ( $k, $v ) = split /=/, $_, 2; ( $k => pack( q{H*}, $v // q{} ) ) } split /\n/, $t;
}

sub _bytes { my ( $s ) = @_; $s = '' unless defined $s; utf8::encode($s) if utf8::is_utf8($s); return $s }

sub _chars { my ( $s ) = @_; my $c = $s; return utf8::decode($c) ? $c : $s }

my $SEQ = 0;

sub run {
  my ( $self, %a ) = @_;
  my @argv = @{ $a{argv} || [] };
  croak __PACKAGE__.'->run needs argv' unless @argv;
  return ( undef, 'an argument holds a NUL byte' ) if grep { /\0/ } @argv;
  my $files = $a{files} || {};
  my $dirs  = $a{dirs}  || {};
  my $now   = $a{now};
  my $mtime = defined $now ? $now - 3600 : time - 3600;

  my $tar = Archive::Tar->new;
  my $dir = sub {
    my ( $p, $o ) = @_;
    $tar->add_data( substr( $p, 1 ).'/', '', { type => Archive::Tar::Constant::DIR(), mode => $o->{mode} // 0755,
        uid => $o->{uid} // 0, gid => $o->{gid} // 0, mtime => $mtime } );
  };
  $dir->( $_, $dirs->{$_} || {} ) for sort grep { m{\A/[^\0]+\z} } keys %$dirs;
  my @sent;
  for my $p ( sort keys %$files ) {
    next unless $p =~ m{\A/[^\0]+\z} && $p !~ m{\A/\.hg(?:/|\z)};
    my $e = $files->{$p};
    my %o = ( uid => $e->{uid} // 0, gid => $e->{gid} // 0, mtime => $e->{mtime} // $mtime );
    if ( defined $e->{link} ) {
      $tar->add_data( substr( $p, 1 ), '', { %o, type => Archive::Tar::Constant::SYMLINK(), linkname => $e->{link}, mode => 0777 } );
    }
    else {
      $tar->add_data( substr( $p, 1 ), _bytes( $e->{content} ), { %o, mode => $e->{mode} // 0644 } );
    }
    push @sent, $p;
  }
  my %job = (
    argv => join( "\0", @argv ), cwd => $a{cwd} // '/root', host => $a{host} // 'localhost', tz => $a{tz} // 'Europe/Berlin',
    path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', timeout => $self->timeout,
    scan => join( "\0", @SCAN ), sent => join( "\0", @sent ), max_new => $self->max_new, max_file => $self->max_file,
    env => join( "\0", map { $_.'='.$a{env}{$_} } sort grep { /\A[A-Za-z_]\w*\z/ } keys %{ $a{env} || {} } ),
    now => defined $now ? POSIX::strftime( '%Y-%m-%d %H:%M:%S', gmtime $now ) : '',
  );
  # libfaketime reads FAKETIME in the zone of TZ: hand it the simulation's local time
  if ( defined $now ) {
    local $ENV{TZ} = $job{tz};
    POSIX::tzset();
    $job{now} = POSIX::strftime( '%Y-%m-%d %H:%M:%S', localtime $now );
  }
  POSIX::tzset();
  $tar->add_data( '.hg/', '', { type => Archive::Tar::Constant::DIR(), mode => 0700 } );
  $tar->add_data( '.hg/job',    _job(%job), { mode => 0600 } );
  $tar->add_data( '.hg/stdin',  _bytes( $a{stdin} ), { mode => 0600 } );
  $tar->add_data( '.hg/driver', $DRIVER, { mode => 0600 } );

  my $in  = File::Temp->new( TEMPLATE => 'holmgang-sandbox-in-XXXXXX',  TMPDIR => 1 );
  my $out = File::Temp->new( TEMPLATE => 'holmgang-sandbox-out-XXXXXX', TMPDIR => 1 );
  my $err = File::Temp->new( TEMPLATE => 'holmgang-sandbox-err-XXXXXX', TMPDIR => 1 );
  $tar->write( $in->filename ) or return ( undef, 'the input archive did not write: '.( $tar->error // '' ) );

  ( my $host = $job{host} ) =~ s/[^A-Za-z0-9.-]/-/g;
  $host = 'localhost' unless $host =~ /\A[A-Za-z0-9]/;
  my $name = sprintf 'holmgang-sandbox-%d-%d', $$, ++$SEQ;
  my @cmd = ( @{ $self->docker }, 'run', '--rm', '-i', '--name', $name,
    '--network', 'none', '--hostname', substr( $host, 0, 63 ),
    '--cap-drop', 'ALL', ( map { ( '--cap-add', $_ ) } qw( CHOWN DAC_OVERRIDE FOWNER ) ),
    '--security-opt', 'no-new-privileges', '--pids-limit', $self->pids,
    '--memory', $self->memory, '--cpus', $self->cpus,
    '--entrypoint', 'sh', $self->image, '-c', 'cd / && tar --overwrite -xf - && exec perl /.hg/driver' );

  my $t0  = Time::HiRes::time();
  my $pid = fork;
  return ( undef, 'fork failed: '.$! ) unless defined $pid;
  if ( !$pid ) {
    open STDIN,  '<', $in->filename  or POSIX::_exit(125);
    open STDOUT, '>', $out->filename or POSIX::_exit(125);
    open STDERR, '>', $err->filename or POSIX::_exit(125);
    exec { $cmd[0] } @cmd or POSIX::_exit(127);
  }
  my $status;
  my $done = eval {
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm $self->timeout + 20;
    waitpid $pid, 0;
    $status = $?;
    alarm 0;
    1;
  };
  if ( !$done ) {
    system { $self->docker->[0] } @{ $self->docker }, 'kill', $name;
    kill 'KILL', $pid;
    waitpid $pid, 0;
    return ( undef, 'the container did not end in time' );
  }
  my $ms = int( 1000 * ( Time::HiRes::time() - $t0 ) + 0.5 );
  if ( $status ) {
    my $why = do { local $/; open my $h, '<', $err->filename; scalar <$h> } // '';
    $why =~ s/\s+/ /g;
    return ( undef, 'the container failed ('.( $status >> 8 ).'): '.substr( $why, 0, 300 ) );
  }

  my $back = Archive::Tar->new;
  $back->read( $out->filename ) or return ( undef, 'the result archive did not read: '.( $back->error // '' ) );
  my %got = map { ( '/'.( $_->full_path =~ s{\A/+}{}r ) => $_ ) } $back->get_files;
  my $res = $got{'/.hg/result'} or return ( undef, 'the container gave no result' );
  my %r = _unjob( $res->get_content // '' );
  return ( undef, $r{unavailable} ) if length( $r{unavailable} // '' );

  my $output = $got{'/.hg/out'} ? $got{'/.hg/out'}->get_content // '' : '';
  $output = substr( $output, 0, $self->max_output ) if length $output > $self->max_output;
  my %changed;
  for my $p ( sort grep { !m{\A/\.hg/} } keys %got ) {
    my $f = $got{$p};
    my $old = $files->{$p};
    if ( $f->is_symlink ) {
      next if $old && defined $old->{link} && $old->{link} eq $f->linkname;
      $changed{$p} = { link => $f->linkname };
      next;
    }
    next unless $f->is_file;
    my $content = $f->get_content // '';
    my $mode    = $f->mode & 07777;
    next if $old && !defined $old->{link} && _bytes( $old->{content} ) eq $content && ( $old->{mode} // 0644 ) == $mode;
    $changed{$p} = { content => _chars($content), mode => $mode, ( $old ? () : ( new => 1 ) ) };
  }
  my @deleted = grep { length } split /\0/, $r{deleted} // '';
  push @{ $self->log }, { host => $job{host}, argv => [@argv], exit => 0 + $r{rc}, ms => $ms, clock => $r{clock} };
  return { output => _chars($output), exit => 0 + $r{rc}, changed => \%changed, deleted => \@deleted, ms => $ms, clock => $r{clock} };
}


sub available {
  my ( $self ) = @_;
  my $out = File::Temp->new;
  my $pid = fork;
  return ( 0, 'fork failed: '.$! ) unless defined $pid;
  if ( !$pid ) {
    open STDIN,  '<', '/dev/null';
    open STDOUT, '>', $out->filename;
    open STDERR, '>&', \*STDOUT;
    exec { $self->docker->[0] } @{ $self->docker }, 'image', 'inspect', '--format', '{{.Id}}', $self->image
      or POSIX::_exit(127);
  }
  waitpid $pid, 0;
  my $text = do { local $/; open my $h, '<', $out->filename; scalar <$h> } // '';
  $text =~ s/\s+\z//;
  return ( 1, $text ) unless $?;
  return ( 0, $? >> 8 == 127 ? $self->docker->[0].' is not installed' : 'the image '.$self->image.' is not there: '.substr( $text =~ s/\s+/ /gr, 0, 200 ) );
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sandbox::Docker - Runs one real program on a copy of a device's files in a locked-down container

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Langertha::Holmgang::Sandbox::Docker;

  my $sandbox = Langertha::Holmgang::Sandbox::Docker->new;   # image langertha-holmgang-sandbox:1
  my ( $r, $why ) = $sandbox->run(
    argv  => [ 'python3', '-c', 'print(open("/etc/app.conf").read().upper())' ],
    files => { '/etc/app.conf' => { content => "debug = on\n", mode => 0644 } },
    stdin => undef,
    cwd   => '/root',
    now   => 1792490400,
    host  => 'app1',
  );
  # $r = { output => "DEBUG = ON\n", exit => 0, changed => {}, deleted => [], ms => 412 }
  # $r = undef, $why = 'python3 is not in the image'   -- the caller keeps its gap

=head1 DESCRIPTION

The simulators answer from their state and never touch the host. A real program
they do not model (C<python3 -c>, an C<awk> script past the filter grammar,
C<openssl x509> on a file) is a gap of the simulation: an empty answer and an
C<uncertain> case. This class is the way out for such a program: B<one command>
runs for real, in a container that is made for this call and removed after it.

=over

=item * The container has B<no network>, no capabilities beyond what unpacking
files as root needs, no new privileges, bounded memory, processes and time. No
host directory is mounted: the device's files go in as a tar stream on standard
input and the result comes back as a tar stream on standard output.

=item * The program sees the files the caller hands over, at their real paths,
and nothing else of the simulated device: no services, no other host, no
simulated command. What the simulation knows better stays with the simulator —
the caller decides which commands may come here
(L<Langertha::Holmgang::Sim::Linux/SANDBOX>).

=item * The clock is the simulation's (C<now>) when the image carries
libfaketime; the host name is the device's.

=item * Afterwards the caller gets the output (standard output and error in one
text, as a simulated command answers; Python writes unbuffered, so both come in the order written), the exit status, the files that changed
or appeared and the ones that went away, and writes them back into its state.

=back

A program that is not in the image, a result that is too large, a container
that does not start: L</run> returns nothing and a reason, and the caller keeps
its gap. It never guesses an answer.

The image is built from F<share/sandbox/Dockerfile> of this distribution (after
installation under C<File::ShareDir::dist_dir('Langertha-Holmgang')>):

  docker build -t langertha-holmgang-sandbox:1 share/sandbox

Its programs' output is part of a measurement: name the image digest with a run.

This class is opt-in (C<holmgang run --sandbox docker>). Loading and lint never
use it — a case loads and lints the same with and without Docker
(ADR 0011).

=head2 image

The image to run, default C<langertha-holmgang-sandbox:1>
(F<share/sandbox/Dockerfile>). It needs C<sh>, C<tar> and C<perl>.

=head2 docker

The command of the container runtime as a list, default C<['docker']>
(C<['podman']> works the same).

=head2 timeout

Seconds one program may run, default 10. Past it the program is killed and the
call exits 124, as under C<timeout>.

=head2 memory

=head2 cpus

=head2 pids

The limits of the container (C<--memory>, C<--cpus>, C<--pids-limit>), default
C<512m>, C<1> and C<128>.

=head2 max_output

=head2 max_file

=head2 max_new

Bounds of a result: bytes of output (default 256 KiB, cut beyond), bytes of one
changed or new file (default 1 MiB) and the number of new files (default 200).
A file or count past its bound makes the whole call unusable (L</run> returns
nothing).

=head2 log

Every call that ran, in order: C<{ host, argv, exit, ms }>. The runner takes
the entries of one tool call into its record (L</take_log>).

=head2 take_log

  my @entries = $sandbox->take_log;

The entries of L</log> since the last call, and empties it.

=head2 run

  my ( $result, $why ) = $sandbox->run(
    argv  => \@argv,            # the program and its arguments, no shell
    files => { $path => { content => $text, mode => 0640, uid => 0, gid => 0 } | { link => $target } },
    dirs  => { $path => { mode => 0750, uid => 0, gid => 0 } },
    stdin => $text,
    cwd   => '/root',
    env   => { NAME => $value },
    now   => $epoch,            # the simulation's clock
    tz    => 'Europe/Berlin',
    host  => 'app1',
  );

Runs C<argv> as root in a fresh container in which exactly C<files> and C<dirs>
exist beside the image. Returns the result, or nothing and the reason it is not
usable:

=over

=item * C<output> — standard output and standard error, in the order written.

=item * C<exit> — the exit status; 124 after the timeout, 128 + signal after a
signal.

=item * C<changed> — the files whose content, mode or link target differs from
what went in, and the new ones (C<new>), under the directories a server
program writes to: C<{ content, mode }> or C<{ link }>.

=item * C<deleted> — the paths of C<files> that are gone.

=item * C<ms> — wall time of the call; C<clock> — C<sim> when the program saw
C<now>, C<real> when the image has no libfaketime.

=back

Texts go in and come back as characters (UTF-8 in the container); a result
that is not UTF-8 comes back as bytes.

=head2 available

  my ( $ok, $id_or_reason ) = $sandbox->available;

Whether the runtime answers and the image is there: true and the image id
(to note with a run), or false and the reason.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
