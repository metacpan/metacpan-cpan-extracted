package Devel::XSCover::Test;

use 5.020;
use strict;
use warnings;

use Cwd ();
use File::Path ();
use File::Spec ();

our $VERSION = '0.02';

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        dir     => '.',
        db      => 'cover_db',
        make    => 'make',
        prove   => 'prove',
        test    => [],
        plain   => [],
        delete  => 1,
        no_perl => 0,
        no_deparse => 0,
        threads_covered => 0,
        timeout => 0,
        dry     => 0,
        silent  => 0,
    }, $class;
    $self->{$_} = $args{$_} for keys %args;
    return $self;
}

sub db_path {
    my ($self) = @_;
    return File::Spec->rel2abs($self->{db}, File::Spec->rel2abs($self->{dir}));
}

sub switches {
    my ($self) = @_;
    my $db = $self->db_path;
    $db =~ s/\\/\\\\/g if $^O eq 'MSWin32';
    $db =~ s/ /\\ /g;
    my $cover = "-MDevel::Cover=-db,$db,-ignore," . ($^O eq 'MSWin32' ? '^[A-Za-z]:' : '^/');
    $cover .= ',-silent,1' if $self->{silent};
    return join ' ', grep { defined && length } $ENV{DEVEL_COVER_TEST_OPTS}, $self->deparse_switch, $cover;
}

sub deparse_switch {
    my ($self) = @_;
    return '' if $self->{no_deparse};
    my $pm = $INC{'Devel/XSCover/Test.pm'} or return '-MDevel::XSCover::Deparse';
    (my $lib = $pm) =~ s{[/\\]Devel[/\\]XSCover[/\\]Test\.pm\z}{};
    $lib = File::Spec->rel2abs($lib);
    return -f File::Spec->catfile($lib, 'Devel', 'XSCover', 'Deparse.pm') ? "-I$lib -MDevel::XSCover::Deparse" : '-MDevel::XSCover::Deparse';
}

sub reset_db {
    my ($self) = @_;
    return 0 unless $self->{delete};
    my $db = $self->db_path;
    return 0 unless -d $db;
    $self->_say("xs_cover: removing $db");
    File::Path::remove_tree($db) unless $self->{dry};
    return 1;
}

sub thread_tests {
    my ($self, @files) = @_;
    my $here = Cwd::getcwd();
    chdir $self->{dir} or die "xs_cover: cannot chdir to $self->{dir}: $!\n";
    @files = sort glob 't/*.t' unless @files;
    my @threaded;
    for my $file (@files) {
        open my $fh, '<', $file or next;
        while (my $line = <$fh>) {
            next unless $line =~ /^\s*(?:use|require)\s+threads\b|\bthreads->create\b|\bthreads->new\b|^\s*use\s+Thread\b/;
            push @threaded, $file;
            last;
        }
        close $fh;
    }
    chdir $here;
    return @threaded;
}

sub commands {
    my ($self) = @_;
    my @plain = @{ $self->{plain} };
    my @test  = @{ $self->{test} };
    unless ($self->{no_perl} || $self->{threads_covered}) {
        my %have = map { $_ => 1 } @plain;
        my @threaded = grep { !$have{$_} } $self->thread_tests(@test);
        if (@threaded) {
            $self->_say("xs_cover: @threaded use threads, which Devel::Cover does not work with, so " . (@threaded == 1 ? 'it runs' : 'they run') . ' without it');
            push @plain, @threaded;
        }
    }
    my $covered = $self->{no_perl} ? 0 : 1;
    return ([ [ $self->{make}, 'test' ], $covered ]) unless @plain || @test;
    return ([ [ $self->{prove}, '-b', '-j1', @test ], 0 ]) if $self->{no_perl} && @test;
    my %plain = map { $_ => 1 } @plain;
    unless (@test) {
        my $here = Cwd::getcwd();
        chdir $self->{dir} or die "xs_cover: cannot chdir to $self->{dir}: $!\n";
        @test = sort glob 't/*.t';
        chdir $here;
    }
    my @covered = grep { !$plain{$_} } @test;
    my @commands;
    push @commands, [ [ $self->{prove}, '-b', '-j1', @covered ], 1 ] if @covered;
    push @commands, [ [ $self->{prove}, '-b', '-j1', @plain ], 0 ] if @plain;
    return @commands;
}

sub run {
    my ($self) = @_;
    $self->reset_db;
    my $status = 0;
    for my $command ($self->commands) {
        my ($cmd, $covered) = @$command;
        my $s = $self->_run($cmd, $covered);
        $status = $s if $s && !$status;
    }
    return $status;
}

