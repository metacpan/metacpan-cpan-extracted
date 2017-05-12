package Math::ContinuedFraction;

use warnings;
use strict;
use Carp;
use Math::BigInt;
use Math::BigRat;
#use Smart::Comments;

our $VERSION = '0.11';

#
# $cf = Math::ContinuedFraction->new([1, 1, 1, 1, [3, 2, 3, 2]]);
#
#
sub new
{
	my $class = shift;
	my $self = {};
	my(@seq);

	if (ref $class)
	{
		if ($class->isa(__PACKAGE__))
		{
			$class->_copy($self);
			return bless($self, ref $class);
		}

		warn "Attempts to create a Continued Fraction object from a '",
			ref $class, "' object fail.\n";
		return undef;
	}

	bless($self, $class);

	#
	# We're not creating a copy of an existing CF, so start from
	# first principles.
	#
	$self->{simple} = [0];
	$self->{repeat} = undef;

	if (scalar @_)
	{
		#
		# Get the a's and b's.
		# SHHH! Don't tell anyone about the b's yet, but
		# they'll get accessed in a later version.
		#
		my($a_ref, $b_ref) = @_;

		if (ref $a_ref eq "ARRAY")
		{
			my(@seq) = @$a_ref;

			#
			# See if there's a repeating component. If there is, check for
			# one of those "Why are you doing that" empty array cases.
			#
			if (ref $seq[$#seq] eq "ARRAY")
			{
				my @r = @{ pop @seq };
				$self->{repeat} = [@r] if (scalar @r > 0);
			}

			#
			# Another empty array case check, this one slightly legitimate.
			#
			$self->{simple} = (scalar @seq)? [@seq]: [0];
		}
		elsif (ref $a_ref eq "Math::BigRat")
		{
			my($n, $d) = $a_ref->parts();

			#
			# Do from_ratio stuff.
			#
			$self->from_ratio($n, $d);
		}
		else
		{
			#
			# Complain bitterly if we weren't passed an ARRAY or
			# BigRat reference.
			#
			carp __PACKAGE__ .
				"->new() takes either an array reference or a Math::BigRat object or another " .
				__PACKAGE__ . " object";
			return undef;
		}
	}

	return $self;
}

#
# my $cf67_29 = Math::ContinuedFraction->from_ratio(67, 29);
#
# Create a continued fraction from a simple ratio.
# These CFs will always be the simple types.
#
sub from_ratio
{
	my $class = shift;
	my($n, $d) = @_;
	my $self = {};
	my @cf;

	use integer;

	LOOP:
	for (;;)
	{
		my $q = $n / $d;
		my $r = $n % $d;

		push @cf, $q;
		last LOOP if ($r == 0);
		if ($r == 1)
		{
			push @cf, $d;
			last LOOP;
		}
		$n = $d;
		$d = $r;
	}

	$self->{simple} = [@cf];
	$self->{repeat} = undef;
	return bless($self, $class);
}

#
# $qs = Math::ContinuedFraction->from_quadratic($a, $b, $c);
#
sub from_root
{
	my $class = shift;
	my($dis) = @_;
	my $self = {};
	my(@repeat);

	my($p, $q) = (0, 1);
	my($a0, $a, $last);
	$last = 2 * ($a0 = $a = int(sqrt($dis)));

	for (;;)
	{
		$p = $a * $q - $p;
		$q = ($dis - $p**2)/$q;
		$a = int(($a0 + $p)/$q);
		push @repeat, $a;
		last if ($last == $a);
	}

	$self->{simple} = [$a0];
	$self->{repeat} = [@repeat];
	return bless($self, $class);
}

#
# $qs = Math::ContinuedFraction->from_quadratic($a, $b, $c);
#
sub from_quadratic
{
	my $self = shift;
	my(@coefficients) = @_;

	while (@coefficients)
	{
	}
}

#
# if ($cf->is_finite()) { ...
#
#
#
sub is_finite
{
	my $self = shift;
	return ($self->{repeat})? 1: 0;
}

#
# my($slength, $rlength) = $cf->sequence_length();
#
#
sub sequence_length
{
	my $self = shift;
	my $sl = scalar @{ $self->{simple} };
	my $rl = ($self->{repeat})? scalar @{ $self->{repeat} }: 0;

	return ($sl, $rl);
}

#
# $bigratio = $cf->brconvergent($nth);
#
# Exactly like the convergent() method, except returning a BigRat
# type instead of separate BigInt numerator and denominator.
#
sub brconvergent
{
	my $self = shift;
	my($terms) = @_;

	my($n, $d) = $self->convergent($terms);
	return Math::BigRat->new($n, $d);
}

#
# ($numerator, $denominator) = $cf->convergent($nth);
#
# Get the fraction for the continued fraction at the nth term.
#
sub convergent
{
	my $self = shift;
	my($terms) = @_;
	my($repetitions, $remainder) = (0, 0);
	my($sl, $rl) = $self->sequence_length();

	use integer;

	#
	### $terms
	### $sl
	### $rl
	#
	my $n = Math::BigInt->new(0);
	my $d = Math::BigInt->new(1);

	$terms = $sl + $rl unless ($terms);
	$terms = $sl if ($terms > $sl and $rl == 0);

	if ($terms >= $sl)
	{
		$repetitions = ($terms - $sl) / $rl;
		$remainder = ($terms - $sl) % $rl;

		#
		### $repetitions
		### $remainder
		#
		if ($remainder > 0)
		{
			my @remaining = (@{ $self->{repeat} }[0..$remainder]);
			($n, $d) = $self->evaluate(\@remaining, $n, $d);
		}

		for (1..$repetitions)
		{
			($n, $d) = $self->evaluate($self->{repeat}, $n, $d);
		}

		return reverse $self->evaluate($self->{simple}, $n, $d);
	}

	my @partial = @{ $self->{simple} }[0..$terms];
	return reverse $self->evaluate(\@partial, $n, $d);
}

sub evaluate
{
	my $self = shift;
	my($sequence, $n, $d) = @_;

	#
	### $sequence
	### $n
	### $d
	#
	# Add on the next group of continued fraction terms.
	#
	#  a0 + 1
	#       ------
	#       a1 + 1
	#            ------
	#            a2 + n
	#                 ---
	#                 d
	#
	foreach my $a_k (reverse @$sequence)
	{
		$n += $d * $a_k;
		($n, $d) = ($d, $n);	# Reciprocal
	}

	return ($n, $d);
}

#
# Get the array form of the continued fraction.
#
sub to_array
{
	my $self = shift;
	my $v = $self->{simple};
	push @{ $v }, $self->{repeat} if ($self->{repeat});

	return $v;
}

sub to_ascii
{
	my $self = shift;
	my $cf = '[' . join(", ", @{ $self->{simple} });
	$cf .= ', [' . join(", ", @{ $self->{repeat} }) . ']' if ($self->{repeat});
	return $cf .']';
}

#
# $class->_copy($self);
#
# Duplicate the continued fraction object.
#
sub _copy
{
	my($other, $self) = @_;

	#
	# Direct copy of all keys, except for our arrays, which
	# we'll do with a deeper copy.
	#
	foreach my $k (grep($_ !~ /simple|repeat/, keys %{$other}))
	{
		$self->{$k} = $other->{$k};
	}

	$self->{simple} = [ @$other->{simple} ];
	$self->{repeat} = ($other->{repeat})? [ @$other->{repeat} ]: undef;

	return $self;
}


=head1 NAME

Math::ContinuedFraction - Create and Manipulate Continued Fractions.

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Math::ContinuedFraction;

    #
    # Create new continued fraction objects.
    #
    my $cf = Math::ContinuedFraction->new([1, 4, 9, 25]);
    my $cf_phi = Math::ContinuedFraction->new([1, [1]]);
 
    my $cf_67div29 = Math::ContinuedFraction->from_ratio(67, 29);


=head1 DESCRIPTION

Continued fractions are expressions of the form

         b1
    a1 + -------
               b2
          a2 + -------
	             b3
	        a3 + -------
	                ...

For most instances, the 'b' terms are 1, and the continued fraction
can be written as C<[a1, a2, a3, ...]>, etc. If the sequence of 'a' terms ends
at a certain point, the continued fraction is known as a finite continued
fraction, and can be exactly represented as a fraction. If the sequence of
'a' terms has a repeating sequence, it is normally written as

                 ______
    [a1, a2, a3, a4, a5]

where the line over a4 and a5 indicates that they repeat forever. Since we
can't use that method in perl code, we indicate the repeating portion by using an
array within the array:

    [a1, a2, a3, [a4, a5]]

Note that in the examples in the L</SYNOPSIS>, C<$cf_phi> is created using
that notation.

=head2 Methods to Create Continued Fraction Objects

=head3 new()

Create a new continued fraction object from an array.

    my $cf = Math::ContinuedFraction([1, [2, 1]]);

Arrays are in the form C<[finite_sequence, [repeating_sequence]]>. A continued fraction
with no repeating part simply omits the embedded array reference:

    my $cf = Math::ContinuedFraction([1, 2, 1, 3, 1, 5]);

=head3 from_ratio()

Generate a continued fraction from a pair of relatively prime numbers.

=head2 Methods to Return Information

=head3 convergent()

Returns the fraction formed by calculating the rational approximation
of the continued fraction at a stopping point, and returning the
numerator and denominator.

Convergent term counts begin at 1. Continued fractions with a repeating
component can effectively have a term count as high as you like. Finite
continued fractions will stop at the end of the sequence without warning.

    #
    # Find the ratios that approximate pi.
    #
    # The array stops at seven elements for simplicity's sake,
    # the sequence actually does not end.
    #
    my $cfpi = Math::ContinuedFraction([3, 7, 15, 1, 292, 1, 1]);

    for my $j (1..4)
    {
        my($n, $d) = cfpi->convergent($j);
        print $n->bstr() . "/". $d->bstr() . "\n";
    }

The values returned are objects of type Math::BigInt.

=head3 brconvergent()

Behaves identically to convergent(), but returns a single Math::BigRat
object instead of two Math::BigInt objects.

    #
    # Find the ratios that approximate pi.
    #
    # The array stops at seven elements for simplicity's sake,
    # the sequence actually does not end.
    #
    my $cfpi = Math::ContinuedFraction([3, 7, 15, 1, 292, 1, 1]);

    for my $j (1..4)
    {
        my $r = cfpi->convergent($j);
        print $r->bstr() . "\n";
    }


=head3 to_array()

Returns an array reference that can be used to create a continued fraction (see L</new()>).

    my $cf = Math::ContinuedFraction->from_ratio(0xfff1, 0x7fed);
    my $aref = $cf->to_array()
    my $cf2 = Math::ContinuedFraction->new($aref);

=head3 to_ascii()

Returns the string form of the array reference.

    my $cf = Math::ContinuedFraction->from_ratio(0xfff1, 0x7fed);
    print $cf->to_ascii(), "\n";

Returns C<[2, 1432, 1, 6, 1, 2]>.

=head1 AUTHOR

John Gamble, C<< <jgamble at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Olds, C. D. I<Continued Fractions>. New York: Random House, 1963.

=head1 COPYRIGHT & LICENSE

Copyright 2011 John Gamble.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Math::ContinuedFraction
