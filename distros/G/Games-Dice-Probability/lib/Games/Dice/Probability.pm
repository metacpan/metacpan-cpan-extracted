package Games::Dice::Probability;

use 5.006;

# Be a Good Module
use strict;
use warnings;
#use diagnostics;

# Our version number.
our $VERSION = '0.02';

# Required Modules
#     Math::Sumbolic::AuxFunctions is for the calcs of binomial coefficients.
#
#     Parse::RecDescent parses the dice expressions.
use Math::Symbolic::AuxFunctions;
use Parse::RecDescent;

# Optional Modules
#     Debug::ShowStuff is used by $self->debug() to descend and display hashes
#     in the object.
#
#     Memoize is used by $self->new() to speed up calculations on individual
#     nodes in the expression tree.  If there are duplicate nodes, the second
#     and all subsequent calc_distribution calls with the same parameters will
#     just return the cached values.
#
#     Thanks to Mark Mills for the optional-module code snippet, and general
#     ideas, tips, and tricks for the whole module.  He's my local Perl
#     Monk...you can email him thanks and offers of cookies at:
#     extremely{plus}pm{at}hostile{dot}org
BEGIN {
    # Is Debug::ShowStuff available?
    if ( eval q/ require Debug::ShowStuff / ) {
	# If so, import the routines.
	Debug::ShowStuff->import("showref");
    } else {
	# Not available.  Place stub in its place.
	eval q/ sub showref { print @_; print "\n"; } /;
    }

    # Is Memoize available?
    if ( eval q/ require Memoize / ) {
	# If so, import the routines.
	Memoize->import();
    } else {
	# Not available.  Place stub in its place.
	eval q/ sub memoize { return; } /;
    }
}

# Binomial Coefficient Shortcut
#     Non-polluted namespaces are cool and all, but sometimes it's too much to
#     type a 44 character long subroutine name multiple times in a simple
#     equation.  Sheesh.
my $binco = \&Math::Symbolic::AuxFunctions::binomial_coeff;

# Recursive Parsing Grammar
#     Parsing grammar and tree code outright stolen from Sam Holden's
#     DiceDistribution.pm at http://sam.holden.id.au/junk/DICEDISTRIBUTION/.
#     Added a divide expression for division calculations.  Changed the way
#     Fudge Dice are expressed to be #d[fF] which is more inline with how
#     they are represented elsewhere.  Added mid# dice expression as part
#     of dicenode.
my $DiceGrammar = <<'END_GRAMMAR';
expression:	add_sub end  { $item[1] }
add_sub:	mult_div '+' add_sub { { left => $item[1], op => '+', right => $item[3] } }
add_sub:	mult_div '-' add_sub { { left => $item[1], op => '-', right => $item[3] } }
add_sub:	mult_div
mult_div:	bracket '/' mult_div { { left => $item[1], op => '/', right => $item[3] } }
mult_div:	bracket '*' mult_div { { left => $item[1], op => '*', right => $item[3] } }
mult_div:	bracket
bracket:	'(' add_sub ')' { $item[2] }
bracket:	dicenode
dicenode:	/(\d+|mi)d(\d+|f)/i
dicenode:	/\d+/
end:		/\s*$/
END_GRAMMAR

# Dice Parsing Object
my $DiceParser = Parse::RecDescent->new($DiceGrammar) || die("bad grammar");

# import()
#     Faux import function that either memoizes the calc portions of the
#     module (default) or doesn't.
sub import {
    # Default is to memoize.  Saving cycles is a Good Thing.  However, if
    # someone passes an unmemoize argument, then we will respect their wishes.
    if ( ! grep(/(un|no)memo(ize)*/i,@_) ) {
	# Attempt to memoize the calculation subroutines.  This will either
	# truly memoize, or the stub memoize function will simply return having
	# done nothing.
	memoize('calc_distribution');
	# Not certain if calc_combination will benefit from Memoize.  Need to
	# test further.
	memoize('calc_combination');
    }

    # All is well.  Return.
    return;
}

# debug()
#    Print debugging information about object.
sub debug {
    # The object of our attention.
    my $self = shift;

    # For every piece of the object...
    foreach my $key ( sort(keys(%$self)) ) {
	# Output the name...
	print "self->{$key}=";
	# And if it is a reference...
	if ( ref($self->{$key}) ) {
	    # Print the contents of the reference...
	    print "\n";
	    showref($self->{$key});
	} else {
	    # Or, print the value.
	    print $self->{$key} . "\n";
	}
    }

    # All is well.
    return(0);
}

