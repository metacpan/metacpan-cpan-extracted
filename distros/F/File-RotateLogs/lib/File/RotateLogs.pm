package File::RotateLogs;

use strict;
use warnings;
use POSIX qw//;
use Fcntl qw/:DEFAULT/;
use Proc::Daemon;
use File::Basename;
use File::Path;
use File::Spec;
use Mouse;
use Mouse::Util::TypeConstraints;

our $VERSION = '0.08';

subtype 'File::RotateLogs::Path'
    => as 'Str'
    => message { "This argument must be Str or Object that has a stringify method" };
coerce 'File::RotateLogs::Path'
    => from 'Object' => via {
        my $logfile = $_;
        if ( my $stringify = overload::Method( $logfile, '""' ) ) {
            return $stringify->($logfile);
        }
        $logfile;
    };

no Mouse::Util::TypeConstraints;

has 'logfile' => (
    is => 'ro',
    isa => 'File::RotateLogs::Path',
    required => 1,
    coerce => 1,
);

has 'linkname' => (
    is => 'ro',
    isa => 'File::RotateLogs::Path',
    required => 0,
    coerce => 1,
);

has 'rotationtime' => (
    is => 'ro',
    isa => 'Int',
    default => 86400
);

has 'maxage' => (
    is => 'ro',
    isa => 'Int',
    default => sub {
        warn "[INFO] File::RotateLogs: 'maxage' was not configured. RotateLogs doesn't remove any log files\n";
        return 0;
    },
);

has 'sleep_before_remove' => (
    is => 'ro',
    isa => 'Int',
    default => 3,
);

has 'offset' => (
    is => 'ro',
    isa => 'Int',
    default => 0,
);


sub _gen_filename {
    my $self = shift;
    my $now = time;
    my $time = $now - (($now + $self->offset) % $self->rotationtime);
    return POSIX::strftime($self->logfile, localtime($time));
}

sub print {
    my ($self,$log) = @_;
    my $fname = $self->_gen_filename;

    my $fh;
    if ( $self->{fh} ) {
        if ( $fname eq $self->{fname} && $self->{pid} == $$ ) {
            $fh = delete $self->{fh};
        }
        else {
            $fh = delete $self->{fh};
            close $fh if $fh;
            undef $fh;
        }
    }

    unless ($fh) {
        my $is_new = ( ! -f $fname || ( $self->linkname && ! -l $self->linkname ) ) ? 1 : 0;
        File::Path::mkpath( File::Basename::dirname($fname) ) if ! -e File::Basename::dirname($fname);
        open $fh, '>>:utf8:unix', $fname or die "Cannot open file($fname): $!";
        if ( $is_new ) {
            eval {
                $self->rotation($fname);
            };
            warn "failed rotation or symlink: $@" if $@;
        }
    }

    $fh->print($log)
        or die "Cannot write to $fname: $!";

    $self->{fh} = $fh;
    $self->{fname} = $fname;
    $self->{pid} = $$;
}

sub rotation {
    my ($self, $fname) = @_;

    my $lock = $fname .'_lock';
    sysopen(my $lockfh, $lock, O_CREAT|O_EXCL) or return;
    close($lockfh);
    if ( $self->linkname ) {
        my $symlink = $fname .'_symlink';
        symlink($fname, $symlink) or die $!;
        rename($symlink, $self->linkname) or die $!;
    }

    if ( ! $self->maxage ) {
        unlink $lock;
        return;
    }

    my $time = time;
    my @to_unlink = grep { $time - [stat($_)]->[9] > $self->maxage } 
        glob($self->logfile_pattern);
    if ( ! @to_unlink ) {
        unlink $lock;
        return;
    }

    if ( $self->sleep_before_remove ) {
        $self->unlink_background(@to_unlink,$lock);
    }
    else {
        unlink $_ for @to_unlink;
        unlink $lock;
    }
}

sub logfile_pattern {
    my $self = shift;
    my $logfile = $self->logfile;
    $logfile =~ s!%[%+A-Za-z]!*!g;
    $logfile =~ s!\*+!*!g;
    $logfile;
}

sub unlink_background {
    my ($self, @files) = @_;    
    my $daemon = Proc::Daemon->new();
    @files = map { File::Spec->rel2abs($_) } @files;
    if ( ! $daemon->Init ) {
        $0 = "$0 rotatelogs unlink worker";
        sleep $self->sleep_before_remove;
        unlink $_ for @files;
        POSIX::_exit(0);
    }
}

__PACKAGE__->meta->make_immutable();

1;
__END__

=head1 NAME

File::RotateLogs - File logger supports log rotation

=head1 SYNOPSIS

  use File::RotateLogs;
  use Plack::Builder;
  
  my $rotatelogs = File::RotateLogs->new(
      logfile => '/path/to/access_log.%Y%m%d%H%M',
      linkname => '/path/to/access_log',
      rotationtime => 3600,
      maxage => 86400, #1day
  );
  
  builder {
      enable 'AccessLog',
        logger => sub { $rotatelogs->print(@_) };
      $app;
  };

=head1 DESCRIPTION

File::RotateLogs is utility for file logger.
Supports logfile rotation and makes symlink to newest logfile.

=head1 CONFIGURATION

=over 4

=item logfile

This is file name pattern. It is the pattern for filename. The format is POSIX::strftime(), see also L<POSIX>.

=item linkname

Filename to symlink to newest logfile. default: none

=item rotationtime

default: 86400 (1day)

=item maxage

Maximum age of files (based on mtime), in seconds. After the age is surpassed, 
files older than this age will be deleted. Optional. Default is undefined, which means unlimited.
old files are removed at a background unlink worker.

=item sleep_before_remove

Sleep seconds before remove old log files. default: 3
If sleep_before_remove == 0, files are removed within plack processes. Does not fork background 
unlink worker.

=item offset

The number of seconds offset form UTC. default: 0
If offset is omitted or set zero, UTC is used.
When rotationtime is 24h and offset is 0, log is going to be rotated at 0 O'clock (UTC).
For example, to use local timezone in the zone UTC +9 (Asia/Tokyo), set 32400 (9*60*60).

=back

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

L<File::Stamped>, L<Log::Dispatch::Dir>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
