# perl
use strict;
use warnings;
use 5.10.1;
use Carp;
use Devel::Git::MultiBisect::Auxiliary qw(validate_list_sequence);
use List::Util qw( min max );
use Test::More;

=head1 NAME

examples/generalized-multisection.t

=head1 SYNOPSIS

    prove -v examples/generalized-multisection.t

=head1 DESCRIPTION

This program holds tests for the accuracy and efficiency of an implementation
of multiple bisection.

In this program we abstract away many of the considerations found in the rest
of CPAN distribution F<Devel-Git-MultiBisect>.  These include:

=over 4

=item *

The specific application domains:  the Perl 5 core distribution and CPAN
librairies.

=item *

F<git> as a source control mechanism.

=back

We make the following assumptions:

=over 4

=item *

We have a given body of source code which changes step-by-step (I<e.g.,>
commits) over time.

=item *

We can perform an action over the source code at each step which generates a
single, defined, non-empty string as a result.

=item *

If, from one step to another, there is no relevant change in the source code
and if we make no changes in the way we call the action (I<e.g.,> different
command-line options, different testing data), then the action will generate
the same result every time.

=item *

If the action has been producing string C<A> and we then make source code or
testing changes which generate string C<B>, no further changes will ever
generate C<A>, C<B>, etc., ever again.

=item *

We already know the total number of steps over which we can or will perform
the action.

=item *

We have already performed the action at the first and last steps in the
sequence, so we know the strings generated at those points.

=back

=cut

my @values = (
    "09431b9e74d329ef9ae0940eb0d279fb",
    "01ec704681e4680f683eaaaa6f83f79c",
    "b29d11b703576a350d91e1506674fd80",
    "481032a28823c8409a610e058b34a047",
);

{
    note("Case 1:");
    my @list = (
        (("$values[0]") x  55),
        (("$values[1]") x   4),
        (("$values[2]") x   6),
        (("$values[3]") x 155),
    );

    my $expected_transitional_values = {
      "0"   => "$values[0]",
      "54"  => "$values[0]",
      "55"  => "$values[1]",
      "58"  => "$values[1]",
      "59"  => "$values[2]",
      "64"  => "$values[2]",
      "65"  => "$values[3]",
      "219" => "$values[3]",
    };

    test_this_list(\@list, $expected_transitional_values);
}

{
    note("Case 2:");
    my @list = (
        (("$values[0]") x  54),
        (("$values[1]") x   5),
        (("$values[2]") x   6),
        (("$values[3]") x 155),
    );

    my $expected_transitional_values = {
      "0"   => "$values[0]",
      "53"  => "$values[0]",
      "54"  => "$values[1]",
      "58"  => "$values[1]",
      "59"  => "$values[2]",
      "64"  => "$values[2]",
      "65"  => "$values[3]",
      "219" => "$values[3]",
    };

    test_this_list(\@list, $expected_transitional_values);
}

{
    note("Case 3:");
    my @list = (
        (("$values[0]") x  56),
        (("$values[1]") x   4),
        (("$values[2]") x   6),
        (("$values[3]") x 154),
    );

    my $expected_transitional_values = {
      "0"   => "$values[0]",
      "55"  => "$values[0]",
      "56"  => "$values[1]",
      "59"  => "$values[1]",
      "60"  => "$values[2]",
      "65"  => "$values[2]",
      "66"  => "$values[3]",
      "219" => "$values[3]",
    };

    test_this_list(\@list, $expected_transitional_values);
}

{
    note("Case 4:");
    my @list = (
        (("$values[0]") x 217),
        (("$values[1]") x   1),
        (("$values[2]") x   1),
        (("$values[3]") x   1),
    );

    my $expected_transitional_values = {
      "0"   => "$values[0]",
      "216" => "$values[0]",
      "217" => "$values[1]",
      "218" => "$values[2]",
      "219" => "$values[3]",
    };

    test_this_list(\@list, $expected_transitional_values);
}

{
    note("Case 5:");
    my @list = (
        (("$values[0]") x 216),
        (("$values[1]") x   1),
        (("$values[2]") x   1),
        (("$values[3]") x   2),
    );

    my $expected_transitional_values = {
      "0"   => "$values[0]",
      "215" => "$values[0]",
      "216" => "$values[1]",
      "217" => "$values[2]",
      "218" => "$values[3]",
      "219" => "$values[3]",
    };

    test_this_list(\@list, $expected_transitional_values);
}