# new(expression)
#     Creates a new object based on the provided dice expression.
sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = {};

    die("must provide dice expression") unless (@_);

    if (@_ != 1) {
	die("new() called with too many arguments");
    } else {
	$self->{EXPRESSION} = $DiceParser->expression(@_) || die "could not parse expression";
	$self->{DISTRIBUTION} = travel($self->{EXPRESSION}) || die "could not travel parsed expression";
    }

    return(bless($self, $class));
}

# travel(expression)
#     Travel the parsed expression, returning hash of value => permutations.
sub travel {
    my $node = shift || die "invalid or missing expression node";

    if ( ref($node) ) {
	for ($node->{op}) {
	    /(\+)/ && return( calc_combination($1, travel($node->{left}), travel($node->{right})) );
	    /(\-)/ && return( calc_combination($1, travel($node->{left}), travel($node->{right})) );
	    /(\*)/ && return( calc_combination($1, travel($node->{left}), travel($node->{right})) );
	    /(\/)/ && return( calc_combination($1, travel($node->{left}), travel($node->{right})) );
	}
    }

    for ($node) {
	/^(\d+)(d)(\d+|f)/i && return( calc_distribution($2,$1,$3) );
	/^(mi)(d)(\d+|f)/i && return( calc_distribution("m",3,$3) );
	/^\d+$/ && return( {$node => 1} );
    }

    die("invalid token in expression.");
}

# calc_distribution(method,numdice,numsides)
#     Calculate distribution of values/permutations given: method, number of
#     dice, and number of sides per die.
sub calc_distribution {
    # The dice method requested.
    my $method = shift;
    # The number of dice.
    my $n = shift; $n += 0;
    # The number of sides/faces on each die.
    #     f/F = Fudge dice = d3.
    my $s = shift; $s += 0 unless $s =~ /f/i;
    # Loop value based on total/face.
    my $t1;
    # Hash to return containing the distribution.
    my %dist;

    # If dice node method is simple-sum nDs or nDf...
    if ( $method =~ /d/i ) {
	if ( $s =~ /f/i ) {
	    # If dice node method is fudge nDf...

	    # First, get the distribution for nDs...
	    my $tempdist = calc_distribution("d",$n,3);
	    # Then loop to build the new distribution from (-n..0)...
	    my $origkey = $n;
	    for ($t1=-1 * $n; $t1 <= 0; $t1++) {
		# Changing the original values in (n..ns) to (-n..n),
		# copy the original distribution to the new one with
		# the correct values...
		$dist{$t1} = $$tempdist{$origkey};
		$dist{$t1*-1} = $$tempdist{$origkey};
		$origkey++;
	    }
	} elsif ( $n eq 1 ) {
	    # Save compute cycles if only one die...

	    # Each face has a single chance...
	    for ($t1=1; $t1 <= $s; $t1++) {
		$dist{$t1} = 1;
	    }
	} else {
	    # Else compute number of combinations for a total on the face of n
	    # dice.

	    # Minimum and maximum sums.
	    my $tmin = $n;
	    my $tmax = $n*$s;
	    # Peak sum is the sum around which the bell-curve mirrors, saving
	    # compute time.
	    my $tpeak = ($tmin+$tmax)/2;

	    # For each total (t1) in $tmin..$tmax, calculate the number of
	    # combinations giving that total.
	    for ($t1=$tmin; $t1 <= $tpeak; $t1++) {
		# Total (t2) that is the mirror point in the bell curve.
		my $t2 = $tmin + $tmax - $t1;
		# Ceiling for the sum function.
		my $ceil = int( ($t1-$n) / $s );
		# Result.
		my $res = 0;
		# Loop control for the sum funtion.
		my $k;

		# Sum Function: For each k in 0 to $ceil...
		for ($k=0; $k <= $ceil; $k++) {
		    # Calculate and add to previous results.
		    $res += ((-1)**$k) * &$binco($n,$k) * &$binco(($t1-($s*$k)-1),($n-1));
		}

		# Set the mirrored points of the distribution.
		#     Note: $t1 and $t2 can be equal once at 
		#     $t1=$tpeak when s is even.
		$dist{$t1} = $res;
		$dist{$t2} = $res;
	    }
	}
    } elsif ( $method =~ /m/i ) {
	# If dice method is take-the-middle-value nMs...

	# Minimum and maximum values.
	my $tmin = 1;
	my $tmax = $s;

	# For each value (t1) in $tmin..$tmax, calculate the number of
	# combinations giving t1 as the middle face value.
	for ($t1=$tmin; $t1 <= $tmax; $t1++) {
	    $dist{$t1} = 1 + ( 3 * ($s - 1) ) + ( 6 * ($t1 - 1) * ($s - $t1) );
	}
    }

    # Return the value=>combinations distribution hash for this node.
    return({%dist});
}

