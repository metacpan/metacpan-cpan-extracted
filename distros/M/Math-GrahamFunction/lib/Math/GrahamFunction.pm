package Math::GrahamFunction;

use warnings;
use strict;

use 5.008;

=head1 NAME

Math::GrahamFunction - Calculate the Graham's Function of a Natural
Number.

=head1 VERSION

Version 0.02000

=cut

our $VERSION = '0.02001';

use base qw(Math::GrahamFunction::Object);

use Math::GrahamFunction::SqFacts;
use Math::GrahamFunction::SqFacts::Dipole;

__PACKAGE__->mk_accessors(qw(
    _base
    n
    _n_vec
    next_id
    _n_sq_factors
    primes_to_ids_map
    ));

sub _initialize
{
    my $self = shift;
    my $args = shift;

    $self->n($args->{n}) or
        die "n was not specified";

    $self->primes_to_ids_map({});

    return 0;
}

=head1 SYNOPSIS

    use Math::GrahamFunction;

    my $calc = Math::GrahamFunction->new({ 'n' => 500 });

    my $results = $calc->solve();

    print "The Graham Function of 500 is ",
        $results->{'factors'}->[-1],
        "\n";

=head1 DESCRIPTION

The Graham Function of a natural number B<n>, which we will denote by B<G(n)>,
is the minimal number for which there's an increasing series of integers
that starts at B<n> and ends at B<G(n)> whose product is a perfect square.

This module calculates the Graham Function of a natural number, along with
the entire associated series.

=head2 BACKGROUND

On 11 December 2002, Mark Jason Dominus gave a Perl Quiz-of-the-week
challenge to write a Perl program to calculate the Graham Function. I came
up with a solution for it, whose complexity was polynomial (as opposed to
brute force solutions, which are exponential complexity.). This module is
derived from my original code, after it was heavily refactored.

More information about the algorithm and the original code can be found here:

L<http://www.shlomifish.org/lecture/Perl/Graham-Function/>

=head1 FUNCTIONS

=head2 my $calc = Math::GrahamFunction->new({'n' => $n});

Initializes a new object for solving the Graham's Function of the
number C<$n>. Call solve() next.

=head2 my $results = $calc->solve();

Calculates the Graham's Function series for the number (could be
time consuming), and returns a hash ref of results. The only field
of interest there is C<'factors'>, which points to an array reference
of the series. The series is increasing so
C<$results->{factors}->[0]> is C<$n> and
C<$results->{factors}->[-1]} is the Graham's Function.

=head2 $self->_get_num_facts($number)

Get the Square factors of the number $number.

=cut

sub _get_num_facts
{
    my ($self, $number) = @_;

    return Math::GrahamFunction::SqFacts->new({ 'n' => $number });
}

sub _get_facts
{
    my ($self, $factors) = @_;

    return
        Math::GrahamFunction::SqFacts->new(
            { 'factors' =>
                (ref($factors) eq "ARRAY" ? $factors : [$factors])
            }
        );
}

sub _get_num_dipole
{
    my ($self, $number) = @_;

    return Math::GrahamFunction::SqFacts::Dipole->new(
        {
            'result' => $self->_get_num_facts($number),
            'compose' => $self->_get_facts($number),
        }
    );

}

sub _calc_n_sq_factors
{
    my $self = shift;

    $self->_n_sq_factors(
        $self->_get_num_dipole($self->n)
    );
}

