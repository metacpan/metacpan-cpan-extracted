package Devel::XSCover;

use 5.020;
use strict;
use warnings;

use Config ();
use Cwd ();
use File::Path ();
use File::Spec ();
use Getopt::Long ();
use Pod::Usage   ();
use Devel::XSCover::Build ();
use Devel::XSCover::Test ();
use Devel::XSCover::XS ();
use Devel::XSCover::Gcov ();
use Devel::XSCover::DB ();

our $VERSION = '0.09';

our (%DEFAULTS);

BEGIN {
    %DEFAULTS = (
        dir     => '.',
        db      => 'cover_db',
            report  => 'XSCover',
        make    => 'make',
        test    => [],
        plain   => [],
        timeout => 0,
        ignore  => [],
    );
}

sub new {
    my ($class, %args) = @_;
    my $self = bless { %DEFAULTS }, $class;
    $self->{$_} = $args{$_} for keys %args;
    $self->{test}   = [ $self->{test} ]   unless ref $self->{test};
    $self->{plain}  = [ $self->{plain} ]  unless ref $self->{plain};
    $self->{ignore} = [ $self->{ignore} ] unless ref $self->{ignore};
    return $self;
}

sub defaults_from_file {
    my ($class, @argv) = @_;
    my $dir = '.';
    for my $i (0 .. $#argv - 1) {
        $dir = $argv[$i + 1] if $argv[$i] eq '-dir' || $argv[$i] eq '--dir';
    }
    my $file = File::Spec->catfile($dir, '.xs_cover');
    open my $fh, '<', $file or return;
    my @words;
    while (my $line = <$fh>) {
        $line =~ s/#.*//;
        for my $word (split ' ', $line) {
            $word =~ s/^(['"])(.*)\1$/$2/;
            push @words, $word;
        }
    }
    close $fh;
    return @words;
}

sub new_from_argv {
    my ($class, @argv) = @_;
    unshift @argv, $class->defaults_from_file(@argv);
    my %opt = (test => [], plain => [], ignore => []);
    my $parser = Getopt::Long::Parser->new(config => [qw(no_ignore_case)]);
    $parser->getoptionsfromarray(\@argv, \%opt, qw(
        dir=s db=s report=s gcov=s make=s cover=s
        test=s@ plain=s@ ignore=s@ timeout=i keep no_delete no_perl threads_covered dry silent
        help|h version|v
    )) or Pod::Usage::pod2usage(-exitval => 2, -verbose => 0, -input => $0);
    Pod::Usage::pod2usage(-exitval => 0, -verbose => 1, -input => $0) if $opt{help};
    if ($opt{version}) {
        print "xs_cover version $VERSION\n";
        exit 0;
    }
    Pod::Usage::pod2usage(-exitval => 2, -verbose => 0, -input => $0,
        -message => "xs_cover: unexpected argument @argv") if @argv;
    delete @opt{qw(help version)};
    return $class->new(%opt);
}

sub dir     { $_[0]{dir} }
sub db      { $_[0]{db} }
sub cover   { $_[0]{cover} }
sub make    { $_[0]{make} }
sub tests   { @{ $_[0]{test} } }
sub plains  { @{ $_[0]{plain} } }
sub timeout { $_[0]{timeout} || 0 }
sub ignores { @{ $_[0]{ignore} } }

sub ignored {
    my ($self, $path) = @_;
    return scalar grep { $path =~ /$_/ } $self->ignores;
}
sub keep    { $_[0]{keep} ? 1 : 0 }
sub dry     { $_[0]{dry} ? 1 : 0 }
sub silent  { $_[0]{silent} ? 1 : 0 }
sub gcov    { $_[0]{gcov} }

sub delete_db { $_[0]{no_delete} ? 0 : 1 }
sub no_perl   { $_[0]{no_perl} ? 1 : 0 }
sub threads_covered { $_[0]{threads_covered} ? 1 : 0 }

sub cover_command {
    my ($self) = @_;
    return [ split ' ', $self->{cover} ] if defined $self->{cover} && length $self->{cover};
    my @inc = $self->report_inc;
    my ($vol, $bin) = File::Spec->splitpath($^X);
    for my $dir (File::Spec->catpath($vol, $bin, ''), grep { defined && length } @Config::Config{qw(installsitescript installsitebin installscript)}) {
        my $path = File::Spec->catfile($dir, 'cover');
        return [ $^X, @inc, $path ] if -f $path;
    }
    return ['cover'];
}

sub report_inc {
    my $pm = $INC{'Devel/XSCover.pm'} or return;
    (my $lib = $pm) =~ s{[/\\]Devel[/\\]XSCover\.pm\z}{};
    return -f File::Spec->catfile($lib, 'Devel', 'Cover', 'Report', 'XSCover.pm') ? ("-I$lib") : ();
}

sub skip_dirs {
    my ($self) = @_;
    my $db = (File::Spec->splitdir($self->{db}))[-1];
    return [ 'blib', '.git', $db ];
}

sub run {
    my ($self) = @_;
    my %common = map { $_ => $self->{$_} } qw(dir make dry silent);
    my $build = Devel::XSCover::Build->new(%common, gcov => $self->gcov, skip => $self->skip_dirs);
    my $status = $build->run;
    if ($status) {
        warn "xs_cover: the build failed with status $status\n";
        return $status;
    }
    my $test = Devel::XSCover::Test->new(%common, db => $self->{db}, test => $self->{test}, plain => $self->{plain},
        delete => $self->delete_db, timeout => $self->timeout, no_perl => $self->no_perl, threads_covered => $self->threads_covered);
    my $finder = Devel::XSCover::Gcov->new(%common, skip => $self->skip_dirs);
    my $stale  = $self->remove_counters($finder);
    $self->_say("xs_cover: removed $stale stale counter file" . ($stale == 1 ? '' : 's') . ' left by an earlier run') if $stale;
    $status = $test->run;
    warn "xs_cover: the tests failed with status $status, reporting what ran\n" if $status;
    my @maps   = grep { !$self->ignored($_->{c}) } Devel::XSCover::XS->new(dir => $self->{dir}, skip => $self->skip_dirs)->read;
    my $reader = Devel::XSCover::Gcov->new(%common, gcov => $build->gcov_command, conditions => $build->conditions, flow => $build->flow_kind, ignore => $self->{ignore},
        generated => [ map { $_->{c} } @maps ], xsubs => { map { my $m = $_; map { $_ => $m->{xsubs}{$_}{file} } keys %{ $m->{xsubs} } } @maps },
        inverse => { map { %{ $_->{inverse} || {} } } @maps },
        skip => $self->skip_dirs, save => $self->gcov_dir($test->db_path));
    my @objects = $reader->read;
    my $writer  = Devel::XSCover::DB->new(%common, db => $test->db_path);
    my $entries = $writer->entries($writer->merge(@objects), @maps);
    if (%$entries) {
        $writer->write($entries);
    }
    else {
        $self->_say('xs_cover: no C counters found, nothing to write');
    }
    $self->report($test->db_path);
    $self->cleanup($build, $reader, $test->db_path) unless $self->keep;
    return $status;
}

sub report {
    my ($self, $db) = @_;
    my @cmd = (@{ $self->cover_command }, '-nogcov', '-report', $self->report_name, $self->silent ? ('-silent') : (), $db);
    $self->_say("xs_cover: running @cmd");
    return 0 if $self->dry;
    my $here = Cwd::getcwd();
    chdir $self->{dir} or die "xs_cover: cannot chdir to $self->{dir}: $!\n";
    my $status = system @cmd;
    chdir $here;
    $status = $status == -1 ? 127 : $status >> 8;
    warn "xs_cover: cover exited with status $status\n" if $status;
    return $status;
}

sub gcov_dir {
    my ($self, $db) = @_;
    return "$db.gcov";
}

sub remove_counters {
    my ($self, $reader, $graphs) = @_;
    my @gone;
    for my $gcda ($reader->find_gcda) {
        (my $gcno = $gcda) =~ s/\.gcda\z/.gcno/;
        for my $rel ($gcda, ($graphs ? $gcno : ())) {
            my $path = File::Spec->catfile($self->{dir}, $rel);
            next unless -f $path;
            push @gone, $rel;
            unlink $path unless $self->dry;
        }
    }
    return scalar @gone;
}

sub cleanup {
    my ($self, $build, $reader, $db) = @_;
    my @gone = (1) x $self->remove_counters($reader, 1);
    my $saved = $self->gcov_dir($db);
    File::Path::remove_tree($saved) if -d $saved && !$self->dry;
    my @touched = do { local $build->{silent} = 1; $build->touch };
    $self->_say(sprintf 'xs_cover: removed %d counter file%s and touched %d source%s, so the next make rebuilds without coverage',
        scalar @gone, @gone == 1 ? '' : 's', scalar @touched, @touched == 1 ? '' : 's');
    return scalar @gone;
}

sub report_name { $_[0]{report} }

sub _say {
    my ($self, $line) = @_;
    print "$line\n" unless $self->{silent};
}

1;

__END__

=head1 NAME

Devel::XSCover - XS and C coverage for Devel::Cover, with one command

=head1 SYNOPSIS

    xs_cover

    use Devel::XSCover;
    my $cover  = Devel::XSCover->new(dir => '.', report => 'html');
    my $status = $cover->run;

=head1 DESCRIPTION

Devel::XSCover extends Devel::Cover with coverage of the XS and C in a distribution.
The C<xs_cover> command, run in a distribution directory, rebuilds the XS with the
compiler's coverage instrumentation, runs the tests under Devel::Cover, reads the
counters the compiler wrote, merges them into the same coverage database as the
Perl side, and runs C<cover> for the report. One run, one database, one report.

=head2 What Devel::Cover's own gcov support gives, and what this adds

C<cover -test> rebuilds the XS with gcov's flags and runs C<gcov2perl> on what gcov
writes. That reads statement counts and two-arm branches and nothing more: every
C<switch> and every line with two conditions is dropped with a warning, no C
function or XSUB has subroutine coverage, a header's inline functions seen from
several objects write conflicting data, perl's own headers appear in the report,
and the generated C file, the only record that an XSUB was entered, is thrown away.

On a small XS distribution with a C<switch>, an inline function in a header and an
XSUB with an alias, C<cover -test> reports

    File                           stmt   bran   cond    sub    pod   time  total
    ...ulti-2level/CORE/inline.h  100.0    n/a    n/a    n/a    n/a    n/a  100.0
    ...i-2level/CORE/sv_inline.h   80.0   50.0    n/a    n/a    n/a    n/a   71.4
    Spike.xs                       88.4   75.0    n/a    n/a    n/a    n/a   85.2
    blib/lib/Spike.pm             100.0    n/a    n/a  100.0    n/a  100.0  100.0
    src/helper.c                   85.7    n/a    n/a    n/a    n/a    n/a   85.7
    xs/more.xs                     50.0    n/a    n/a    n/a    n/a    n/a   50.0

and C<xs_cover> reports

    File              stmt   bran   cond    sub    pod   time  total
    Spike.xs          88.4   83.3    n/a  100.0    n/a    n/a   88.6
    blib/lib/Spike.pm  100.0    n/a    n/a  100.0    n/a  100.0  100.0
    include/spike.h  100.0  100.0    n/a  100.0    n/a    n/a  100.0
    src/helper.c      85.7   87.5    n/a  100.0    n/a    n/a   87.5
    xs/more.xs        50.0    n/a    n/a   50.0    n/a    n/a   50.0

The header is in, perl's are out, every function and XSUB has a subroutine entry
under its Perl name (an alias gives it two), and every arm of the C<switch> is a
branch. With gcc 14 or later the C files have a condition column too, from the
compiler's own condition coverage: for every term of a decision, whether its true
and its false outcome each decided the result. gcc counts the terms after the
preprocessor, so a decision with more terms than its source holds has a macro's own
among them and is left out, as a line with no decision in its text is. Other
compilers give gcov nothing of the kind, and the column stays empty for C.

A branch of a C file is a decision of its source, an C<if>, C<while>, C<for> or
C<switch>, with one arm per way out of it, read from the flow graph the compiler
wrote beside the counters (C<llvm-cov gcov --dump>, or C<gcov --json-format> from
gcc 9). gcov's text alone lists every block on the line, and on a line such as
C<if (!stash || !HvNAME_get(stash))> most of them are the macro's own: its inner
tests jump within the line and nothing in the source can take their other arm. The
arcs that leave the decision's lines are its outcomes, and those that stay on them
are not, so the macro's tests vanish and the C<if> has two arms, the one into its
body first. A conditional expression inside a statement, C<x ? y : z> or C<return
a && b>, is not a branch, since its outcomes merge on its own line: under gcc 14 its
terms are in the condition column. An older gcov, which has no flow graph, gives
every block with two or more arms as a branch, leaving out the blocks on lines
with no decision in their text.

=head2 The report

The default report is L<Devel::Cover::Report::XSCover>: a summary page with tiles,
a sortable table and a filter, and a page per file with the coverage drawn beside
each line, in words where something is missing. Any other report of Devel::Cover
can be asked for with C<-report>.

=head2 Marking code uncoverable

Devel::Cover's own forms work on C lines: a comment such as
C</* # uncoverable branch true */> at the end of the line, or the F<.uncoverable>
file. Which of a C branch's two arms is "true" is the compiler's choice, so a mark
on a C branch may land on the other arm. The report shows the marked arm in its
own colour.

=head2 Limitations

A process that ends by C<POSIX::_exit> or by a signal writes no C counters, since
the compiler's runtime writes them at a normal exit. A test that uses threads dies
under Devel::Cover, so every test file that uses threads is found and run without
it by itself, keeping its C side, and C<-plain> does the same for any other file. A test that
compares a C<die> message against C<at FILE line N> sees a different message under
Devel::Cover, where a string eval's location gains its file and line. A module that
reads or rewrites the op tree sees Devel::Cover's instrumentation in it and may
behave differently under it, and C<-no_perl> runs its whole suite without, for the
C side alone. Windows is
not supported in this release.

=head1 METHODS

=head2 new

    my $cover = Devel::XSCover->new(%options);

Takes the options of L<xs_cover> as a hash: C<dir>, C<db>, C<report>,
C<gcov>, C<make>, C<test> (an array reference of test files), C<plain> (an array reference of test
files run without Devel::Cover), C<ignore> (an array reference of patterns),
C<timeout>, C<cover> (the cover command), C<keep>, C<no_delete>, C<no_perl> (run the
tests without Devel::Cover, for the C side alone), C<threads_covered>, C<dry> and
C<silent>.

=head2 new_from_argv

    my $cover = Devel::XSCover->new_from_argv(@ARGV);

Parses a command line in the form L<xs_cover> takes and returns the object. Prints
the usage and exits for C<-h>, prints the version and exits for C<-v>.
A F<.xs_cover> file in the distribution directory (the one C<-dir> names, or the
current one) holds defaults: its words, split on whitespace with a C<#> starting a
comment and quotes around a word dropped, go before the command line, so a pattern
in the file and one on the command line both apply and a single-valued option on
the command line wins.

=head2 defaults_from_file

    my @words = Devel::XSCover->defaults_from_file(@ARGV);

The words of the distribution's F<.xs_cover>, or nothing when there is no such file.

=head2 run

    my $status = $cover->run;

Runs the five steps in order: the instrumented build, the tests under
Devel::Cover, the XS map and the gcov reader, the write into the database, and
C<cover> for the report. Returns the exit status of the test run, or of the build
when that fails. Any counter file left by an earlier run is removed before the tests. Unless
C<keep> is set, the counter files are removed and the sources touched again
afterwards, so the next plain C<make> rebuilds optimised.

=head2 dir

The distribution directory.

=head2 db

The coverage database directory, C<cover_db> by default.

=head2 report_name

The report passed to C<cover>, C<XSCover> by default.

=head2 report

    $cover->report($db);

Runs C<cover> on the database with that report, with C<-nogcov>: left to itself
C<cover> runs its own gcov pass on any counter file in the tree and writes a second,
thinner set of runs over ours. The C<cover> beside the running perl is used, so the
report is made by the same Devel::Cover that wrote the runs.

=head2 cover_command

That C<cover> as a list of words, or the C<cover> option split on spaces. When
C<cover> runs under the same perl it also gets C<-I> for the directory this module
was loaded from, so a report module of this distribution is found from a source
tree as well as from an installation.

=head2 report_inc

That C<-I>, or nothing when the report module is not beside this one.

=head2 cover

The C<cover> option.

=head2 cleanup

    $cover->cleanup($build, $reader, $db);

Removes the counter files and the saved gcov text and touches the sources, and
says how many of each.

=head2 remove_counters

    my $n = $cover->remove_counters($reader, $graphs);

Removes every counter file under the directory, and the graph files too when
C<$graphs> is set, and returns how many went. Run after the build and before the
tests as well, since a counter file left by a process of an earlier run that ended
late belongs to another build, and the compiler's runtime refuses to merge into it
and leaves it corrupt.

=head2 gcov_dir

    my $dir = $cover->gcov_dir($db);

Where the gcov text of each object is kept during a run, and after it with
C<keep>: the database's name with C<.gcov> appended, beside it rather than inside,
since C<cover> complains of anything it does not know inside the database.

=head2 skip_dirs

The directories the steps leave alone: C<blib>, C<.git> and the database.

=head2 gcov

The gcov tool, when the detection is to be overridden.

=head2 make

The make command.

=head2 tests

The test files to run instead of C<make test>, as a list.

=head2 plains

The test files to run without Devel::Cover, as a list.

=head2 timeout

The seconds a test run may take, zero for no limit.

=head2 ignores

The patterns added to the default ignore list, as a list.

=head2 ignored

    if ($xs_cover->ignored('t/consumer/Consumer.c')) { ... }

True when a path matches one of those patterns. The XS maps of a generated C
file that does are left out, so a test's own XS module is neither a source
of the report nor a subroutine in it.

=head2 keep

True when the counters and instrumented objects are kept after the run.

=head2 delete_db

True when the coverage database is removed before the run, which is the default.

=head2 no_perl

True when the tests run without Devel::Cover, so the report has the C side alone.

=head2 threads_covered

True when test files that use threads are left in the covered run rather than run
without Devel::Cover by themselves.

=head2 dry

True when every command is printed and nothing is run.

=head2 silent

True when only the summary is printed.

=head1 SEE ALSO

L<Devel::Cover>, L<xs_cover>, L<gcov2perl>

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
