package Devel::Git::MultiBisect;
use strict;
use warnings;
use v5.10.0;
use Devel::Git::MultiBisect::Init;
use Devel::Git::MultiBisect::Auxiliary qw(
    clean_outputfile
    hexdigest_one_file
    validate_list_sequence
);
use Carp;
use Cwd;
use File::Spec;
use File::Temp;
use List::Util qw(sum);

our $VERSION = '0.12';

=head1 NAME

Devel::Git::MultiBisect - Study build and test output over a range of F<git> commits

=head1 SYNOPSIS

You will typically construct an object of a class which is a child of
F<Devel::Git::MultiBisect>, such as F<Devel::Git::MultiBisect::AllCommits> or
F<Devel::Git::MultiBisect::Transitions>.  All methods documented in this
parent package may be called from either child class.

    use Devel::Git::MultiBisect::AllCommits;
    $self = Devel::Git::MultiBisect::AllCommits->new(\%parameters);

... or

    use Devel::Git::MultiBisect::Transitions;
    $self = Devel::Git::MultiBisect::Transitions->new(\%parameters);

... and then:

    $commit_range = $self->get_commits_range();

    $full_targets = $self->set_targets(\@target_args);

    $outputs = $self->run_test_files_on_one_commit($commit_range->[0]);

... followed by methods specific to the child class.

... and then perhaps also:

    $timings = $self->get_timings();

=head1 DESCRIPTION

Given a Perl library or application kept in F<git> for version control, it is
often useful to be able to compare the output collected from running one or
more test files over a range of F<git> commits.  If that range is sufficiently
large, a test may fail in B<more than one way> over that range.

If that is the case, then simply asking, I<"When did this file start to
fail?"> -- a question which C<git bisect> is designed to answer -- is
insufficient.  In order to identify more than one point of failure, we may
need to (a) capture the test output for each commit; or, (b) capture the test
output only at those commits where the output changed.  The output of a run of
a test file may change for a variety of reasons:  test failures, segfaults,
changes in the number or content of tests, etc.

F<Devel::Git::MultiBisect> provides methods to achieve that objective.  Its
child classes, F<Devel::Git::MultiBisect::AllCommits> and
F<Devel::Git::MultiBisect::Transitions>, provide different flavors of that
functionality for objectives (a) and (b), respectively.  Please refer to their
documentation for further discussion.

=head2 GLOSSARY

=over 4

=item * B<commit>

A source code change set entered ("committed") to a F<git> repository.  Each
commit is denoted by a SHA.  In this library, whenever a commit is called for
as the argument to a function, you can also use a F<git tag>.

=item * B<commit range>

The range of sequential commits (determined by F<git log>) requested for analysis.

=item * B<target>

A test file from the test suite of the application or library under study.

=item * B<test output>

What is sent to STDOUT or STDERR as a result of calling a test program such as
F<prove> or F<t/harness> on an individual target file.  Currently we assume
that all such test programs are written based on the
L<Test Anything Protocol (TAP)|https://en.wikipedia.org/wiki/Test_Anything_Protocol>.

=item * B<transitional commit>

A commit at which the test output for a given target changes from that of the
commit immediately preceding.

=item * B<digest>

A string holding the output of a cryptographic process run on test output
which uniquely identifies that output.  (Currently, we use the
C<Digest::SHA::md5_hex> algorithm.)  We assume that if the test output does
not change between one or more commits, then that commit is not a transitional
commit.

Note:  Before taking a digest on a particular test output, we exclude text
such as timings which are highly likely to change from one run to the next and
which would introduce spurious variability into the digest calculations.

=item * B<multisection> or B<multibisection>

A series of configure-build-test process sequences at those commits within the
commit range which are selected by a bisection algorithm.

Normally, when we bisect (via F<git bisect>, F<Porting/bisect.pl> or
otherwise), we are seeking a single point where a Boolean result -- yes/no,
true/false, pass/fail -- is returned.  What the test run outputs to STDOUT or
STDERR is a lesser concern.

In multisection we bisect repeatedly to determine all points where the output
of the test command changes -- regardless of whether that change is a C<PASS>,
C<FAIL> or whatever.  We capture the output for later human examination.

=back

=head1 METHODS

=head2 C<new()>

=over 4

=item * Purpose

Constructor.

=item * Arguments

    $self = Devel::Git::MultiBisect::AllCommits->new(\%params);

or

    $self = Devel::Git::MultiBisect::Transitions->new(\%params);

Reference to a hash, typically the return value of
C<Devel::Git::MultiBisect::Opts::process_options()>.