sub _run {
    my ($self, $cmd, $covered) = @_;
    $self->_say(sprintf 'xs_cover: running %s%s', "@$cmd", $covered ? ' under Devel::Cover' : ' without Devel::Cover');
    return 0 if $self->{dry};
    my $here = Cwd::getcwd();
    chdir $self->{dir} or die "xs_cover: cannot chdir to $self->{dir}: $!\n";
    my $switches = $self->switches;
    my $pid = fork;
    die "xs_cover: cannot fork: $!\n" unless defined $pid;
    if (!$pid) {
        eval { setpgrp 0, 0 };
        if ($covered) {
            $ENV{HARNESS_PERL_SWITCHES} = $switches;
            $ENV{PERL5OPT}              = $switches;
        }
        else {
            delete @ENV{qw(HARNESS_PERL_SWITCHES PERL5OPT)};
        }
        exec @$cmd or exit 127;
    }
    $self->_say("xs_cover: waiting on pid $pid") if $self->{timeout};
    my $status;
    my $timed_out = !eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $self->{timeout} if $self->{timeout};
        waitpid $pid, 0;
        $status = $?;
        alarm 0;
        1;
    };
    if ($timed_out) {
        alarm 0;
        warn "xs_cover: the test run passed $self->{timeout} seconds, ending process group $pid\n";
        kill 'TERM', -$pid;
        sleep 2;
        kill 'KILL', -$pid;
        waitpid $pid, 0;
        $status = 124 << 8;
    }
    chdir $here;
    return 127 if $status == -1;
    return 128 + ($status & 127) if $status & 127;
    return $status >> 8;
}

sub _say {
    my ($self, $line) = @_;
    print "$line\n" unless $self->{silent};
}

1;

__END__

=head1 NAME

Devel::XSCover::Test - the test run under Devel::Cover

=head1 SYNOPSIS

    use Devel::XSCover::Test;
    my $test   = Devel::XSCover::Test->new(dir => '.', db => 'cover_db');
    my $status = $test->run;

=head1 DESCRIPTION

Runs a distribution's tests once, under Devel::Cover for the Perl side and on the
instrumented objects for the C side, so both land in one coverage database from
one run. The environment is the one C<cover -test> sets: C<HARNESS_PERL_SWITCHES>
and C<PERL5OPT> both carry C<-MDevel::Cover=-db,DIR>, after anything in
C<DEVEL_COVER_TEST_OPTS>, plus an ignore of every absolute path: C<PERL5OPT> covers
every perl that runs, C<prove> itself and the scripts a test writes under the
temporary directory included, and none of those is the distribution's code. C<RELEASE_TESTING> and the rest of the environment pass
through untouched.

A process that ends by C<POSIX::_exit> or by a signal writes no C counters, since
the compiler's runtime writes them at a normal exit. The Perl side of such a
process is unaffected, as Devel::Cover writes from its own C<END> block. A test that uses threads dies under Devel::Cover ("Devel::Cover does not yet work with
threads", at compile time, so the file fails). Any test file that uses threads is
found and run without Devel::Cover by itself, and the run says so, unless
C<threads_covered> asks for it to be left alone. The C<plain> list adds other files.
A suite that behaves differently under Devel::Cover altogether, as one whose module
rewrites the op tree does, runs without it with C<no_perl>, and then only the C side
is in the report.

=head1 METHODS

=head2 new

    my $test = Devel::XSCover::Test->new(%options);

Options: C<dir>, C<db>, C<make>, C<prove>, C<test> (an array reference of test
files to run instead of the whole suite), C<plain> (an array reference of test
files to run without Devel::Cover), C<no_perl> (run everything without it), C<no_deparse> (leave custom ops to
B::Deparse's own fallback), C<threads_covered> (do not take thread tests out of the
covered run), C<delete>
(remove the database first, on by default), C<timeout> (seconds, none by default),
C<dry> and C<silent>.

=head2 db_path

The absolute path of the database.

=head2 switches

The perl switches put in the environment of a covered run: L<Devel::XSCover::Deparse>
first, so a custom op without a deparse of its own does not make Devel::Cover warn,
then Devel::Cover. With C<silent>, Devel::Cover's own messages are turned off too.

=head2 deparse_switch

The switch that loads L<Devel::XSCover::Deparse>, with C<-I> for its directory
when this module runs from a source tree, or nothing with C<no_deparse>.

=head2 reset_db

Removes the database when C<delete> is set and it exists. Returns true when it did.

=head2 thread_tests

    my @files = $test->thread_tests(@files);

The test files (those given, or every F<t/*.t>) that load C<threads> or C<Thread>
or call C<threads-E<gt>create>.

=head2 commands

The commands of the run, each a pair of the command words and whether it runs
under Devel::Cover. With neither C<test> nor C<plain> that is C<make test> alone.
Otherwise the files (those given, or every F<t/*.t>) less the plain ones run
with C<prove -b -j1> under Devel::Cover, and the plain ones with the same
command without it. With C<no_perl> nothing runs under Devel::Cover.

=head2 run

Resets the database, runs the commands, and returns the first non-zero exit
status, or zero. A run that passes C<timeout> seconds has its process group ended
and returns 124.

=head1 SEE ALSO

L<Devel::XSCover>, L<Devel::Cover>

=cut
