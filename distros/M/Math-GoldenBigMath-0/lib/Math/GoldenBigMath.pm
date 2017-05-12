# perl 5
#
# GoldenBigMath.pm
#
# calc + - * / % with unbounded integers/decimals
#
# + - * / % == != > < <=> implemented
#
# handling of exponents ([eE][+-]?123456789) and decimal point "[,.]" still missing
#
# Ralf Peine, Mon Aug 18 17:01:06 2014

$VERSION = "0.804";

use strict;
use warnings;

$|=1;

package Math::GoldenBigMath; # shorthand: GBM

use Carp;

use vars qw($version $_MAX_DIV_DIGITS $_COEFF_MAX_DIGITS);

# stop calculation of division if digit count >= $_maxDivDigits
$_MAX_DIV_DIGITS = 100000;
# $_MAX_DIV_DIGITS = 100;
$_COEFF_MAX_DIGITS = 1000000;

# --- overloads ------------------- sub ----------------------------------------

# define usual mathematic operators
use overload
    '+'   => \&Addition,		# sub 
    '-'   => \&Subtraction,		# sub 
    '*'   => \&Multiplication,		# sub 
    '/'   => \&Division,		# sub 
    '%'   => \&DivisionModulus,		# sub 
    '=='  => \&CompareEqual,		# sub 
    '!='  => \&CompareNotEqual,		# sub 
    '>'   => \&Greater,			# sub 
    '<'   => \&Smaller,			# sub 
    '>='  => \&GreaterEqual,		# sub 
    '<='  => \&SmallerEqual,		# sub 
    '<=>' => \&Compare,			# sub 
    '""'  => \&GetValue;		# sub 

# --- creating, getting and setting sub (s) ------------------------------------

sub new {
    my $self = shift;

    my $type = ref($self)  ||  $self;
    my $number = shift;
    $number = "0" unless $number;
    my $elem = bless {}, $type; 
    $elem->SetValue($number); 
    return $elem;
}

# --- set coefficient (value before 'e') ------------------------
sub _setCoeff {
    my $self  = shift;
    $self->{_coeff} = shift;
    return $self;
}

# --- get coefficient (value before 'e') ------------------------
sub _getCoeff {
    my $self  = shift;
    return $self->{_coeff};
}

# --- set exponent (value after 'e') ------------------------
sub _setExp {
    my $self = shift;
    $self->{_exp} = shift;
    return $self;
}

# --- get exponent (value after 'e') ------------------------
sub _getExp {
    my $self = shift;
    return $self->{_exp};
}

# --- get char for sign ('+', '-' for +1, -1)
sub _getSignChar {
    my $sign = shift;

    return '+' if $sign == 1;
    return '-' if $sign == -1;

    croak "wrong sign given: $sign";
}

# --- Get whole value ---
sub GetValue {
    my $self  = shift;

    my $coeff_sign = _getSignChar($self->_getCoeffSign());
    my $exp_sign   = _getSignChar($self->_getExpSign());

    return $coeff_sign.$self->_getCoeff().'e'.$self->GetExpValue();
}

# --- Get exponent value ---
sub GetExpValue {
    my $self  = shift;

    my $exp_sign   = _getSignChar($self->_getExpSign());

    return $exp_sign.$self->_getExp();
}

# --- Set sign of coeff ---
sub _setCoeffSign {
    my $self = shift;
    $self->{_coeff_sign} = shift;
    return $self;
}

# --- Get sign of coeff ---
sub _getCoeffSign {
    my $self = shift;
    return $self->{_coeff_sign};
}

# --- Set sign of exp ---
sub _setExpSign {
    my $self = shift;
    $self->{_exp_sign} = shift;
    return $self;
}

# --- Get sign of exponent ---
sub _getExpSign {
    my $self = shift;
    return $self->{_exp_sign};
}

# --- extract Sign out of $number_ref ---
sub _extractSign {
    my $number = shift;

    my $sign  = 1;

    my $signStr = substr($number,0,1);
    if ($signStr eq '-') {
	$number = substr($number, 1);
	$sign = -1;
    }
    elsif ($signStr eq '+') {
	$number = substr($number, 1);
	$sign = 1;
    }

    $sign = 1 unless $number;

    return ($sign, $number);
}