The hashref passed as argument must contain key-value pairs for C<gitdir>,
C<workdir> and C<outputdir>.  C<new()> tests for the existence of each of
these directories.

=item * Return Value

Object of Devel::Git::MultiBisect child class.

=back

=cut

sub new {
    my ($class, $params) = @_;

    my $data = Devel::Git::MultiBisect::Init::init($params);

    return bless $data, $class;
}

=head2 C<get_commits_range()>

=over 4

=item * Purpose

Identify the SHAs of each F<git> commit identified by C<new()>.

=item * Arguments

    $commit_range = $self->get_commits_range();

None; all data needed is already in the object.

=item * Return Value

Array reference, each element of which is a SHA.

=back

=cut

sub get_commits_range {
    my $self = shift;
    return [  map { $_->{sha} } @{$self->{commits}} ];
}

=head2 C<set_targets()>

=over 4

=item * Purpose

Identify the test files which will be run at different points in the commits
range.  We shall assume that the test file has existed with its name unchanged
over the entire commit range.

=item * Arguments

    $target_args = [
        't/44_func_hashes_mult_unsorted.t',
        't/45_func_hashes_alt_dual_sorted.t',
    ];
    $full_targets = $self->set_targets($target_args);

Reference to an array holding the relative paths beneath the C<gitdir> to the
test files selected for examination.

=item * Return Value

Reference to an array holding hash references with these elements:

=over 4

=item * C<path>

Absolute paths to the test files selected for examination.  Test file is
tested for its existence.

=item * C<stub>

String composed by taking an element in the array ref passed as argument and
substituting underscores C(<_>) for forward slash (C</>) and dot (C<.>)
characters.  So,

    t/44_func_hashes_mult_unsorted.t

... becomes:

    t_44_func_hashes_mult_unsorted_t

=back

=back

=cut

sub set_targets {
    my ($self, $explicit_targets) = @_;

    my @raw_targets = @{$self->{targets}};

    # If set_targets() is provided with an appropriate argument
    # ($explicit_targets), override whatever may have been stored in the
    # object by new().

    if (defined $explicit_targets) {
        croak "Explicit targets passed to set_targets() must be in array ref"
            unless ref($explicit_targets) eq 'ARRAY';
        @raw_targets = @{$explicit_targets};
    }

    my @full_targets = ();
    my @missing_files = ();
    for my $rt (@raw_targets) {
        my $ft = File::Spec->catfile($self->{gitdir}, $rt);
        if (! -e $ft) { push @missing_files, $ft; next }
        my $stub;
        ($stub = $rt) =~ s{[./]}{_}g;
        push @full_targets, {
            path    => $ft,
            stub    => $stub,
        };
    }
    if (@missing_files) {
        croak "Cannot find file(s) to be tested: @missing_files";
    }
    $self->{targets} = [ @full_targets ];
    return \@full_targets;
}

=head2 C<run_test_files_on_one_commit()>

=over 4

=item * Purpose

Capture the output from running the selected test files at one specific F<git> checkout.

=item * Arguments

    $outputs = $self->run_test_files_on_one_commit("2a2e54a");

or

    $excluded_targets = [
        't/45_func_hashes_alt_dual_sorted.t',
    ];
    $outputs = $self->run_test_files_on_one_commit("2a2e54a", $excluded_targets);

=over 4

=item 1

String holding the SHA from a single commit in the repository.  This string
would typically be one of the elements in the array reference returned by
C<$self->get_commits_range()>.  If no argument is provided, the method will
default to using the first element in the array reference returned by
C<$self->get_commits_range()>.

=item 2

Reference to array of target test files to be excluded from a particular
invocation of this method.  Optional, but will die if argument is not an array
reference.

=back

=item * Return Value

Reference to an array, each element of which is a hash reference with the
following elements:

=over 4

=item * C<commit>

String holding the SHA from the commit passed as argument to this method (or
the default described above).

=item * C<commit_short>

String holding the value of C<commit> (above) to the number of characters
specified in the C<short> element passed to the constructor; defaults to 7.

=item * C<file_stub>

String holding a rewritten version of the relative path beneath C<gitdir> of
the test file being run.  In this relative path forward slash (C</>) and dot
(C<.>) characters are changed to underscores C(<_>).  So,

    t/44_func_hashes_mult_unsorted.t

... becomes:

    t_44_func_hashes_mult_unsorted_t'

=item * C<file>

