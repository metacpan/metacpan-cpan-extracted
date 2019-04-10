package Math::ContinuedFraction;

use 5.010001;

use warnings;
use strict;
use Carp;
use Math::BigInt;
use Math::BigRat;
#use Smart::Comments;

use overload
	'+' => sub {return Continued::Fraction->add($_[0], $_[1]);},
	'-' => sub {return Continued::Fraction->subt($_[0], $_[1]);},
	'*' => sub {return Continued::Fraction->mult($_[0], $_[1]);},
	'/' => sub {return Continued::Fraction->div($_[0], $_[1]);},
	;

our $VERSION = '0.13';

=pod

=encoding UTF-8

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
can't use that method in perl code, we indicate the repeating portion by
using an array within the array:

    [a1, a2, a3, [a4, a5]]

Note that in the examples in the L</SYNOPSIS>, C<$cf_phi> is created using
that notation.

=head2 Methods to Create Continued Fraction Objects

=head3 new()

Create a new continued fraction object from an array or the
ratio of two numbers.

    my $cf = Math::ContinuedFraction([1, [2, 1]]);

Arrays are in the form C<[finite_sequence, [repeating_sequence]]>. A
continued fraction with no repeating part simply omits the embedded
array reference:

    $cf = Math::ContinuedFraction([1, 2, 1, 3, 1, 5]);
    $cf = Math::ContinuedFraction->new([1, 71, 13, 8]);
    $cf = Math::ContinuedFraction->new([1, 2, 1, 2, [3, 2, 3, 2]]);

A continued fraction may be created from a ratio between two numbers.
Be sure not to put the numbers in an array, as

    #
    # Find the CF form of 121/23.
    #
    $cf  = Math::ContinuedFraction->new(121, 23);

is different from

    #
    # Find the CF of
    #     121 + 1
    #          -----
    #           23
    #
    $cf  = Math::ContinuedFraction->new([121, 23]);


The ratio may consist of Math::BigInt objects.

    $big_n = Math::BigInt->new("0xccc43c90d2c0");
    $big_q = Math::BigInt->new("0xb2069d579ddb");
    $cf = Math::ContinuedFraction->new($big_n, $big_q);

A Math::BigRat object will also work:

    $bratio = Math::BigRat->new("0xccc43c90d2c0", "0xb2069d579ddb");
    $cf = Math::ContinuedFraction->new($bratio);

=cut

