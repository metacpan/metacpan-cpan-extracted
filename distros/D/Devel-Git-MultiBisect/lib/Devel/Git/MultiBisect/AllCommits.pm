package Devel::Git::MultiBisect::AllCommits;
use strict;
use warnings;
use v5.10.0;
use parent( qw| Devel::Git::MultiBisect | );
use Devel::Git::MultiBisect::Opts qw( process_options );
use Devel::Git::MultiBisect::Auxiliary qw(
    clean_outputfile
    hexdigest_one_file
    validate_list_sequence
);
use Carp;
use Cwd;
use File::Temp;
use List::Util qw(first sum);

our $VERSION = '0.10';

=head1 NAME

Devel::Git::MultiBisect::AllCommits - Gather test output over an entire range of F<git> commits

=head1 SYNOPSIS

    use Devel::Git::MultiBisect::AllCommits;

    $self = Devel::Git::MultiBisect::AllCommits->new(\%parameters);

    $commit_range = $self->get_commits_range();

    $full_targets = $self->set_targets(\@target_args);

    $outputs = $self->run_test_files_on_one_commit($commit_range->[0]);

    $all_outputs = $self->run_test_files_on_all_commits();

    $rv = $self->get_digests_by_file_and_commit();

    $transitions = $self->examine_transitions();

=head1 DESCRIPTION

Given a Perl library or application kept in F<git> for version control, it is
often useful to be able to compare the output collected from running one or
several test files over a range of F<git> commits.  If that range is sufficiently
large, a test may fail in B<more than one way> over that range.

If that is the case, then simply asking, I<"When did this file start to
fail?"> is insufficient.  We may want to capture the test output for each
commit, or, more usefully, may want to capture the test output only at those
commits where the output changed.

F<Devel::Git::MultiBisect> provides methods to achieve that objective.  More specifically:

=over 4

=item *

When you want to capture the test output for each commit in a specified range,
you can use this package, F<Devel::Git::MultiBisect::AllCommits>.

=item *

When the number of commits in the specified range is large and you only need
the test output at those commits where the output materially changed, you can
use another package found in this library, F<Devel::Git::MultiBisect::Transitions>.

=back

=head1 METHODS

This package inherits methods from F<Devel::Git::MultiBisect>.  Only methods unique to
F<Devel::Git::MultiBisect::AllCommits> are documented here.  See the documentation for
F<Devel::Git::MultiBisect> for all other methods, including:

    new()
    get_commits_range()
    set_targets()
    run_test_files_on_one_commit()

=head2 C<run_test_files_on_all_commits()>

=over 4

=item * Purpose

Capture the output from a run of the selected test files at each specific git
checkout in the selected commit range.

=item * Arguments

    $all_outputs = $self->run_test_files_on_all_commits();

None; all data needed is already present in the object.

=item * Return Value

Array reference, each of whose elements is an array reference, each of whose
elements is a hash reference with the same four keys as in the return value
from C<run_test_files_on_one_commit()>:

    commit
    commit_short
    file
    file_stub
    md5_hex

Example:

    [
      # Array where each element corresponds to a single git checkout

      [
        # Array where each element corresponds to one of the selected test
        # files (here, 2 test files were targetd)

        {
          # Hash where each element correponds to the result of running a
          # single test file at a single commit point

          commit => "2a2e54af709f17cc6186b42840549c46478b6467",
          commit_short => "2a2e54a",
          file => "/tmp/AHC_YkwUYg/2a2e54a.t_44_func_hashes_mult_unsorted_t.output.txt",
          file_stub => "t_44_func_hashes_mult_unsorted_t",
          md5_hex => "31b7c93474e15a16d702da31989ab565",
        },
        {
          commit => "2a2e54af709f17cc6186b42840549c46478b6467",
          commit_short => "2a2e54a",
          file => "/tmp/AHC_YkwUYg/2a2e54a.t_45_func_hashes_alt_dual_sorted_t.output.txt",
          file_stub => "t_45_func_hashes_alt_dual_sorted_t",
          md5_hex => "6ee767b9d2838e4bbe83be0749b841c1",
        },
      ],
      [
        {
          commit => "a624024294a56964eca53ec4617a58a138e91568",
          commit_short => "a624024",
          file => "/tmp/AHC_YkwUYg/a624024.t_44_func_hashes_mult_unsorted_t.output.txt",
          file_stub => "t_44_func_hashes_mult_unsorted_t",
          md5_hex => "31b7c93474e15a16d702da31989ab565",
        },
        {
          commit => "a624024294a56964eca53ec4617a58a138e91568",
          commit_short => "a624024",
          file => "/tmp/AHC_YkwUYg/a624024.t_45_func_hashes_alt_dual_sorted_t.output.txt",
          file_stub => "t_45_func_hashes_alt_dual_sorted_t",
          md5_hex => "6ee767b9d2838e4bbe83be0749b841c1",
        },
      ],
    # ...
      [
        {
          commit => "d304a207329e6bd7e62354df4f561d9a7ce1c8c2",
          commit_short => "d304a20",
          file => "/tmp/AHC_YkwUYg/d304a20.t_44_func_hashes_mult_unsorted_t.output.txt",
          file_stub => "t_44_func_hashes_mult_unsorted_t",
          md5_hex => "31b7c93474e15a16d702da31989ab565",
        },
        {
          commit => "d304a207329e6bd7e62354df4f561d9a7ce1c8c2",
          commit_short => "d304a20",
          file => "/tmp/AHC_YkwUYg/d304a20.t_45_func_hashes_alt_dual_sorted_t.output.txt",
          file_stub => "t_45_func_hashes_alt_dual_sorted_t",
          md5_hex => "6ee767b9d2838e4bbe83be0749b841c1",
        },
      ],
    ]