String holding the full path to the file holding the TAP output collected
while running one test file at the given commit.  The following example shows
how that path is calculated.  Given:

    output directory (outputdir)    => '/tmp/DQBuT_SRAY/'
    SHA (commit)                    => '2a2e54af709f17cc6186b42840549c46478b6467'
    shortened SHA (commit_short)    => '2a2e54a'
    test file (target->[$i])        => 't/44_func_hashes_mult_unsorted.t'

... the file is placed in the directory specified by C<outputdir>.  We then
join C<commit_short> (the shortened SHA), C<file_stub> (the rewritten relative
path) and the strings C<output> and C<txt> with a dot to yield this value for
the C<file> element:

    2a2e54a.t_44_func_hashes_mult_unsorted_t.output.txt

=item * C<md5_hex>

String holding the return value of
C<Devel::Git::MultiBisect::Auxiliary::hexdigest_one_file()> run with the file
designated by the C<file> element as an argument.  (More precisely, the file
as modified by C<Devel::Git::MultiBisect::Auxiliary::clean_outputfile()>.)

=back

Example:

    [
      {
        commit => "2a2e54af709f17cc6186b42840549c46478b6467",
        commit_short => "2a2e54a",
        file => "/tmp/1mVnyd59ee/2a2e54a.t_44_func_hashes_mult_unsorted_t.output.txt",
        file_stub => "t_44_func_hashes_mult_unsorted_t",
        md5_hex => "31b7c93474e15a16d702da31989ab565",
      },
      {
        commit => "2a2e54af709f17cc6186b42840549c46478b6467",
        commit_short => "2a2e54a",
        file => "/tmp/1mVnyd59ee/2a2e54a.t_45_func_hashes_alt_dual_sorted_t.output.txt",
        file_stub => "t_45_func_hashes_alt_dual_sorted_t",
        md5_hex => "6ee767b9d2838e4bbe83be0749b841c1",
      },
    ]

=item * Comment

In this method's current implementation, we start with a C<git checkout> from
the repository at the specified C<commit>.  We configure (I<e.g.,> C<perl
Makefile.PL>) and build (I<e.g.,> C<make>) the source code.  We then test each
of the test files we have targeted (I<e.g.,> C<prove -vb
relative/path/to/test_file.t>).  We redirect both STDOUT and STDERR to
C<outputfile>, clean up the outputfile to remove the line containing timings
(as that introduces unwanted variability in the C<md5_hex> values) and compute
the digest.

This implementation is very much subject to change.

If a true value for C<verbose> has been passed to the constructor, the method
prints C<Created [outputfile]> to STDOUT before returning.

B<Note:>  While this method is publicly documented, in actual use you probably
will not need to call it directly.  Instead, you will probably use either
C<Devel::Git::MultiBisect::AllCommits::run_test_files_on_all_commits()> or
C<Devel::Git::MultiBisect::Transitions::multisect_all_targets()>.

=back

=cut

sub run_test_files_on_one_commit {
    my ($self, $commit, $excluded_targets) = @_;
    $commit //= $self->{commits}->[0]->{sha};
    say "Testing commit: $commit" if ($self->{verbose});

    if (defined $excluded_targets) {
        if (ref($excluded_targets) ne 'ARRAY') {
            croak "excluded_targets, if defined, must be in array reference";
        }
    }
    else {
        $excluded_targets = [];
    }
    my %excluded_targets;
    for my $t (@{$excluded_targets}) {
        my $ft = File::Spec->catfile($self->{gitdir}, $t);
        $excluded_targets{$ft}++;
    }

    my $current_targets = [
        grep { ! exists $excluded_targets{$_->{path}} }
        @{$self->{targets}}
    ];

    my $starting_branch = $self->_configure_build_one_commit($commit);

    my $outputsref = $self->_test_one_commit($commit, $current_targets);
    say "Tested commit:  $commit; returning to: $starting_branch"
        if ($self->{verbose});

    # We want to return to our basic branch (e.g., 'master', 'blead')
    # before checking out a new commit.

    system(qq|git checkout --quiet $starting_branch|)
        and croak "Unable to 'git checkout --quiet $starting_branch";

    $self->{commit_counter}++;
    say "Commit counter: $self->{commit_counter}" if $self->{verbose};

    return $outputsref;
}

sub _configure_one_commit {
    my ($self, $commit) = @_;
    chdir $self->{gitdir} or croak "Unable to change to $self->{gitdir}";
    system(qq|git clean --quiet -dfx|) and croak "Unable to 'git clean --quiet -dfx'";
    my $starting_branch = $self->{branch};

    system(qq|git checkout --quiet $commit|) and croak "Unable to 'git checkout --quiet $commit'";
    say "Running '$self->{configure_command}'" if $self->{verbose};
    system($self->{configure_command}) and croak "Unable to run '$self->{configure_command})'";
    return $starting_branch;
}