# --- split ExponentValue into sign and value and set ---
sub SetExpValue {
    my $self     = shift;
    my $expValue = shift;

    my ($expSign, $exp) = _extractSign($expValue);

    return $self
	->_setExp($exp)
	->_setExpSign($expSign);
}

# --- Parse and set value ---
sub SetValue {
    my $self  = shift;
    my $number = lc(shift);

    # --- Split up into coeffStr, expStr and frac ---
    my $coeffStr;
    my $expStr;
    my $frac;

    #                   1.e1
    #                 +13.0e+2
    #                -123.010e-3
    if ($number =~ /^([\+\-]?\d+)(\.\d*)e([\+\-]?\d+)$/) {
	$coeffStr = $1;
	$frac = $2;
	$expStr = $3;
    }
    #                       1e1
    #                     +12e+2
    #                    -123e-3
    elsif ($number =~ /^([\+\-]?\d+)e([\+\-]?\d+)$/) {
	$coeffStr = $1;
	$frac = '.';
	$expStr = $2;
    }
    #                       1.
    #                     +12.01
    #                    -123.120
    elsif ($number =~ /^([\+\-]?\d+)(\.\d*)$/) {
	$coeffStr = $1;
	$frac = $2;
	$expStr = '0';
    }
    #                       1
    #                     +12
    #                    -123
    elsif ($number =~ /^([\+\-]?\d+)$/) {
	$coeffStr = $1;
	$frac = '.';
	$expStr = '0';
    }
    else {
	croak "wrong number format: '$number'";
    }

    # --- extract signs ---

    my ($exp_sign, $exp)     = _extractSign($expStr);

    # --- remove not needed '0's ---

    $frac .= '0';
    $frac  =  substr($frac, 1); # throw away '.' in first char
    $frac  =~ s/0+$//o;         # throw away 0 at end
    
    $exp   =  0 unless $exp;   # in case exp not set

    # --- move decimal point '.' off to right to get empty fractional part ---

    my $exp_value = $exp;
    $exp_value = '-' . $exp
	if $exp_sign < 0;

    # TODO: replace standard '-' operator by subtraction of GBM, when available
    # --- move '.' ---
    $exp_value       -=  length($frac);     
    
    ($exp_sign, $exp) = _extractSign($exp_value);

    $coeffStr .= $frac;

    my ($coeff_sign, $coeff) = _extractSign($coeffStr);

    # --- store values in instance ---

    $self->_setCoeff($coeff);
    $self->_setExp($exp);
    $self->_setCoeffSign($coeff_sign);
    $self->_setExpSign($exp_sign);

    return $self->Simplify();
}