# calc_combination(operand,distribution1,distribution2)
#     Combine two distributions with the method provided.
sub calc_combination {
    # Calculation to perform on values.
    my $op = shift;
    # Distributions to combine.
    my $dist1 = shift;
    my $dist2 = shift;
    # The combined distribution.
    my %cdist;

    # For each value in the first distribution...
    foreach my $val1 ( sort {$a+0 <=> $b+0} keys(%$dist1) ) {
	# Combine it with every value in the second distribution...
	foreach my $val2 ( sort {$a+0 <=> $b+0} keys(%$dist2) ) {
	    # The new value of which is calculated based on combine method...
	    my $newval;
	    for ($op) {
		/\+/ && do { $newval = $val1 + $val2 };
		/\-/ && do { $newval = $val1 - $val2 };
		/\*/ && do { $newval = $val1 * $val2 };
		/\// && do { $newval = int($val1 / $val2) };
	    }
	    # Calculate the new combined combinations and set it to the new
	    # value in the new distribution.
	    $cdist{$newval} += $$dist1{$val1} * $$dist2{$val2};
	}
    }

    # Return the combined distribution.
    return({%cdist});
}

# combinations(targetvalue)
#     Calculate number of combinations for a target value.
sub combinations {
    my $self = shift;
    my $targetvalue = shift;

    $targetvalue = "ALL" unless defined($targetvalue);

    if ( ref($self) ) {
	if (@_ != 0) {
	    die("combinations() called incorrectly");
	} else {
	    if ( $targetvalue eq "ALL" ) {
		if ( $self->{COMBINATIONS} ) {
		    return ( $self->{COMBINATIONS} );
		} else {
		    foreach my $value ( values(%{$self->{DISTRIBUTION}}) ) {
			$self->{COMBINATIONS} += $value;
		    }
		    return($self->{COMBINATIONS});
		}
	    } else {
		return( $self->{DISTRIBUTION}->{$targetvalue} );
	    }
	}
    } else {
	die("combinations() called on non-object");
    }
}

# distribution()
#     Returns a hash containing the distribution in value=>combinations format.
sub distribution {
    my $self = shift;

    if ( ref($self) ) {
	if (@_ != 0) {
	    die("distribution() called with argument on object");
	} else {
	    return( $self->{DISTRIBUTION} );
	}
    } else {
	if (@_ != 0) {
	    my $expression = $DiceParser->expression(@_) || die "could not parse expression";
	    return( travel($expression) );
	} else {
	    die("no expression provided for non-object distribution() call");
	}
    }
}

# probability(targetvalue)
#     Returns the probability for targetvalue, or a hash of probabilities in 
#     value=>probability format.
sub probability {
    my $self = shift;
    my $targetvalue = shift;

    $targetvalue = "ALL" unless defined($targetvalue);

    if ( ref($self) ) {
	if (@_ != 0) {
	    die("probability() called incorrectly");
	} else {
	    if ( ! exists($self->{PROBABILITIES}) ) {
		my $combs = $self->combinations();
		my %probs;
		foreach my $value ( keys(%{$self->{DISTRIBUTION}}) ) {
		    $probs{$value} = $self->{DISTRIBUTION}->{$value} / $combs;
		}
		$self->{PROBABILITIES} = {%probs};
	    }
	    if ( $targetvalue eq "ALL" ) {
		return( $self->{PROBABILITIES} );
	    } else {
		return( $self->{PROBABILITIES}->{$targetvalue} || undef );
	    }
	}
    } else {
	die("probability() called on non-object");
    }
}

# bounds()
#     Returns the min and max values of the valueset.
sub bounds {
    my $self = shift;

    if ( ref($self) ) {
	if (@_ != 0) {
	    die("bounds() called with argument on object");
	} else {
	    return( [ $self->min(), $self->max() ] );
	}
    } else {
	die("bounds() called on non-object");
    }
}