sub _configure_build_one_commit {
    my ($self, $commit) = @_;

    my $starting_branch = $self->_configure_one_commit($commit);

    say "Running '$self->{make_command}'" if $self->{verbose};
    system($self->{make_command}) and croak "Unable to run '$self->{make_command})'";

    return $starting_branch;
}

sub _test_one_commit {
    my ($self, $commit, $current_targets) = @_; 
    my $short = substr($commit,0,$self->{short});
    my @outputs;
    for my $target (@{$current_targets}) {
        my $outputfile = File::Spec->catfile(
            $self->{outputdir},
            join('.' => (
                $short,
                $target->{stub},
                'output',
                'txt'
            )),
        );
        my $command_raw = $self->{test_command};
        my $cmd;
        unless ($command_raw eq 'harness') {
            $cmd = qq|$command_raw $target->{path} >$outputfile 2>&1|;
        }
        else {
            $cmd = qq|cd t; ./perl harness -v $target->{path} >$outputfile 2>&1; cd -|;
        }
        say "Running '$cmd'" if $self->{verbose};
        system($cmd) and croak "Unable to run test_command";
        $outputfile = clean_outputfile($outputfile);
        push @outputs, {
            commit => $commit,
            commit_short => $short,
            file => $outputfile,
            file_stub => $target->{stub},
            md5_hex => hexdigest_one_file($outputfile),
        };
        say "Created $outputfile" if $self->{verbose};
    }
    return \@outputs;
}

sub _bisection_decision {
    my ($self, $target_h_md5_hex, $current_start_md5_hex, $h, $relevant_self,
        $overall_end_md5_hex, $current_start_idx, $current_end_idx, $max_idx, $n) = @_;
    if ($target_h_md5_hex ne $current_start_md5_hex) {
        my $g = $h - 1;
        $self->_run_one_commit_and_assign($g);
        my $target_g_md5_hex  = $relevant_self->[$g]->{md5_hex};
        if ($target_g_md5_hex eq $current_start_md5_hex) {
            if ($target_h_md5_hex eq $overall_end_md5_hex) {
            }
            else {
                $current_start_idx  = $h;
                $current_end_idx    = $max_idx;
            }
            $n++;
        }
        else {
            # Bisection should continue downwards
            $current_end_idx = $h;
            $n++;
        }
    }
    else {
        # Bisection should continue upwards
        $current_start_idx = $h;
        $n++;
    }
    return ($current_start_idx, $current_end_idx, $n);
}

=head2 C<get_timings()>

=over 4

=item * Purpose

Get information on the time a multisection took to run.

=item * Arguments

None; all data needed is already in the object.

=item * Return Value

Hash reference.  The selection of elements in this hashref will depend on
which subclass of F<Devel::Git::MultiBisect> you are using and may differ among
subclasses.  Example:

    { elapsed => 4297, mean => 186.83, runs => 23 }

In this example (taken from a run of one test file over 220 commits in Perl 5
blead), 23 runs were needed to achieve a result.   These took 4297 seconds
(approximately 71 minutes) with a mean run time of approximately 3 minutes
each.

Method will return undefined value if timings are not yet available within the
object.

=back

=cut

sub get_timings {
	my $self = shift;
	return unless exists $self->{timings};
	return $self->{timings};
}

=head1 SUPPORT

Please report any bugs by mail to C<bug-Devel-Git-MultiBisect@rt.cpan.org>
or through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

James E. Keenan (jkeenan at cpan dot org).  When sending correspondence, please
include 'Devel::Git::MultiBisect' or 'Devel-Git-MultiBisect' in your subject line.

Creation date:  October 12 2016. Last modification date:  February 11 2019.

Development repository: L<https://github.com/jkeenan/devel-git-multibisect>

=head1 ACKNOWLEDGEMENTS

Thanks to the following contributors and reviewers:

=over 4

=item * Smylers

For naming suggestion: L<http://www.nntp.perl.org/group/perl.module-authors/2016/10/msg10851.html>

=item * Ricardo Signes

For feedback during initial development.

=item * Eily and Monk::Thomas

For diagnosis of regex problems in http://perlmonks.org/?node_id=1175983.

=back

=head1 COPYRIGHT

Copyright (c) 2016-2018 James E. Keenan.  United States.  All rights reserved.
This is free software and may be distributed under the same terms as Perl
itself.

=cut

1;

