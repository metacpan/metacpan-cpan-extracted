package Math::GrahamFunction::SqFacts;

use strict;
use warnings;

=head1 NAME

Math::GrahamFunction::SqFacts - a squaring factors vector.

=head1 WARNING!

This is a module for Math::GrahamFunction's internal use only.

=cut

use base qw(Math::GrahamFunction::Object);

use List::Util ();
__PACKAGE__->mk_accessors(qw(n factors));

sub _initialize
{
    my $self = shift;
    my $args = shift;

    if ($args->{n})
    {
        $self->n($args->{n});

        $self->_calc_sq_factors();
    }
    elsif ($args->{factors})
    {
        $self->factors($args->{factors});
    }
    else
    {
        die "factors or n must be supplied.";
    }

    return 0;
}

=head1 CONSTRUCTION

=head2 Math::GrahamFunction::SqFacts->new({n => $n})

Initializes a squaring factors object from a number.

=head2 Math::GrahamFunction::SqFacts->new({factors => \@factors})

Initializes a squaring factors object from a list of factors.

=head1 METHODS

=head2 $facts->clone()

Creates a clone of the object and returns it.

=cut

sub clone
{
    my $self = shift;
    return __PACKAGE__->new({'factors' => [@{$self->factors()}]});
}

sub _calc_sq_factors
{
    my $self = shift;

    $self->factors($self->_get_sq_facts($self->n()));

    return 0;
}

my %gsf_cache = (1 => []);

sub _get_sq_facts
{
    my $self = shift;
    my $n = shift;

    if (exists($gsf_cache{$n}))
    {
        return $gsf_cache{$n};
    }

    my $start_from = shift || 2;

    for(my $p=$start_from; ;$p++)
    {
        if ($n % $p == 0)
        {
            # This function is recursive to make better use of the Memoization
            # feature.
            my $division_factors = $self->_get_sq_facts(($n / $p), $p);
            if (@$division_factors && ($division_factors->[0] == $p))
            {
                return ($gsf_cache{$n} = [ @{$division_factors}[1 .. $#$division_factors] ]);
            }
            else
            {
                return ($gsf_cache{$n} = [ $p, @$division_factors ]);
            }
        }
    }
}

# Removed because it is too slow - we now use our own custom memoization (
# or perhaps it is just called caching)
# memoize('get_squaring_factors', 'NORMALIZER' => sub { return $_[0]; });

# This function multiplies the squaring factors of $n and $m to receive
# the squaring factors of ($n*$m)

# OOP-Wise, it should be a multi-method, but since we don't inherit this
# object it's all-right.

=head2 $n_facts->mult_by($m_facts)

Calculates the results of the multiplication of the number represented by
C<$n_facts> and C<$m_facts> and stores it in $n_facts (destructively).

This is actually addition in vector space.

=cut

sub mult_by
{
    my $n_ref = shift;
    my $m_ref = shift;

    my @n = @{$n_ref->factors()};
    my @m =
    eval {
        @{$m_ref->factors()};
    };
    if ($@)
    {
        print "Hello\n";
    }

    my @ret = ();

    while (scalar(@n) && scalar(@m))
    {
        if ($n[0] == $m[0])
        {
            shift(@n);
            shift(@m);
        }
        elsif ($n[0] < $m[0])
        {
            push @ret, shift(@n);
        }
        else
        {
            push @ret, shift(@m);
        }
    }
    push @ret, @n, @m;

    $n_ref->factors(\@ret);

    # 0 for success
    return 0;
}

=head2 my $result = $n->mult($m);

Non destructively calculates the multiplication and returns it.

=cut

sub mult
{
    my $n = shift;
    my $m = shift;

    my $result = $n->clone();
    $result->mult_by($m);
    return $result;
}

=head2 $facts->is_square()

A predicate that returns whether the factors represent a square number.

=cut

sub is_square
{
    my $self = shift;
    return (scalar(@{$self->factors()}) == 0);
}

=head2 $facts->exists($myfactor)

Checks whether C<$myfactor> exists in C<$facts>.

=cut

sub exists
{
    my ($self, $factor) = @_;

    return defined(List::Util::first { $_ == $factor } @{$self->factors()});
}

=head2 my $last_factor = $factors->last()

Returns the last (and greatest factor).

=cut

sub last
{
    my $self = shift;

    return $self->factors()->[-1];
}

use vars qw($a $b);

=head2 $facts->product()

Returns the product of the factors.

=cut

sub product
{
    my $self = shift;

    return (List::Util::reduce { $a * $b } @{$self->factors()});
}

=head2 $facts->first()

Returns the first (and smallest) factor.

=cut

sub first
{
    my $self = shift;

    return $self->factors()->[0];
}

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

B<Note:> the module meta-data says this module is released under the BSD
license. However, MIT X11 is the more accurate license, and "bsd" is
the closest option for the CPAN meta-data.

=cut

1;

