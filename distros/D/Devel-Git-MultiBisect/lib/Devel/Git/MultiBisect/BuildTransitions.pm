package Devel::Git::MultiBisect::BuildTransitions;
use strict;
use warnings;
use v5.10.0;
use parent ( qw| Devel::Git::MultiBisect | );
use Devel::Git::MultiBisect::Auxiliary qw(
    hexdigest_one_file
    validate_list_sequence
);
use Carp;
use Cwd;
use File::Spec;
use File::Temp qw( tempdir );
use Data::Dump qw(dd pp);

our $VERSION = '0.08';

=head1 NAME

Devel::Git::MultiBisect::BuildTransitions - Gather build-time output where it changes over a range of F<git> commits

=head1 SYNOPSIS

    use Devel::Git::MultiBisect::BuildTransitions;

    $self = Devel::Git::MultiBisect::BuildTransitions->new(\%parameters);

    $commit_range = $self->get_commits_range();

    $self->multisect_builds();

    $multisected_outputs = $self->get_multisected_outputs();

    $transitions = $self->inspect_transitions();
}

=head1 DESCRIPTION

When the number of commits in the specified range is large and you only need
the build-time output at those commits where the output materially changed, you can
use this package, F<Devel::Git::MultiBisect::BuildTransitions>.

=head1 METHODS

=head2 C<new()>

=cut

sub new {
    my ($class, $params) = @_;

    my $data = Devel::Git::MultiBisect::Init::init($params);

    delete $data->{targets};
    delete $data->{test_command};

    return bless $data, $class;
}

=head2 C<multisect_builds()>

=over 4

=item * Purpose

With a given set of configuration options and a specified range of F<git>
commits, identify the point where the "build command" -- typically, F<make>
-- first threw exceptions and then all subsequent commits where the build-time
exceptions materially changed.  A "material change" would be either a
correction of all exceptions or a set of different build-time exceptions from
those first observed.  Store the test output at those transition points for
human inspection.

=item * Arguments

    $self->multisect_builds();

    $self->multisect_builds({ probe => 'error' });

    $self->multisect_builds({ probe => 'warning' });

Optionally takes one hash reference.  At present that hashref may contain only
one element whose key is C<probe> and whose possible values are C<error> or
C<warning>.  Defaults to C<error>.  Select between those values depending on
whether you are probing for changes in errors or changes in warnings.

=item * Return Value

Returns true value upon success.

=item * Comment

As C<multisect_builds()> runs it does two kinds of things:

=over 4

=item *

It stores results data within the object which you can subsequently access through method calls.

=item *

It captures error messages from each commit run and writes them to a file on
disk for later human inspection.

=back

=back

=cut