=item * Comment

Note:  If the number of commits in the commits range is large, this method
will take a long time to run.  That time will be even longer if the
configuration and build times for each commit are large.  For example, to run
one test over 160 commits from the Perl 5 core distribution might take 15
hours.  YMMV.  If either of these conditions holds, you are probably better
off using F<Devel::Git::MultiBisect::Transitions>.

The implementation of this method is very much subject to change.

=back

=cut

sub run_test_files_on_all_commits {
    my $self = shift;
    my $all_commits = $self->get_commits_range();
    my @all_outputs;
    my $start_time = time();
    for my $commit (@{$all_commits}) {
        my $outputs = $self->run_test_files_on_one_commit($commit);
        push @all_outputs, $outputs;
    }
    my $end_time = time();
    my %timings = (
	    elapsed	=> $end_time - $start_time,
	    runs	=> scalar(@{$all_commits}),
    );
    if ($timings{runs}) {
        $timings{mean} = sprintf("%.02f" => $timings{elapsed} / $timings{runs});    }
    if ($self->{verbose}) {
        my $msg = "Ran $timings{runs} runs; elapsed: $timings{elapsed} sec";
        if ($timings{runs}) {
            $msg .= "; mean: $timings{mean} sec";
        }
        say $msg;
    }
    $self->{all_outputs}  = [ @all_outputs ];
    $self->{timings}	  = \%timings;
    return \@all_outputs;
}


=head2 C<get_digests_by_file_and_commit()>

=over 4

=item * Purpose

Present the same outcomes as C<run_test_files_on_all_commits()>, but formatted
by target file, then commit.

=item * Arguments

    $rv = $self->get_digests_by_file_and_commit();

None; all data needed is already present in the object.

=item * Return Value

Reference to a hash keyed on the basename of the target file, modified to
substitute underscores for forward slashes and dots.  The value of each
element in the hash is a reference to an array which, in turn, holds a list of
hash references, one per F<git> commit.  Each such hash has the following keys:

    commit
    file
    md5_hex

Example:

    {
      t_44_func_hashes_mult_unsorted_t   => [
          {
            commit  => "2a2e54af709f17cc6186b42840549c46478b6467",
            file    => "/tmp/Xhilc8ZSgS/2a2e54a.t_44_func_hashes_mult_unsorted_t.output.txt",
            md5_hex => "31b7c93474e15a16d702da31989ab565",
          },
          {
            commit  => "a624024294a56964eca53ec4617a58a138e91568",
            file    => "/tmp/Xhilc8ZSgS/a624024.t_44_func_hashes_mult_unsorted_t.output.txt",
            md5_hex => "31b7c93474e15a16d702da31989ab565",
          },
          # ...
          {
            commit  => "d304a207329e6bd7e62354df4f561d9a7ce1c8c2",
            file    => "/tmp/Xhilc8ZSgS/d304a20.t_44_func_hashes_mult_unsorted_t.output.txt",
            md5_hex => "31b7c93474e15a16d702da31989ab565",
          },
      ],
      t_45_func_hashes_alt_dual_sorted_t => [
          {
            commit  => "2a2e54af709f17cc6186b42840549c46478b6467",
            file    => "/tmp/Xhilc8ZSgS/2a2e54a.t_45_func_hashes_alt_dual_sorted_t.output.txt",
            md5_hex => "6ee767b9d2838e4bbe83be0749b841c1",
          },
          {
            commit  => "a624024294a56964eca53ec4617a58a138e91568",
            file    => "/tmp/Xhilc8ZSgS/a624024.t_45_func_hashes_alt_dual_sorted_t.output.txt",
            md5_hex => "6ee767b9d2838e4bbe83be0749b841c1",
          },
          # ...
          {
            commit  => "d304a207329e6bd7e62354df4f561d9a7ce1c8c2",
            file    => "/tmp/Xhilc8ZSgS/d304a20.t_45_func_hashes_alt_dual_sorted_t.output.txt",
            md5_hex => "6ee767b9d2838e4bbe83be0749b841c1",
          },
      ],
    }