# --- Simplify: Remove 0 at front and ascend exponent for every 0 removed at end ---
sub Simplify {
    my $self  = shift;
    my $coeff = $self->_getCoeff();

    if ($coeff =~ /(\d)(0+)$/) {
	$coeff = $`.$1;
	my $expAdd = length($2);

	$self->SetExpValue($self->_getExpSign() * $self->_getExp() + $expAdd);
    }

    $coeff =~ s/^0+//o;           # throw away 0 from beginning
    $coeff = '0' if $coeff eq ''; # coeff was 0 
    
    if ($coeff eq '0') {
	$self->_setExp(0);
	$self->_setCoeffSign(1);
	$self->_setExpSign(1);
    }

    return $self->_setCoeff($coeff);
}

# --- move decimal point to the right until exponent is 0 ----
sub DispenseExponent {
    my $self  = shift;

    return $self if $self->_getExpSign() < 0;
    my $exp = $self->_getExp();

    croak __PACKAGE__.'::'.(caller(0))[3].'(): '.
	"Cannot deal numbers with more than $_COEFF_MAX_DIGITS"
	if $exp > $_COEFF_MAX_DIGITS;

    return $self if $exp eq '0';
    return $self->MoveDecimalPointToRight($exp);
}

# --- MoveDecimalPointToRight for bigger exponent until exponents are equal ---
sub AdoptExponents {
    my $gbm1    = shift; # GoldenBigMath 1
    my $gbm2    = shift; # GoldenBigMath 2
    
    # print $gbm1->GetValue()."\n";
    # print $gbm2->GetValue()."\n\n";

    my $exp1 = $gbm1->GetExpValue();
    my $exp2 = $gbm2->GetExpValue();

    my $expDiff = 0;
    if ($exp1 > $exp2) {
	$expDiff = $exp1 - $exp2;
	$gbm1->MoveDecimalPointToRight($expDiff);

	# print "expDiff $expDiff\n";
	# print $gbm1->GetValue()."\n";
	# print $gbm2->GetValue()."\n\n";

	return $gbm1;
    }
    elsif ($exp1 < $exp2) {
	$expDiff = $exp2 - $exp1;
	$gbm2->MoveDecimalPointToRight($expDiff);
	
	# print "expDiff $expDiff\n";
	# print $gbm1->GetValue()."\n";
	# print $gbm2->GetValue()."\n\n";

	return $gbm2;
    }

    # print $gbm1->GetValue()."\n";
    # print $gbm2->GetValue()."\n\n";

    return $gbm1;
}

# --- move decimal point to the right and reduce exponent ----
sub MoveDecimalPointToRight {
    my $self  = shift;
    my $moves = shift;     # number of '0' digits to add at right end

    croak __PACKAGE__.'::'.(caller(0))[3].'(): '.
	"Wrong number format for moving decimal point, should be [1-9][0-9]*, "
	."but was '$moves'"
	unless $moves =~ /^[1-9][0-9]*$/;

    croak __PACKAGE__.'::'.(caller(0))[3].'(): '.
	"Cannot deal numbers with more than $_COEFF_MAX_DIGITS"
	if $moves > $_COEFF_MAX_DIGITS;

    return $self 
	if $moves <= 0 or $moves + length($self->_getCoeff()) > $_COEFF_MAX_DIGITS;

    # TODO: replace standard '-' operator by subtraction of GBM, when available
    $self->SetExpValue($self->GetExpValue() - $moves);
    $self->{_coeff} .= '0' x $moves;

    return $self;
}

#=== Calculation sub (s) =======================================================

# --- comparison sub (s) -------------------------------------------------------

sub CompareEqual {
    my $gbm1 = shift;
    my $gbm2 = shift;

    $gbm1->Simplify();
    $gbm2->Simplify();
    return $gbm1->GetValue() eq $gbm2->GetValue() ? 1: 0;
}

sub CompareNotEqual {
    my $gbm1 = shift;
    my $gbm2 = shift;

    $gbm1->Simplify();
    $gbm2->Simplify();
    return $gbm1->GetValue() ne $gbm2->GetValue() ? 1: 0;
}

sub Greater {
    my $gbm1 = shift;
    my $gbm2  = shift;

    my $result = ($gbm1 <=> $gbm2) > 0 ? 1 : 0;
    return $result;
}

sub Smaller {
    my $gbm1 = shift;
    my $gbm2  = shift;
    my $result = ($gbm1 <=> $gbm2) < 0 ? 1 : 0;
    return $result;
}

sub GreaterEqual {
    my $gbm1 = shift;
    my $gbm2  = shift;

    my $result = ($gbm1 <=> $gbm2) >= 0 ? 1 : 0;
    return $result;
}

sub SmallerEqual {
    my $gbm1 = shift;
    my $gbm2  = shift;
    my $result = ($gbm1 <=> $gbm2) <= 0 ? 1 : 0;
    return $result;
}

# --- start Addition, handle exponents and sign ----
sub Addition {
    my $gbm1  = shift;
    my $gbm2  = shift;
    
    return new Math::GoldenBigMath($gbm1)->Addition($gbm2) unless ref $gbm1;
    return $gbm1->Addition(new Math::GoldenBigMath($gbm2)) unless ref $gbm2;

    AdoptExponents($gbm1, $gbm2);

    my $resultString;

    my $sign1 = $gbm1->_getCoeffSign();
    my $sign2 = $gbm2->_getCoeffSign();

    my $z1 = $gbm1->_getCoeff();
    my $z2 = $gbm2->_getCoeff();

    if ($sign1 == $sign2) {
	$resultString = AdditionWithoutSignPointAndExponent($z1, $z2);
    }
    else {
	my $result = $sign1 > 0
	    ? Subtraction($z1, $z2)
	    : Subtraction($z2, $z1);

	$result->DispenseExponent();
	croak "something went wrong, exponent was not dispensed" if $result->_getExp() ne '0';

	$resultString = $result->_getCoeff();
	$sign1        = $result->_getCoeffSign();
    }

    my $signChar = _getSignChar($sign1);
    my $exponent = _getSignChar($gbm1->_getExpSign()) . $gbm1->_getExp();

    return $gbm1->new("$signChar${resultString}e$exponent");
}

# --- start Subtraction, handle exponents and sign ----
sub Subtraction {
    my $gbm1    = shift;
    my $gbm2 = shift;
    
    return new Math::GoldenBigMath($gbm1)->Subtraction($gbm2) unless ref $gbm1;
    return $gbm1->Subtraction(new Math::GoldenBigMath($gbm2)) unless ref $gbm2;

    AdoptExponents($gbm1, $gbm2);
    
    my $resultString;

    my $sign1 = $gbm1->_getCoeffSign();
    my $sign2 = $gbm2->_getCoeffSign();

    my $z = $gbm1->_getCoeff();
    my $subtr = $gbm2->_getCoeff();

    if ($sign1 == $sign2) {
	my $swap = Compare ($z, $subtr) < 0 ? 1: 0;
    
	if ($swap) { # Second is greater, so swap args and set $sign1 = -$sign1
	    $resultString = SubtractionWithoutSignPointAndExponentAndFirstGreater($subtr, $z);
	    $sign1 = $sign1 < 0 ? 1: -1;
	    # print "# swap\n";
	}
	else {
	    $resultString = SubtractionWithoutSignPointAndExponentAndFirstGreater($z, $subtr);
	}
    }
    else {
	$resultString = AdditionWithoutSignPointAndExponent($z, $subtr);
    }

    # print "# sign $sign1\n";

    my $signChar = _getSignChar($sign1);
    my $exponent = _getSignChar($gbm1->_getExpSign()) . $gbm1->_getExp();

    return $gbm1->new("$signChar${resultString}e$exponent");
}

# --- start multiplication, handle exponents and sign ---------------------
sub Multiplication {
    my $gbm1 = shift;
    my $gbm2 = shift;

    return new Math::GoldenBigMath($gbm1)->Multiplication($gbm2) unless ref $gbm1;
    return $gbm1->Multiplication(new Math::GoldenBigMath($gbm2)) unless ref $gbm2;

    my $coeff1 = $gbm1->_getCoeff();
    my $coeff2 = $gbm2->_getCoeff();

    return $gbm1->new(0)
	if $coeff1 == 0 or $coeff2 == 0;
    
    my $resultString = MultiplicationWithoutSignPointAndExponent
	($coeff1, $coeff2);

    my $signChar = $gbm1->_getCoeffSign() eq $gbm2->_getCoeffSign()
	? '+' : '-';

    my $exp1 = _getSignChar($gbm1->_getExpSign()) . $gbm1->_getExp();
    my $exp2 = _getSignChar($gbm2->_getExpSign()) . $gbm2->_getExp();

    # TODO: replace standard '+' operator by addition of GBM
    my $exponent = $exp1 + $exp2;

    # Add call of Simplify()
    return $gbm1->new("$signChar${resultString}e$exponent");
}

# --- Do Compare ----------------------------------------------------------
sub Compare {
    my $gbm1 = shift;
    my $gbm2 = shift;

    return new Math::GoldenBigMath($gbm1)->Compare($gbm2) unless ref $gbm1;
    return $gbm1->Compare(new Math::GoldenBigMath($gbm2)) unless ref $gbm2;

    my $sign = $gbm1->_getCoeffSign();
    my $sign2 = $gbm2->_getCoeffSign();

    if ($sign ne $sign2) {
	return $sign cmp $sign2;
    }

    AdoptExponents($gbm1, $gbm2);

    my $coeff1 = $gbm1->_getCoeff();
    my $coeff2 = $gbm2->_getCoeff();

    my $l1 = length($coeff1);
    my $l2 = length($coeff2);

    my $coeffCmp = "";
    if ($l1 == $l2) {
	$coeffCmp = $coeff1 cmp $coeff2;
    }
    else {
	$coeffCmp = $l1 > $l2 ? 1:-1;
    }

    return $sign > 0 ? $coeffCmp: -$coeffCmp;
}

# --- create multiplication table for fast multiplication and division ---
# internal, but should be tested
sub buildMultiplicationTableAsString {
    my $z = shift; # coeff without sign as string

    croak "not a number string " unless $z =~ /^\d+$/;

    my @mulTab;
    $mulTab[9] = 0;
    $mulTab[0] = 0;
    $mulTab[1] = $z;
    foreach my $i (2..9) {
	$mulTab[$i] = AdditionWithoutSignPointAndExponent($mulTab[$i-1], $z);
    }

    return \@mulTab;
}

#=== Worker subs with real calculation ====================================

# FB-SCHR+ =====================================================================
# Addition without exponent, decimal point and sign
# Returns string containing [0-9]+
sub AdditionWithoutSignPointAndExponent {
    my $z1 = shift;   # Number as string
    my $z2 = shift;   # Number as string

    my $i1 = length($z1) - 1;
    my $i2 = length($z2) - 1;
    my $maxIdx = $i1 > $i2 ? $i1: $i2;

    # print "# maxIdx $maxIdx\n";
    
    # result variables
    my $result = '';  # result as string

    # index variables
    my $i;     # running index in GoldenBigMath
    my $s;     # sum of two digits
    my $u = 0; # store carry (u for german uebertrag)
    my $d1;    # one digit
    my $d2;    # one digit

    # --- now calculate sum by schriftliche addition ---------------------------
    for ($i = $maxIdx; $i >= 0; $i--) {
	$d1 = 0;
	$d2 = 0;

	$d1 = substr($z1, $i1, 1) if $i1 >= 0;
	$d2 = substr($z2, $i2, 1) if $i2 >= 0;

	$s = $d1 + $d2 + $u;
	# print "# $s = $d1 + $d2\n";
	if ($s > 9) {
	    $u  = 1;  # don't use slow divide or modulo
	    $s -= 10; # don't use slow divide or modulo
	}
	else {
	    $u = 0;
	}
	# print "# $u$s = $d1 + $d2\n";
	$result .= $s;   # much faster than $result = $s . $result

	$i1--;
	$i2--;
    }

    $result .= $u if $u;

    # --- reverse strings to get the highest number at first position
    $result = reverse $result;

    # replace starting zeroes
    $result =~ s/^0+//go;
    $result = 0 unless $result;

    return $result;
}

# FB-SCHR- =====================================================================
# Subtraction without exponent, decimal point and sign
#             and first number is greater than second
sub SubtractionWithoutSignPointAndExponentAndFirstGreater {
    my $z1 = shift;   # Number as string
    my $z2 = shift;   # Number as string

    my $maxIdx = length($z1) - 1;
    my $addZeroCount = $maxIdx - length($z2) + 1;

    croak "second longer than first" if $addZeroCount < 0;

    # Add zeros in front of second to get both strings same length
    $z2 = '0' x $addZeroCount . $z2 if $addZeroCount > 0;

    # print "\n $z1\n-$z2\n\n";

    # result variables
    my $result = '';  # result as string
    my $resultObj;    # result as object

    # index variables
    my $i;     # running index in GoldenBigMath
    my $d;     # difference of two digits
    my $u = 0; # store carry (u for german uebertrag)

    # --- now calculate difference by schriftliche subtraction -----------------
    for ($i = $maxIdx; $i >= 0; $i--) {
	$d = substr($z1, $i, 1) - substr($z2, $i, 1) - $u;
	if ($d < 0) {
	    $u  = 1;  # don't use slow divide or modulo
	    $d += 10; # don't use slow divide or modulo
	}
	else {
	    $u = 0;
	}
	$result .= $d;   # much faster than $result = $d . $result
    }

    # --- reverse strings to get the highest number at first position
    $result = reverse $result;

    # replace starting zeroes by ' '
    $result =~ s/^0+//go;
    $result = 0 unless $result;

    return $result;
}

# FB-SCHR* =====================================================================
# Multiplication without exponent, decimal point and sign
sub MultiplicationWithoutSignPointAndExponent {
    my $z1 = shift;   # Number as string
    my $z2 = shift;   # Number as string

    my $mulTabRef = buildMultiplicationTableAsString($z2);

    # result variables
    my $result    = '';

    # help variables
    my $c = 1;   # dot counter

    # intermediate multiplication values
    my $d;              # next digit
    my $addZeros = '';  # store zeros to append to multab value
    my $add;            # GoldenBigMath to be added as
                        # next multiplication by single digit

    # --- now calculate mul by schriftliche multiplication ---------------------

    for (my $i = length($z1)-1; $i >= 0; $i--) {
	$d = substr($z1, $i, 1);
	if ($d != '0') {
	    # --- $add = $d * $d2, much faster is using table as follows
	    $add    = $mulTabRef->[$d] . $addZeros;
	    $result = AdditionWithoutSignPointAndExponent($result, $add);
	}
	$addZeros .= '0';            # next number position, mulTabRef *= 10;

        # --- print dots (.) to see its still running and not hanging ----------
	if ($c > 16383) {
	    print "\n";
	    $c = 1;
	}
	print "." unless $c++ & 127;
    }

    return $result;
 }

# FB-SCHR/ =====================================================================
# FB-SCHR% =====================================================================
# Really calc the division (without exponent, decimal point and sign)
sub CalcDivisionWithoutSignPointAndExponent {
    my $gbm1 = shift;
    my $z1   = $gbm1; # to get symmetric names
    my $z2   = shift; # to get symmetric names

    $z1->prepareMulDiv($z2);

    my @mulTab       = $gbm1->ConvertMultiplicationTableToGoldenBigMath();
    my $maxDivDigits = $gbm1->GetMaxDivideDigits();

    # use string references for faster access
    my $bm1Ref = \$z1->GetValue();
    my $bm1Len = length($$bm1Ref);

    # result variables
    my $result    = '';
    my $resultObj = new GoldenBigMath->new(0);

    # index and help variables
    my $i         = 0;      # running index in GoldenBigMath
    my $z;                  # next digit  (z for german ziffer)
    my $u         = 0;      # store carry (u for german uebertrag)
    my $c         = 1;      # dot counter
    my $firstIter = 'true'; # One iteration is needed !!

    # intermediate division values
    my $rest      = '0';    # Residue of actual division step,
                            # but rest is shorter and same in german
    my %restHash = ();      # will actually not be used,
                            # coming later to identify periods

    # --- now calculate div by schriftliche division ---------------------------

    while ($i < $maxDivDigits
	   &&  ($rest != 0  ||  $firstIter  ||  $i <= $bm1Len)) {
	
        $firstIter = '';
	my $bmRest = GoldenBigMath->new($rest); # Rest as GoldenBigMath
	my $z = 0;                              # next digit of result

        # --- find next result digit -------------------------------------------

	unless ($bmRest < $mulTab[1]) {
	    while ($z < 9) {
		if ($mulTab[$z+1] > $bmRest) {
		    last;
		}
		$z++ if $z < 9;
	    }

	    # --- fire exit, should never be reached!! ---
	    if ($mulTab[$z] > $bmRest) {
		print $bmRest->GetValue() . " < " . $mulTab[$z]->GetValue()
		    . "\n";
		croak "problem during search for multiplication factor\n";
	    }

	    # --- calc next rest for division ----------------------------------

	    $bmRest = $bmRest - $mulTab[$z];
	}

        # --- add digit found --------------------------------------------------

	$result .= $z;

	# --- Check, if decimal point reached ----------------------------------

	my $lz = '0';
	if ($i < $bm1Len) {
	    $lz = substr($$bm1Ref, $i, 1);
	}
	# --- end of number reached --------------------------------------------
	elsif ($i == $bm1Len) {
	    # --- modulo wanted ? ----------------------------------------------
	    if ($gbm1->GetOperator() eq '%') {
		$result = $bmRest->GetValue();
		last;
	    }

	    # --- add decimal point --------------------------------------------

	    $result .= '.'; 
	}

	# --- Append next digit to rest ----------------------------------------

	$rest = $bmRest->GetValue() . $lz;

        # --- print dots (.) to see its still running and not hanging ----------
	if ($c > 16383) {
	    print "\n";
	    $c = 1;
	}
	print "." unless $c++ %127;

	$i++;
    }
    
    # --- create and fill result object ----------------------------------------
    $z1->Normalize();
    $z2->Normalize();
    $resultObj = GoldenBigMath->new($result);
    $resultObj->Normalize();
    $resultObj->_storeOperator($gbm1->GetOperator());
    $resultObj->_storeOperatorName("div string");
    $resultObj->_storeU('...');
    $resultObj->_setZ1($z1); #TODO: clean up storage??
    $resultObj->_setZ2($z2); #TODO: clean up storage??

    return $resultObj;
}

__END__

=head1 NAME

Math::GoldenBigMath - Verified Big Real Number Calcualtion With Operators + - * / %

=head1 VERSION

This documentation refers to version 0.804 of Math::GoldenBigMath

=head1 SYNOPSIS

  use Math::GoldenBigMath;

  $a = new Math::GoldenBigMath("3");
  $b = new Math::GoldenBigMath("4.1e+0");

  $sum  = $a + $b;      #  7.1   "+71e-1"
  $diff = $a - $b;      # -1.1   "-11e-1"
  $mul  = $a * $b;      # 12.3   "+123e-1"

  print "$a + $b = $sum\n";
  print "$a - $b = $diff\n";
  print "$a * $b = $mul\n";

  $a->Simplify(); # get back to optimal exponent

  print "$a\n";

  print '3 <=> 4.1: '.($a <=> $b)."\n";
  print '3 >  4.1:  '.($a >  $b)."\n";
  print '3 >= 4.1:  '.($a >= $b)."\n";
  print '3 <  4.1:  '.($a <  $b)."\n";
  print '3 <= 4.1:  '.($a <= $b)."\n";
  print '3 == 4.1:  '.($a == $b)."\n";
  print '3 == 3:    '.($a == $a)."\n";

=head1 DESCRIPTION

This module implements the algorithms I (and all other german
childrens) learned in my school, in german called "Schriftliches
Rechnen". That means exact calculation with pencil and paper, before
computers or electronical calculators come up.

All of these alogrithms are exact, simple, well known and mathematical
completely proven. But they are not very fast, even for computers.

So GoldenBigMath can be used for calculation, if high speed is not
necessary or you have time to wait for the results.

It was designed to be used as a golden device to check all the other
existing libraries handling big numbers, which are fast and
complicated and so can contain errors.

Later on GoldenBigMath shell be proved by many other developers to get
a verification of correctness in that sense, if you get a result, that
the result is correct. But there is still the possibility not to get a
result, because of programming problems, memory problems or you can't
wait several years for the algorithm to finsh calculation...

=head2 Missing!

More description will follow...

=head1 Known Bugs / Missing Features

Division is deactivated, because it is not possible for floats yet but
will come, when I have time to implement it.

=head1 USAGE

Create one or more GoldenBigMath and use operators for calculation:

  + - * / % 

or comparison:

  <=> < <= > >= == !=

=head2 Missing!

More description will follow... See SYNOPSIS

=head1 AUTHOR

Ralf Peine, ralf.peine@jupiter-programs.de

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011-2013 by Ralf Peine.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