sub multisect_builds {
    my ($self, $args) = @_;

    if (defined $args) {
        croak "Argument passed to multisect_builds() must be hashref"
            unless ref($args) eq 'HASH';
        my %good_keys = map {$_ => 1} (qw| probe |);
        for my $k (keys %{$args}) {
            croak "Invalid key '$k' in hashref passed to multisect_builds()"
                unless $good_keys{$k};
        }
        my %good_values = map {$_ => 1} (qw| error warning |);
        for my $v (values %{$args}) {
            croak "Invalid value '$v' in 'probe' element in hashref passed to multisect_builds()"
                unless $good_values{$v};
        }
    }
    $args->{probe} = 'error' unless defined $args->{probe};
    $self->{probe} = $args->{probe};

    # Prepare data structures in the object to hold results of build runs on a
    # per target, per commit basis.
    # Also, "prime" the data structure by performing build runs for each target
    # on the first and last commits in the commit range, storing that build
    # output on disk as well.

    my $start_time = time();
    my $all_outputs = $self->_prepare_for_multisection();

=pod

At this point, C<$all_outputs> is an array ref with one
element per commit in the commit range.  If a commit has been visited, the
element is a hash ref with 4 key-value pairs like the ones below.  If the
commit has not yet been visited, the element is C<undef>.

    [
      {
        commit => "7c9c5138c6a704d1caf5908650193f777b81ad23",
        commit_short => "7c9c513",
        file => "/home/jkeenan/learn/perl/multisect/7c9c513.make.errors.rpt.txt",
        md5_hex => "d41d8cd98f00b204e9800998ecf8427e",
      },
      undef,
      undef,
    ...
      undef,
      {
        commit => "8f6628e3029399ac1e48dfcb59c3cd30e5127c3e",
        commit_short => "8f6628e",
        file => "/home/jkeenan/learn/perl/multisect/8f6628e.make.errors.rpt.txt",
        md5_hex => "fdce7ff2f07a0a8cd64005857f4060d4",
      },
    ]

Unlike F<Devel::Git::MultiBisect::Transitions> -- where we could have been
testing multiple test files on each commit -- here we're only concerned with
recording the presence or absence of build-time errors.  Hence, we only need
an array of hash refs rather than an array of arrays of hash refs.

The multisection process will entail running C<run_build_on_one_commit()> over
each commit selected by the multisection algorithm.  Each run will insert a hash
ref with the 4 KVPs into C<@{$self-E<gt>{all_outputs}}>.  At the end of the
multisection process those elements which we did not need to visit will still be
C<undef>.  We will then analyze the defined elements to identify the
transitional commits.

The objective of multisection is to identify the git commits at which the
build output -- as reflected in a file on disk holding a list of normalized
errors -- materially changed.  We are using an md5_hex value for that error
file as a presumably valid unique identifier for that file's content.  A
transition point is a commit at which the output file's md5_hex differs from
that of the immediately preceding commit.  So, to identify the first
transition point, we need to locate the commit at which the md5_hex changed
from that found in the very first commit in the designated commit range.  Once
we've identified the first transition point, we'll look for the second
transition point, i.e., that where the md5_hex changed from that observed at
the first transition point.  We'll continue that process until we get to a
transition point where the md5_hex is identical to that of the very last
commit in the commit range.

=cut

    my ($min_idx, $max_idx)     = (0, $#{$self->{commits}});
    my $this_target_status      = 0;
    my $current_start_idx       = $min_idx;
    my $current_end_idx         = $max_idx;
    my $overall_start_md5_hex   = $self->{all_outputs}->[$min_idx]->{md5_hex};
    my $overall_end_md5_hex     = $self->{all_outputs}->[$max_idx]->{md5_hex};
    my $n = 0;

    while (! $this_target_status) {

        # What gets (or may get) updated or assigned to in the course of one rep of this loop:
        # $current_start_idx
        # $current_end_idx
        # $n
        # $self->{all_outputs}

        my $h = sprintf("%d" => (($current_start_idx + $current_end_idx) / 2));
        $self->_run_one_commit_and_assign($h);

        my $current_start_md5_hex = $self->{all_outputs}->[$current_start_idx]->{md5_hex};
        my $target_h_md5_hex      = $self->{all_outputs}->[$h]->{md5_hex};

        # Decision criteria:
        # If $target_h_md5_hex eq $current_start_md5_hex, then the first
        # transition is *after* index $h.  Hence bisection should go upwards.

        # If $target_h_md5_hex ne $current_start_md5_hex, then the first
        # transition has come *before* index $h.  Hence bisection should go
        # downwards.  However, since the test of where the first transition is
        # is that index j-1 has the same md5_hex as $current_start_md5_hex but
        #         index j   has a different md5_hex, we have to do a run on
        #         j-1 as well.

        ($current_start_idx, $current_end_idx, $n) =
            $self->_bisection_decision(
                $target_h_md5_hex, $current_start_md5_hex, $h,
                $self->{all_outputs},
                $overall_end_md5_hex, $current_start_idx, $current_end_idx,
                $max_idx, $n,
            );
        $this_target_status = $self->_evaluate_status_of_build_runs();
    }


    my $end_time = time();
    my %timings = (
	    elapsed	=> $end_time - $start_time,
        runs => scalar( grep {defined $_} @{$self->{all_outputs}} ),
    );
    $timings{mean} = sprintf("%.02f" => $timings{elapsed} / $timings{runs});
    if ($self->{verbose}) {
        say "Ran $timings{runs} runs; elapsed: $timings{elapsed} sec; mean: $timings{mean} sec";
    }
    $self->{timings}	  = \%timings;

    return 1;
}

sub _prepare_for_multisection {
    my $self = shift;

    # get_commits_range is inherited from parent

    my $all_commits = $self->get_commits_range();
    $self->{all_outputs} = [ (undef) x scalar(@{$all_commits}) ];

    my %multisected_outputs_table;
    for my $idx (0, $#{$all_commits}) {

        my $outputs = $self->run_build_on_one_commit($all_commits->[$idx]);
        $self->{all_outputs}->[$idx] = $outputs;
    }
    return $self->{all_outputs};
}

sub run_build_on_one_commit {
    my ($self, $commit) = @_;
    $commit //= $self->{commits}->[0]->{sha};
    say "Building commit: $commit" if ($self->{verbose});

    my $starting_branch = $self->_configure_one_commit($commit);

    my $outputsref = $self->_build_one_commit($commit);
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

sub _build_one_commit {
    my ($self, $commit) = @_;
    my $short_sha = substr($commit,0,$self->{short});
    my $build_log = File::Spec->catfile(
        $self->{outputdir},
        join('.' => (
            $short_sha,
            'make',
            'output',
            'txt'
        )),
    );
    my $command_raw = $self->{make_command};
    my $cmd = qq|$command_raw > $build_log 2>&1|;
    my $rv = system($cmd);
    my $filtered_probes_file = $self->_filter_build_log($build_log, $short_sha);
    say "Created $filtered_probes_file" if $self->{verbose};
    return {
        commit => $commit,
        commit_short => $short_sha,
        file => $filtered_probes_file,
        md5_hex => hexdigest_one_file($filtered_probes_file),
    };
}

sub _filter_build_log {
    my ($self, $buildlog, $short_sha) = @_;
    say "short_sha: $short_sha";
    my $tdir = tempdir( CLEANUP => 1 );

    if ($self->{probe} eq 'error') {
        # the default case:  probing for build-time errors
        my $ackpattern = q|-A2 '^[^:]+:\d+:\d+:\s+error:'|;
        my @raw_acklines = grep { ! m/^--\n/ } `ack $ackpattern $buildlog`;
        chomp(@raw_acklines);
        #pp(\@raw_acklines);
        croak "Got incorrect count of lines from ack; should be divisible by 3"
            unless scalar(@raw_acklines) % 3 == 0;

        my @refined_errors = ();
        for (my $i=0; $i <= $#raw_acklines; $i += 3) {
            my $j = $i + 2;
            my @this_error = ();
            my ($normalized) =
                $raw_acklines[$i] =~ s/^([^:]+):\d+:\d+:(.*)$/$1:_:_:$2/r;
            push @this_error, ($normalized, @raw_acklines[$i+1 .. $j]);
            push @refined_errors, \@this_error;
        }

        my $error_report_file =
            File::Spec->catfile($self->{workdir}, "$short_sha.make.errors.rpt.txt");
        say "rpt: $error_report_file";
        open my $OUT, '>', $error_report_file
            or croak "Unable to open $error_report_file for writing";
        if (@refined_errors) {
            for (my $i=0; $i<=($#refined_errors -1); $i++) {
                say $OUT join "\n" => @{$refined_errors[$i]};
                say $OUT "--";
            }
            say $OUT join "\n" => @{$refined_errors[-1]};
        }
        close $OUT or croak "Unable to close $error_report_file after writing";
        return $error_report_file;
    }
    else {
        my $ackpattern = qr/^
            ([^:]+):
            (\d+):
            (\d+):\s+warning:\s+
            (.*?)\s+\[-
            (W.*)]$
        /x;

        my @refined_warnings = ();
        open my $IN, '<', $buildlog or croak "Unable to open $buildlog for reading";
        while (my $l = <$IN>) {
            chomp $l;
            next unless $l =~ m/$ackpattern/;
            my ($source, $line, $character, $text, $class) = ($1, $2, $3, $4, $5);
            my $rl = "$source:_:_: warning: $text [$class]";
            push @refined_warnings, $rl;
        }
        close $IN or croak "Unable to close $buildlog after reading";

        my $warning_report_file =
            File::Spec->catfile($self->{workdir}, "$short_sha.make.warnings.rpt.txt");
        say "rpt: $warning_report_file";
        open my $OUT, '>', $warning_report_file
            or croak "Unable to open $warning_report_file for writing";
        say $OUT $_ for @refined_warnings;
        close $OUT or croak "Unable to close $warning_report_file after writing";
        return $warning_report_file;
    }
}

sub _evaluate_status_of_build_runs {
    my ($self) = @_;
    my @trans = ();
    for my $o (@{$self->{all_outputs}}) {
        push @trans,
            defined $o ? $o->{md5_hex} : undef;
    }
    my $vls = validate_list_sequence(\@trans);
    return ( (scalar(@{$vls}) == 1 ) and ($vls->[0])) ? 1 : 0;
}

sub _run_one_commit_and_assign {

    # If we've already stashed a particular commit's outputs in all_outputs,
    # then we don't need to actually perform a run.

    # This internal method assigns to all_outputs in place.

    my ($self, $idx) = @_;
    my $this_commit = $self->{commits}->[$idx]->{sha};
    unless (defined $self->{all_outputs}->[$idx]) {
        say "\nAt commit counter $self->{commit_counter}, preparing to test commit ", $idx + 1, " of ", scalar(@{$self->{commits}})
            if $self->{verbose};
        my $these_outputs = $self->run_build_on_one_commit($this_commit);
        $self->{all_outputs}->[$idx] = $these_outputs;
    }
}

=head2 C<get_multisected_outputs()>

=over 4

=item * Purpose

Get results of C<multisect_builds()> (other than test output files
created) reported on a per commit basis.

=item * Arguments

    my $multisected_outputs = $self->get_multisected_outputs();

None; all data needed is already present in the object.

=item * Return Value

Reference to an array with one element for each commit in the commit range.

=over 4

=item *

If a particular commit B<was not visited> in the course of
C<multisect_builds()>, then the array element is undefined.  (The point
of multisection, of course, is to B<not> have to visit every commit in the
commit range in order to figure out the commits at which test output changed.)

=item *

If a particular commit B<was visited> in the course of
C<multisect_builds()>, then the array element is a hash reference whose
elements have the following keys:

    commit
    commit_short
    file
    md5_hex

=back

=back

=cut

sub get_multisected_outputs {
    my $self = shift;
    return $self->{all_outputs};
}

=head2 C<inspect_transitions()>

=over 4

=item * Purpose

Get a data structure which reports on the most meaningful results of
C<multisect_builds()>, namely, the first commit, the last commit and all
transitional commits.

=item * Arguments

    my $transitions = $self->inspect_transitions();

None; all data needed is already present in the object.

=item * Return Value

Reference to a hash with 3 key-value pairs.  Each element's value is another
hash reference.  The elements of the top-level hash are:

=over 4

=item * C<oldest>

Value is reference to hash keyed on C<idx>, C<md5_hex> and C<file>, whose
values are, respectively, the index position of the very first commit in the
commit range, the digest of that commit's test output and the path to the file
holding that output.

=item * C<newest>

Value is reference to hash keyed on C<idx>, C<md5_hex> and C<file>, whose
values are, respectively, the index position of the very last commit in the
commit range, the digest of that commit's test output and the path to the file
holding that output.

=item * C<transitions>

Value is reference to an array with one element for each transitional commit.
Each such element is a reference to a hash with keys C<older> and C<newer>.
In this context C<older> refers to the last commit in a sub-sequence with a
particular digest; C<newer> refers to the next immediate commit which is the
first commit in a new sub-sequence with a new digest.

The values of C<older> and C<newer> are, in turn, references to hashes with
keys C<idx>, C<md5_hex> and C<file>.  Their values are, respectively, the index
position of the particular commit in the commit range, the digest of that
commit's test output and the path to the file holding that output.

=back

Example:


=item * Comment

The return value of C<inspect_transitions()> should be useful to the developer
trying to determine the various points in a long series of commits where a
target's test output changed in meaningful ways.  Hence, it is really the
whole point of F<Devel::Git::MultiBisect::BuildTransitions>.

=back

=cut

sub inspect_transitions {
    my ($self) = @_;
    my $multisected_outputs = $self->get_multisected_outputs();
    my %transitions;
    my $max_index = $#{$multisected_outputs};
    $transitions{transitions} = [];
    $transitions{oldest} = {
        idx     => 0,
        md5_hex => $multisected_outputs->[0]->{md5_hex},
        file    => $multisected_outputs->[0]->{file},
    };
    $transitions{newest} = {
        idx     => $max_index,
        md5_hex => $multisected_outputs->[$max_index]->{md5_hex},
        file    => $multisected_outputs->[$max_index]->{file},
    };
    for (my $j = 1; $j <= $max_index; $j++) {
        my $i = $j - 1;
        next unless (
            (defined $multisected_outputs->[$i]) and
            (defined $multisected_outputs->[$j])
        );
        my $older_md5_hex   = $multisected_outputs->[$i]->{md5_hex};
        my $newer_md5_hex   = $multisected_outputs->[$j]->{md5_hex};
        my $older_file      = $multisected_outputs->[$i]->{file};
        my $newer_file      = $multisected_outputs->[$j]->{file};
        unless ($older_md5_hex eq $newer_md5_hex) {
            push @{$transitions{transitions}}, {
                older => { idx => $i, md5_hex => $older_md5_hex, file => $older_file },
                newer => { idx => $j, md5_hex => $newer_md5_hex, file => $newer_file },
            }
        }
    }
    return \%transitions;
}

1;

__END__