{
    note("Case 6:");
    my @list = (
        (("$values[0]") x 215),
        (("$values[1]") x   1),
        (("$values[2]") x   2),
        (("$values[3]") x   2),
    );

    my $expected_transitional_values = {
      "0"   => "$values[0]",
      "214" => "$values[0]",
      "215" => "$values[1]",
      "216" => "$values[2]",
      "217" => "$values[2]",
      "218" => "$values[3]",
      "219" => "$values[3]",
    };

    test_this_list(\@list, $expected_transitional_values);
}

done_testing();

########## BISECTION SUBROUTINES ##########

=head1 FUNCTIONS

=head2 C<multisect_list()>

=over 4

=item * Purpose

Identify all steps in the sequence where performing the action generates a new result.

=item * Arguments

    ($values, $indices_visited) = multisect_list( {
        action              => $action,
        list_count          => scalar(@{$list}),
        first_value         => $list->[0],
        last_value          => $list->[-1],
    } );

Reference to a hash with the following elements:

=over 4

=item * C<action>

Reference to a subroutine.

=item * C<list_count>

The number of steps in the sequence.

=item * C<first_value>

String holding the result from performing the action on the first step in the
sequence.

=item * C<last_value>

String holding the result from performing the action on the last step in the
sequence.

=back

=item * Return Value

List of two references to arrays.

=over 4

=item 1

Array with one element for each step in the original sequence.  If, for the
purpose of identifying a transition from one action result to another, we had
to perform the action at a given step, then the corresponding element in the
array is defined.  If, however, bisection meant we did not need to perform the
action at a given step, then the corresponding element in the array is
C<undef>.

Example (trimmed):

    [
      "09431b9e74d329ef9ae0940eb0d279fb",
      undef,
      undef,
      ...
      undef,
      undef,
      "09431b9e74d329ef9ae0940eb0d279fb",
      "01ec704681e4680f683eaaaa6f83f79c",
      "01ec704681e4680f683eaaaa6f83f79c",
      "01ec704681e4680f683eaaaa6f83f79c",
      "01ec704681e4680f683eaaaa6f83f79c",
      "b29d11b703576a350d91e1506674fd80",
      "b29d11b703576a350d91e1506674fd80",
      undef,
      undef,
      ...
      undef,
      "b29d11b703576a350d91e1506674fd80",
      "481032a28823c8409a610e058b34a047",
      "481032a28823c8409a610e058b34a047",
      "481032a28823c8409a610e058b34a047",
      undef,
      undef,
      ...
      undef,
      "481032a28823c8409a610e058b34a047",
    ],

=item 2

Array holding the index numbers of the steps in the sequence in the order in
which they were visited during bisection.  By definition, the first two
elements in this array will be C<0> and the total number of steps in the
sequence minus C<1>.

    [ 0, 219, 109, 108, 54, 81, 80, 67, 66, 60, 59, 57, 56, 55,
      137, 136, 96, 95, 75, 74, 65, 64, 58 ],

=back

=back

=cut