=item * Comment

This method currently presumes that you have called
C<run_test_files_on_all_commits()>.  It will die otherwise.

=back

=cut

sub get_digests_by_file_and_commit {
    my $self = shift;
    unless (exists $self->{all_outputs}) {
        croak "You must call run_test_files_on_all_commits() before calling get_digests_by_file_and_commit()";
    }
    my $rv = {};
    for my $commit (@{$self->{all_outputs}}) {
        for my $target (@{$commit}) {
            push @{$rv->{$target->{file_stub}}},
                {
                    commit  => $target->{commit},
                    file    => $target->{file},
                    md5_hex => $target->{md5_hex},
                };
        }
    }
    return $rv;
}

=head2 C<examine_transitions()>

=over 4

=item * Purpose

Determine whether a run of the same targeted test file run at two consecutive
commits produced the same or different output (as measured by string equality
or inequality of each commit's md5_hex value.

=item * Arguments

    $hashref = $self->get_digests_by_file_and_commit();

    $transitions = $self->examine_transitions($hashref);

Hash reference returned by C<get_digests_by_file_and_commit()>;

=item * Return Value

Reference to a hash keyed on the basename of the target file, modified to
substitute underscores for forward slashes and dots.  The value of each
element in the hash is a reference to an array which, in turn, holds a list of
hash references, one per each pair of consecutive F<git> commits.  Each such hash
has the following keys:

    older
    newer
    compare

The value for each of the C<older> and C<newer> elements is a reference to a
hash with two elements:

    md5_hex
    idx

... where C<md5_hex> is the digest of the test output file and C<idx> is the
position (count starting at C<0>) of that element in the list of commits in
the commit range.

Example:

    {
      t_44_func_hashes_mult_unsorted_t   => [
          {
            compare => "same",
            newer   => { md5_hex => "31b7c93474e15a16d702da31989ab565", idx => 1 },
            older   => { md5_hex => "31b7c93474e15a16d702da31989ab565", idx => 0 },
          },
          {
            compare => "same",
            newer   => { md5_hex => "31b7c93474e15a16d702da31989ab565", idx => 2 },
            older   => { md5_hex => "31b7c93474e15a16d702da31989ab565", idx => 1 },
          },
          # ...
          {
            compare => "same",
            newer   => { md5_hex => "31b7c93474e15a16d702da31989ab565", idx => 9 },
            older   => { md5_hex => "31b7c93474e15a16d702da31989ab565", idx => 8 },
          },
      ],
      t_45_func_hashes_alt_dual_sorted_t => [
          {
            compare => "same",
            newer   => { md5_hex => "6ee767b9d2838e4bbe83be0749b841c1", idx => 1 },
            older   => { md5_hex => "6ee767b9d2838e4bbe83be0749b841c1", idx => 0 },
          },
          {
            compare => "same",
            newer   => { md5_hex => "6ee767b9d2838e4bbe83be0749b841c1", idx => 2 },
            older   => { md5_hex => "6ee767b9d2838e4bbe83be0749b841c1", idx => 1 },
          },
          {
            compare => "same",
            newer   => { md5_hex => "6ee767b9d2838e4bbe83be0749b841c1", idx => 3 },
            older   => { md5_hex => "6ee767b9d2838e4bbe83be0749b841c1", idx => 2 },
          },
          # ...
          {
            compare => "same",
            newer   => { md5_hex => "6ee767b9d2838e4bbe83be0749b841c1", idx => 9 },
            older   => { md5_hex => "6ee767b9d2838e4bbe83be0749b841c1", idx => 8 },
          },
      ],
    }

=item * Comment

This method currently may be called only after calling
C<run_test_files_on_all_commits()> and will die otherwise.

Since in this method we are concerned with the B<transition> in the test
output between a pair of commits, the second-level arrays returned by this
method will have one fewer element than the second-level arrays returned by
C<get_digests_by_file_and_commit()>.

=back

=cut

sub examine_transitions {
    my ($self, $rv) = @_;
    my %transitions;
    for my $k (sort keys %{$rv}) {
        my @arr = @{$rv->{$k}};
        for (my $i = 1; $i <= $#arr; $i++) {
            my $older = $arr[$i-1]->{md5_hex};
            my $newer = $arr[$i]->{md5_hex};
            if ($older eq $newer) {
                push @{$transitions{$k}}, {
                    older => { idx => $i-1, md5_hex => $older },
                    newer => { idx => $i,   md5_hex => $newer },
                    compare => 'same',
                }
            }
            else {
                push @{$transitions{$k}}, {
                    older => { idx => $i-1, md5_hex => $older },
                    newer => { idx => $i,   md5_hex => $newer },
                    compare => 'different',
                }
            }
        }
    }
    return \%transitions;
}

1;