sub new
{
	my $class = shift;
	my $self = {};

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
	$self->{simple_a} = [0];
	$self->{repeat_a} = undef;
	$self->{simple_b} = undef;
	$self->{repeat_b} = undef;

	if (scalar @_)
	{
		#
		# Get the a's and b's.
		#
		my($a_ref, $b_ref) = @_;

		if (ref $a_ref eq "ARRAY")
		{
			my(@seq) = @$a_ref;

			#
			# See if there's a repeating component. If there is,
			# check for one of those "Why are you doing that"
			# empty array cases.
			#
			if (ref $seq[$#seq] eq "ARRAY")
			{
				my @r = @{ pop @seq };
				$self->{repeat_a} = [@r] if (scalar @r > 0);
			}

			#
			# Another empty array case check, this one slightly
			# legitimate.
			#
			$self->{simple_a} = (scalar @seq)? [@seq]: [0];

			#
			# Now check for a second ARRAY component, which
			# will act as a numerator in the written-out
			# version of the continued fraction.
			#
			if (defined $b_ref and ref $b_ref eq "ARRAY")
			{
				my(@seq) = @$b_ref;

				if (ref $seq[$#seq] eq "ARRAY")
				{
					my @r = @{ pop @seq };
					$self->{repeat_b} = [@r] if (scalar @r > 0);
				}
				$self->{simple_b} = (scalar @seq)? [@seq]: [0];
			}
		}
		elsif (ref $a_ref eq "Math::BigRat")
		{
			my($n, $d) = $a_ref->parts();

			#
			# Do from_ratio stuff.
			#
			$self->from_ratio($n, $d);
		}
		elsif (ref $a_ref eq "Math::BigInt" and
			ref $b_ref eq "Math::BigInt")
		{
			#
			# Do from_ratio stuff.
			#
			$self->from_ratio($a_ref, $b_ref);
		}
		elsif (ref $a_ref eq "Math::NumSeq")
		{
		}
		elsif (ref $a_ref eq '' and ref $b_ref eq '' and
			defined($a_ref) and defined($b_ref))
		{
			#
			# Do from_ratio stuff.
			#
			$self->from_ratio($a_ref, $b_ref);
		}
		else
		{
			#
			# Complain bitterly if we weren't passed an ARRAY,
			# BigRat or BigInt references, or just a pair of
			# numbers.
			#
			carp "Error." . __PACKAGE__ .
				"->new() takes either an array reference, " .
				"or a Math::BigRat object, " .
				"or a pair of Math::BigInt objects, " .
				"or another " .  __PACKAGE__ . " object";
			return undef;
		}
	}

	return $self;
}

=head3 from_ratio()

Generate a continued fraction from a pair of relatively prime numbers.


    my $cf67_29 = Math::ContinuedFraction->from_ratio(67, 29);

Create a continued fraction from a simple ratio.
These CFs will always be the simple types.

=cut

sub from_ratio
{
	my $class = shift;
	my($n, $d) = @_;
	my $self = {};
	my @cf;

	LOOP:
	for (;;)
	{
		my $q = int($n/$d);
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

	$self->{simple_a} = [@cf];
	$self->{repeat_a} = undef;
	return bless($self, $class);
}

#
# $qs = Math::ContinuedFraction->from_root($x);
#
sub from_root
{
	my $class = shift;
	my($dis) = @_;
	my $self = {};

	my($p, $q) = (0, 1);
	my($a0, $a, $last);
	$last = 2 * ($a0 = $a = int(sqrt($dis)));

	my @repeat;

	for (;;)
	{
		$p = $a * $q - $p;
		$q = ($dis - $p**2)/$q;
		$a = int(($a0 + $p)/$q);
		push @repeat, $a;
		last if ($last == $a);
	}

	$self->{simple_a} = [$a0];
	$self->{repeat_a} = [@repeat];
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
# "... every periodic simple continued fraction CF represents a
# quadratic irrational (c + f*sqrt(d))/b, where b,c,f,d are integers
# and d is squarefree."
#    OEIS, A246904
#
sub to_qirrational
{
}

#
# if ($cf->is_finite()) { ...
#
#
#
sub is_finite
{
	my $self = shift;
	return ($self->{repeat_a})? 1: 0;
}

#
# my($slength, $rlength) = $cf->sequence_length();
#
#
sub sequence_length
{
	my $self = shift;
	my $sl = scalar @{ $self->{simple_a} };
	my $rl = ($self->{repeat_a})? scalar @{ $self->{repeat_a} }: 0;

	return ($sl, $rl);
}

#
# Some OEIS sequences.
#
# e: A0031417
# pi: A001203
#
my $oeis_e = [
	2, 1, 2, 1, 1, 4, 1, 1, 6, 1, 1, 8, 1, 1, 10, 1,
	1, 12, 1, 1, 14, 1, 1, 16, 1, 1, 18, 1, 1, 20, 1, 1,
	22, 1, 1, 24, 1, 1, 26, 1, 1, 28, 1, 1, 30, 1, 1, 32,
	1, 1, 34, 1, 1, 36, 1, 1, 38, 1, 1, 40, 1, 1, 42, 1,
	1, 44, 1, 1, 46, 1, 1, 48, 1, 1, 50, 1, 1, 52, 1, 1,
	54, 1, 1, 56, 1, 1, 58, 1, 1, 60, 1, 1, 62, 1, 1, 64,
	1, 1, 66];

my $oeis_pi = [
	3, 7, 15, 1, 292, 1, 1, 1, 2, 1, 3, 1, 14, 2, 1, 1,
	2, 2, 2, 2, 1, 84, 2, 1, 1, 15, 3, 13, 1, 4, 2, 6,
	6, 99, 1, 2, 2, 6, 3, 5, 1, 1, 6, 8, 1, 7, 1, 2,
	3, 7, 1, 2, 1, 1, 12, 1, 1, 1, 3, 1, 1, 8, 1, 1,
	2, 1, 6, 1, 1, 5, 2, 2, 3, 1, 2, 4, 4, 16, 1, 161,
	45, 1, 22, 1, 2, 2, 1, 4, 1, 2, 24, 1, 2, 1, 3, 1,
	2, 1];

=head3 brconvergent()

Behaves identically to convergent(), but returns a single Math::BigRat
object instead of two Math::BigInt objects.

    #
    # Find the ratios that approximate pi.
    #
    # The array stops at seven elements for simplicity's sake,
    # the sequence actually does not end. See sequence A001203
    # at the Online Encyclopedia of Integer Sequences (http://www.oeis.org/)
    #
    my $cfpi = Math::ContinuedFraction([3, 7, 15, 1, 292, 1, 1]);

    for my $j (1..4)
    {
        my $r = cfpi->brconvergent($j);
        print $r->bstr() . "\n";
    }

=cut

sub brconvergent
{
	my $self = shift;
	my($terms) = @_;

	my($n, $d) = $self->convergent($terms);
	return Math::BigRat->new($n, $d);
}

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

    ($numerator, $denominator) = $cf->convergent($nth);

Get the fraction for the continued fraction at the nth term.

=cut

sub convergent
{
	my $self = shift;
	my($terms) = @_;
	my($repetitions, $remainder) = (0, 0);
	my($sl, $rl) = $self->sequence_length();

	#
	### $terms
	### $sl
	### $rl
	#
	my $n = Math::BigInt->new(0);
	my $d = Math::BigInt->new(1);

	$terms = $sl + $rl unless ($terms);
	$terms = $sl if ($terms > $sl and $rl == 0);

	if ($terms > $sl)
	{
		$repetitions = int(($terms - $sl) / $rl);
		$remainder = ($terms - $sl) % $rl;

		#
		### $repetitions
		### $remainder
		#
		if ($remainder > 0)
		{
			my @remaining = (@{ $self->{repeat_a} }[0..$remainder]);
			($n, $d) = $self->evaluate(\@remaining, $n, $d);
		}

		for (1..$repetitions)
		{
			($n, $d) = $self->evaluate($self->{repeat_a}, $n, $d);
		}

		return reverse $self->evaluate($self->{simple_a}, $n, $d);
	}

	my @partial = @{ $self->{simple_a} }[0..$terms];
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

=head3 to_array()

Returns an array reference that can be used to create a continued
fraction (see L</new()>).

    my $cf = Math::ContinuedFraction->from_ratio(0xfff1, 0x7fed);
    my $aref = $cf->to_array()
    my $cf2 = Math::ContinuedFraction->new($aref);

=cut

sub to_array
{
	my $self = shift;
	my $v = $self->{simple_a};
	push @{ $v }, $self->{repeat_a} if ($self->{repeat_a});

	return $v;
}

=head3 to_ascii()

Returns the string form of the array reference.

    my $cf = Math::ContinuedFraction->from_ratio(0xfff1, 0x7fed);
    print $cf->to_ascii(), "\n";

Returns C<[2, 1432, 1, 6, 1, 2]>.

=cut

sub to_ascii
{
	my $self = shift;
	my $cf = '[' . join(", ", @{ $self->{simple_a} });
	$cf .= ', [' . join(", ", @{ $self->{repeat_a} }) . ']' if ($self->{repeat_a});
	return $cf .']';
}

#
#
#
sub add
{
	my $self = shift;
}

sub subt
{
	my $self = shift;
}

sub mult
{
	my $self = shift;
}

sub div
{
	my $self = shift;
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

	$self->{simple_a} = [ @$other->{simple_a} ];
	$self->{repeat_a} = ($other->{repeat_a})? [ @$other->{repeat_a} ]: undef;

	return $self;
}

1;
__END__

=pod

=head1 ACKNOWLEDGEMENTS

Olds, C. D. I<Continued Fractions>. New York: Random House, 1963.

=head1 COPYRIGHT & LICENSE

Copyright 2011 John Gamble.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

John Gamble, C<< <jgamble at cpan.org> >>

=cut