sub multisect_list {
    my $args = shift;
    croak "Must supply hashref" unless ref($args) eq 'HASH';
    for my $k ( qw|
        action
        list_count
        first_value
        last_value
    | ) {
        croak "Must supply '$k' element" unless exists $args->{$k};
    }
    my ($min_idx, $max_idx)     = (0, $args->{list_count} - 1);
    my $current_start_idx       = $min_idx;
    my $current_end_idx         = $max_idx;
    my $this_target_status      = 0;
    my @values = (
        $args->{first_value},
        ((undef) x ($args->{list_count} - 2)),
        $args->{last_value},
    );
    my @indices_visited = ($min_idx, $max_idx);

    while (! $this_target_status) {
        # At the end of each iteration of this loop, We will assign a boolean value to $this_target_status

        # What gets (or may get) updated or assigned to in the course of one rep of this loop:
        # $h
        # $current_start_value
        # $current_value
        # $current_start_idx
        # $current_end_idx
        # @values
        # @indices_visited

        my $h = sprintf("%d" => (($current_start_idx + $current_end_idx) / 2));

        unless (defined $values[$h]) {
            $values[$h] = $args->{action}($h);
            push @indices_visited, $h;
        }

        my $current_start_value = $values[$current_start_idx];
        my $current_value       = $values[$h];

        # Decision criteria:
        # If $current_value eq $current_start_value, then the first
        # transition is *after* index $h.  Hence bisection should go upwards.

        # If $current_value ne $current_start_value, then the first
        # transition has come *before* index $h.  Hence bisection should go
        # downwards.

        if ($current_value ne $current_start_value) {
            # Bisection should continue downwards, unless we've reached a
            # transition.
            my $g = $h - 1;
            unless (defined $values[$g]) {
                $values[$g] = $args->{action}($g);
                push @indices_visited, $g;
            }
            if ($values[$g] eq $current_start_value) {
                if ($current_value eq $args->{last_value}) {
                }
                else {
                    $current_start_idx  = $h;
                    $current_end_idx    = $max_idx;
                }
            }
            else {
                # Bisection should continue downwards
                $current_end_idx = $h;
            }
        }
        else {
            # Bisection should continue upwards
            $current_start_idx  = $h;
        }
        $this_target_status = _evaluate_status_one_run(\@values);
    }
    return (\@values, \@indices_visited);
}

sub _evaluate_status_one_run {
    my $trans = shift;
    my $vls = validate_list_sequence($trans);
    return ( (scalar(@{$vls}) == 1 ) and ($vls->[0])) ? 1 : 0;
}

=head2 C<prepare_report()>

=over 4

=item * Purpose

Generate a lookup table in which we can quickly see the indexes in the
sequence where the action result changed.

=item * Arguments

    $rep = prepare_report($values);

Single array reference:  the first array ref returned by C<multisect_list()>.

=item * Return Value

Reference to a hash whose elements are keyed on the indices of the
transitional steps, I<i.e.,> the first and last steps and the "before" and
"after" steps at every transitional point.  The values are the corresponding
strings returned by performing the action at each such step.

Example:  If there were 220 steps in the sequence, the return value would look
something like this:

    {
      "0"   => "09431b9e74d329ef9ae0940eb0d279fb",
      "54"  => "09431b9e74d329ef9ae0940eb0d279fb",
      "55"  => "01ec704681e4680f683eaaaa6f83f79c",
      "58"  => "01ec704681e4680f683eaaaa6f83f79c",
      "59"  => "b29d11b703576a350d91e1506674fd80",
      "64"  => "b29d11b703576a350d91e1506674fd80",
      "65"  => "481032a28823c8409a610e058b34a047",
      "219" => "481032a28823c8409a610e058b34a047",
    }

This hashref can then be compared to a hashref with the indices and values we
expected.

=back

=cut

sub prepare_report {
    my $trans = shift;
    croak "Must supply array ref" unless ref($trans) eq 'ARRAY';
    my %seen = ();
    for my $i (0 .. $#{$trans}) {
        push @{$seen{$trans->[$i]}}, $i if defined $trans->[$i];
    }
    my %report = ();
    for my $result (keys %seen) {
        my $first_seen = min(@{$seen{$result}});
        my $last_seen  = max(@{$seen{$result}});
        $report{$first_seen} = $result;
        $report{$last_seen}  = $result;
    }
    return \%report;
}

########## TESTING SUBROUTINES ##########

sub generate_action {
    my $listref = shift;
    my $action = sub {
        my $idx = shift;
        croak "Must provide non-negative integer corresponding to index in list"
            unless ( $idx =~ m/^\d+$/ and $idx >= 0 and $idx <= $#{$listref} );
        return $listref->[$idx];
    };
    return $action;
}

sub test_this_list {
    my ($list, $expected_transitional_values) = @_;

    my $action = generate_action($list);

    my ($values, $indices_visited) = multisect_list( {
        action              => $action,
        list_count          => scalar(@{$list}),
        first_value         => $list->[0],
        last_value          => $list->[-1],
    } );
    is(scalar(@{$values}), scalar(@{$list}), "Got expected number of elements in report");
    pass(scalar(@{$indices_visited}) . " commits visited");

    my $rep = prepare_report($values);
    is_deeply($rep, $expected_transitional_values,
        "Got expected look-up table of transitions");
}