sub _check_largest_factor_in_between
{
    my $self = shift;

    my $n = $self->n();
    # Cheating:
    # Check if between n and n+largest_factor we can fit
    # a square of SqFact{n*(n+largest_factor)}. If so, return
    # n+largest_factor.
    #
    # So, for instance, if n = p than n+largest_factor = 2p
    # and so SqFact{p*(2p)} = 2 and it is possible to see if
    # there's a 2*i^2 between p and 2p. That way, p*2*i^2*2p is
    # a square number.

    my $largest_factor = $self->_n_sq_factors()->last();

    my ($lower_bound, $lb_sq_factors);

    $lower_bound = $self->n() + $largest_factor;
    while (1)
    {
        $lb_sq_factors = $self->_get_num_facts($lower_bound);
        if ($lb_sq_factors->exists($largest_factor))
        {
            last;
        }
        $lower_bound += $largest_factor;
    }

    my $n_times_lb = $self->_n_sq_factors->result->mult($lb_sq_factors);

    my $rest_of_factors_product = $n_times_lb->product();

    my $low_square_val = int(sqrt($n/$rest_of_factors_product));
    my $high_square_val = int(sqrt($lower_bound/$rest_of_factors_product));

    if ($low_square_val != $high_square_val)
    {
        my @factors =
        (
            $n,
            ($low_square_val+1)*($low_square_val+1)*$rest_of_factors_product,
            $lower_bound
        );
        # TODO - possibly convert to Dipole
        # return ($lower_bound, $self->_get_facts(\@factors));
        return \@factors;
    }
    else
    {
        return;
    }
}

sub _get_next_id
{
    my $self = shift;
    return $self->next_id($self->next_id()+1);
}

sub _get_prime_id
{
    my $self = shift;
    my $p = shift;
    return $self->primes_to_ids_map()->{$p};
}

sub _register_prime
{
    my ($self, $p) = @_;
    $self->primes_to_ids_map()->{$p} = $self->_get_next_id();
}

sub _prime_exists
{
    my ($self, $p) = @_;
    return exists($self->primes_to_ids_map->{$p});
}

sub _get_min_id
{
    my ($self, $vec) = @_;

    my $min_id = -1;
    my $min_p = 0;

    foreach my $p (@{$vec->result()->factors()})
    {
        my $id = $self->_get_prime_id($p);
        if (($min_id < 0) || ($min_id > $id))
        {
            $min_id = $id;
            $min_p = $p;
        }
    }

    return ($min_id, $min_p);
}

sub _try_to_form_n
{
    my $self = shift;

    while (! $self->_n_vec->is_square())
    {
        # Calculating $id as the minimal ID of the squaring factors of $p
        my ($id, undef) = $self->_get_min_id($self->_n_vec);

        # Multiply by the controlling vector of this ID if it exists
        # or terminate if it doesn't.
        return 0 if (!defined($self->_base->[$id]));
        $self->_n_vec->mult_by($self->_base->[$id]);
    }

    return 1;
}

sub _get_final_factors
{
    my $self = shift;

    $self->_calc_n_sq_factors();

    # The graham number of a perfect square is itself.
    if ($self->_n_sq_factors->is_square())
    {
        return $self->_n_sq_factors->_get_ret();
    }
    elsif (defined(my $ret = $self->_check_largest_factor_in_between()))
    {
        return $ret;
    }
    else
    {
        return $self->_main_solve();
    }
}

sub solve
{
    my $self = shift;

    return { factors => $self->_get_final_factors() };
}

sub _main_init
{
    my $self = shift;

    $self->next_id(0);

    $self->_base([]);

    # Register all the primes in the squaring factors of $n
    foreach my $p (@{$self->_n_sq_factors->factors()})
    {
        $self->_register_prime($p);
    }

    # $self->_n_vec is used to determine if $n can be composed out of the
    # base's vectors.
    $self->_n_vec($self->_n_sq_factors->clone());

    return;
}

=begin none

# A method to print the base. It is not used but can prove useful for
# debugging.
sub _print_base
{
    my $self = shift;
    print "Base=\n\n";
    for(my $j = 0 ; $j < scalar( @{$self->_base()} ) ; $j++)
    {
        next if (! defined($self->_base->[$j]));
        print "base[$j] (" . join(" * ", @{$self->_base->[$j]}) . ")\n";
    }
    print "\n\n";
};