# max()
#     Returns the max value of the valueset.
sub max {
    my $self = shift;

    if ( ref($self) ) {
	if (@_ != 0) {
	    die("max() called with argument on object");
	} else {
	    if ( $self->{MAX} ) {
		return( $self->{MAX} );
	    } else {
		my @values = sort {$b+0 <=> $a+0} keys(%{$self->{DISTRIBUTION}});
		$self->{MAX} = shift(@values);
		return( $self->{MAX} );
	    }
	}
    } else {
	die("max() called on non-object");
    }
}

# min()
#     Returns the min value of the valueset.
sub min {
    my $self = shift;

    if ( ref($self) ) {
	if (@_ != 0) {
	    die("min() called with argument on object");
	} else {
	    if ( $self->{MIN} ) {
		return( $self->{MIN} );
	    } else {
		my @values = sort {$a+0 <=> $b+0} keys(%{$self->{DISTRIBUTION}});
		$self->{MIN} = shift(@values);
		return( $self->{MIN} );
	    }
	}
    } else {
	die("min() called on non-object");
    }
}

1;

__END__

=head1 NAME

Games::Dice::Probability - Perl extension for calculating dice probabilities and distributions.

=head1 SYNOPSIS

    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("3d6");

    ($minval, $maxval) = $diceobj->bounds();
    $minval = $diceobj->min();
    $maxval = $diceobj->max();
    $tvcombs = $diceobj->combinations($targetvalue);
    $totalcombs = $diceobj->combinations();
    $prob = $diceobj->probability();
    $tvprob = $diceobj->probability($targetvalue);
    $dist = $diceobj->distribution();

    # table of value - combinations / total combinations
    foreach $value ($minval..$maxval) {
        print $value . " - " . $$dist{$value} . " / " . $$prob{$value} . "\n";
    }

=head1 DESCRIPTION

Games::Dice::Probability calculates probabilities and distributions for complex
dice expressions.  The expression provided when creating a new object is
parsed, and each node's combinations distribution is computed and then combined
appropriately to create the combinations distribution for the full expression.

Dice expressions are in the form of nDs or MIDs, where n is the number of dice 
and s is the number of faces on each die.  D is the simple-sum dice method, the
one most commonly used, where n dice of s faces each are rolled and a sum is
taken of the outcomes.  MID is the middle-value dice method, where three dice
are rolled, and the value in the middle is taken as the result.

For example, a single six-sided die is notated as:

    1d6

Two such dice would be:

    2d6

Middle dice would be:

    mid6

or:

    mid20

And so on.  Complex dice expressions can include modifiers (addition, 
subtraction, multiplication, division), and order of precedence brackets, such as:

    (2d6+4) + 2d6

or:

    (3d6/2) * 2d4

or:

    mid20 + (mid6+1)

When the object is created, the full distribution is calculated using as many
shortcuts and optimizations as possible.  These include reducing logic based on
certain values of n, only calculating half of any standard distribution, and
using an identity to create the other "mirrored" half of the distribution.
Also, large-number math is reduced by using formulae that reduce the
calculations to much smaller numbers, including the very efficient binomial
coefficient method in Math::Symbolic::AuxFunctions.  Lastly, each node's
distribution calculation and multi-node combined distribution calculation can
be Memoized, negating nearly all compute cycles for future identical
calculations.  All of these combined create a very sleek and fast method of
calculating dice distributions.

Memoization for calculations can be disabled at the time you declare use of
this module by passing an argument:

    use Games::Dice::Probability q/ nomemoize /;

The argument is recognized by 'no' or 'un' prefixed to 'memo' or 'memoize.'
Memoization is strongly encouraged when using this module for multiple
calculations or long-term scripts; the savings in compute cycles are vast.

Future support for BigInt is being considered, to allow for even larger values
in the complex dice expressions.

=head1 EXPORT

None.  This is intentional.  In fact, there is a faux import() call used
to optionally turn Memoize off, so exporting anything will not be successful.

=head1 SEE ALSO

Requires Math::Symbolic::AuxFunctions for the use of binomial_coeff().

Requires Parse::RecDescent to parse dice expressions.

Optionally uses Debug::ShowStuff to descend and display hashes in the object.

Optionally uses Memoize to speed up calculations of identical nodes in a dice
expression tree.  Use of memoization, though automatic, can be disabled when
using this module.

Up to date information on this module can be obtained from its webpage:

    http://oddgeek.info/code/gdp/

=head1 AUTHOR

Jason A. Dour, E<lt>jad@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Jason A. Dour

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