=end none

=cut

sub _update_base
{
    my ($self, $final_vec) = @_;

    # Get the minimal ID and its corresponding prime number
    # in $final_vec.
    my ($min_id, $min_p) = $self->_get_min_id($final_vec);

    if ($min_id >= 0)
    {
        # Assign $final_vec as the controlling vector for this prime
        # number
        $self->_base->[$min_id] = $final_vec;
        # Canonicalize the rest of the vectors with the new vector.
        CANON_LOOP:
        for(my $j=0;$j<scalar(@{$self->_base()});$j++)
        {
            if (($j == $min_id) || (! defined($self->_base->[$j])))
            {
                next CANON_LOOP;
            }
            if ($self->_base->[$j]->exists($min_p))
            {
                $self->_base->[$j]->mult_by($final_vec);
            }
        }
    }
}

sub _get_final_composition
{
    my ($self, $i_vec) = @_;

    # $final_vec is the new vector to add after it was
    # stair-shaped by all the controlling vectors in the base.

    my $final_vec = $i_vec;

    foreach my $p (@{$i_vec->factors()})
    {
        if (!$self->_prime_exists($p))
        {
            $self->_register_prime($p);
        }
        else
        {
            my $id = $self->_get_prime_id($p);
            if (defined($self->_base->[$id]))
            {
                $final_vec->mult_by($self->_base->[$id]);
            }
        }
    }

    return $final_vec;
}

sub _get_i_vec
{
    my ($self, $i) = @_;

    my $i_vec = $self->_get_num_dipole($i);
    # Skip perfect squares - they do not add to the solution
    if ($i_vec->is_square())
    {
        return;
    }

    # Check if $i is a prime number
    # We need n > 2 because for n == 2 it does include a prime number.
    #
    # Prime numbers cannot be included because 2*n is an upper bound
    # to G(n) and so if there is a prime p > n than its next multiple
    # will be greater than G(n).
    if (($self->n() > 2) && ($i_vec->first() == $i))
    {
        return;
    }

    return $i_vec;
}

sub _solve_iteration
{
    my ($self, $i) = @_;

    my $i_vec = $self->_get_i_vec($i)
        or return;

    my $final_vec = $self->_get_final_composition($i_vec);

    $self->_update_base($final_vec);

    # Check if we can form $n
    if ($self->_try_to_form_n())
    {
        return $self->_n_vec->_get_ret();
    }
    else
    {
        return;
    }
}

sub _main_solve
{
    my $self = shift;

    $self->_main_init();

    for(my $i=$self->n()+1;;$i++)
    {
        if (defined(my $ret = $self->_solve_iteration($i)))
        {
            return $ret;
        }
    }
}

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 KNOWN BUGS

The module may yield different sequences with its "factor in between"
optimization than without it. The last number (= the Graham function)
is the same, but the numbers in between are different. A future release
will provide a flag to disable that optimization.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-grahamfunction at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math::GrahamFunction>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::GrahamFunction

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math::GrahamFunction>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math::GrahamFunction>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math::GrahamFunction>

=item * Search CPAN

L<http://search.cpan.org/dist/Math::GrahamFunction>

=back

=head1 SOURCE AVAILABILITY

The latest source for this module is available from its subversion repository:

L<http://svn.berlios.de/svnroot/repos/web-cpan/Math-GrahamFunction/trunk>

=head1 ACKNOWLEDGEMENTS

Mark Jason Dominus ( L<http://perl.plover.com/> ) for the original Graham
Function Quiz-of-the-Week.

imacat (L<http://www.imacat.idv.tw/>) and David Golden for helping me
debug a CPAN smoking failure with installing this module on imacat's
computer.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

B<Note:> the module meta-data says this module is released under the BSD
license. However, MIT X11 is the more accurate license, and "bsd" is
the closest option for the CPAN meta-data.

=cut

1; # End of Math::GrahamFunction
