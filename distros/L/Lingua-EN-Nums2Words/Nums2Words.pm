###############################################################################
# Numbers to Words Module for Perl.
# Copyright (C) 1996-2016, Lester Hightower <hightowe@cpan.org>
###############################################################################

package Lingua::EN::Nums2Words;
require 5.000;
require Exporter;
use strict;
use warnings;

our @ISA=qw(Exporter);
our @EXPORT=qw(num2word num2usdollars num2word_ordinal num2word_short_ordinal);

our $VERSION = "1.16";
sub Version { $VERSION; }

###############################################################################
# Private File-Global Variables ###############################################
###############################################################################
# Initialization Function init_mod_vars() sets up these variables
my @Classifications;
my @MD;
my @Categories;
my %CardinalToOrdinalMapping;
my @CardinalToShortOrdinalMapping;
my $word_case = 'upper';

# At module load time, initialize our static, file-global variables.
# We use these file-global variables to increase performance when one
# needs to compute many iterations for numbers to words.  The alternative
# would be to re-instantiate the never-changing variables over and over.
&init_mod_vars;
###############################################################################

###############################################################################
# Public Functions ############################################################
###############################################################################
sub set_case($) {
  my $case=lc(shift @_);
  my @cases=qw(upper lower);
  if (scalar(grep(/^$case$/, @cases)) != 1) {
    die __PACKAGE__.":set_case() only accepts these optons: " .
						join(", ", @cases) . "\n";
  }
  $word_case=$case;
}

sub case($) {
  my $str=shift @_;
  if ($word_case eq 'upper') {
    return uc($str);
  } elsif ($word_case eq 'lower') {
    return lc($str);
  } else {
    retrn $str;
  }
}

sub num2word {
  my $Number = shift(@_);
return(case(&num2word_internal($Number, 0)));
}

sub num2usdollars {
  my $Number = shift(@_);
  # OK, lets do some parsing of what we were handed to be nice and
  # flexible to the users of this API
  $Number=~s/^\$//;			# Kill leading dollar sign
  # Get the decimal into hundreths
  # NOTE: sprintf(%f) fails on very large decimal numbers, so we use
  #       our RoundToTwoDecimalPlaces() instead of a sprintf() call.
  #$Number=sprintf("%0.02f", $Number);
  $Number = RoundToTwoDecimalPlaces($Number);

  # Get the num2word version
  my $Final=num2word_internal($Number, 1);
  # Now whack the num2word version into a US dollar version
  my $dollar_verb='DOLLAR';
  if (abs(int($Number)) != 1) { $dollar_verb .= 'S'; }
  if (! ($Final=~s/ AND / $dollar_verb AND /)) {
    $Final .= ' DOLLAR';
    if (abs($Number) != 1) { $Final .='S'; }
  } else {
    $Final=~s/(HUNDREDTH|TENTH)([S]?)/CENT$2/;
  }

# Return the verbiage to the calling program
return(case($Final));
}

sub num2word_ordinal {
  my $Number = shift(@_);
  my($CardPartToConvToOrd, $ConvTo);
  # Get the num2word version
  my $Final=num2word_internal($Number, 0);
  # Now whack the num2word version into a US dollar version

  if ($Final=~/ AND /) {
    if ($Final =~ m/[- ]([A-Z]+) AND/) {
      $CardPartToConvToOrd=$1;
      if (defined($CardinalToOrdinalMapping{$CardPartToConvToOrd})) {
        $ConvTo=$CardinalToOrdinalMapping{$CardPartToConvToOrd};
      } else {
        $ConvTo='';
        warn "NumToWords.pm Missing CardinalToOrdinalMapping -> $CardPartToConvToOrd";
      }
      $Final =~ s/([- ])$CardPartToConvToOrd AND/$1$ConvTo AND/;
    }
  } else {
    if ($Final =~ m/([A-Z]+)$/) {
      $CardPartToConvToOrd=$1;
      if (defined($CardinalToOrdinalMapping{$CardPartToConvToOrd})) {
        $ConvTo=$CardinalToOrdinalMapping{$CardPartToConvToOrd};
      } else {
        $ConvTo='';
        warn "NumToWords.pm Missing CardinalToOrdinalMapping -> $CardPartToConvToOrd";
      }
      $Final =~ s/$CardPartToConvToOrd$/$ConvTo/;
    }
  }

# Return the verbiage to the calling program
return(case($Final));
}

sub num2word_short_ordinal {
  my $Number = shift(@_);
  if ($Number != int($Number)) {
    warn "num2word_short_ordinal can only handle integers!\n";
    return($Number);
  }
  $Number=int($Number);
  my $least_sig_dig = undef;
  my $least_2_sig_dig = undef;
  if ($Number=~m/([0-9])?([0-9])$/) {
    $least_sig_dig=$2;
    if (defined($1)) {
      $least_2_sig_dig=$1.$2;
    }
  } else {
    warn "num2word_short_ordinal couldn't find least significant int!\n";
    return($Number);
  }

  if (defined($least_2_sig_dig) &&
		defined($CardinalToShortOrdinalMapping[$least_2_sig_dig])) {
    $Number.=$CardinalToShortOrdinalMapping[$least_2_sig_dig];
  } else {
    $Number.=$CardinalToShortOrdinalMapping[$least_sig_dig];
  }
return(case($Number));
}

###############################################################################
# Private Functions ###########################################################
###############################################################################

sub num2word_internal {
  my $Number = shift(@_);
  my $KeepTrailingZeros = shift(@_);
  my($ClassificationIndex, %Breakdown, $Index);
  my($NegativeFlag, $Classification);
  my($Word, $Final, $DecimalVerbiage) = ("", "", "");

  # Hand the number off to a function to get the verbiage
  # for what appears after the decimal
  $DecimalVerbiage = &HandleDecimal($Number, $KeepTrailingZeros);

  # Determine if the number is negative and if so,
  # remember that fact and then make it positive
  if (length($Number) && ($Number < 0)) {
    $NegativeFlag=1;  $Number = $Number * -1;
  }

  # Take only the integer part of the number for the
  # calculation of the integer part verbiage
  # NOTE: Changed to regex 06/08/1998 by LHH because the int()
  #       was preventing the code from doing very large numbers
  #       by restricting the precision of $Number.
  # $Number = int($Number);
  if ($Number =~ /^([0-9]*)\./) {
    $Number = $1;
  }

  # Go through each of the @Classifications breaking off each
  # three number pair from right to left corresponding to
  # each of the @Classifications
  $ClassificationIndex = 0; 
  while (length($Number) > 0) {
    if (length($Number) > 2) {
      $Breakdown{$Classifications[$ClassificationIndex]} =
	  substr($Number, length($Number) - 3);
      $Number = substr($Number, 0, length($Number) - 3);
    } else {
      $Breakdown{$Classifications[$ClassificationIndex]} = $Number;
      $Number = "";
    }
    $ClassificationIndex++; 
  }

  # Go over each of the @Classifications producing the verbiage
  # for each and adding each to the verbiage stack ($Final)
  $Index=0;
  foreach $Classification (@Classifications) {
    # If the value of these three digits == 0 then they can be ignored
    if ( (! defined($Breakdown{$Classification})) ||
		($Breakdown{$Classification} < 1) ) { $Index++; next;}

    # Retrieves the $Word for these three digits
    $Word = &HandleThreeDigit($Breakdown{$Classification});

    # Leaves "$Classifications[0] off of HUNDREDs-TENs-ONEs numbers
    if ($Index > 0) {
      $Word .= " " . $Classification;
    }

    # Adds this $Word to the $Final and determines if it needs a comma
    if (length($Final) > 0) {
      $Final = $Word . ", " . $Final;
    } else {
      $Final = $Word;
    }
    $Index++;
  }

  # If our $Final verbiage is an empty string then our original number
  # was zero, so make the verbiage reflect that.
  if (length($Final) == 0) {
    $Final = "ZERO";
  }

  # If we marked the number as negative in the beginning, make the
  # verbiage reflect that by prepending NEGATIVE
  if ($NegativeFlag) {
    $Final = "NEGATIVE " . $Final;
  }

  # Now append the decimal portion of the verbiage calculated at the
  # beginning if there is any
  if (length($DecimalVerbiage) > 0) {
    $Final .= " AND " . $DecimalVerbiage;
  }

# Return the verbiage to the calling program
return($Final);
}

# Helper function which handles three digits from the @Classifications
# level (THOUSANDS, MILLIONS, etc) - Deals with the HUNDREDs
sub HandleThreeDigit {
  my $Number = shift(@_);
  my($Hundreds, $HundredVerbiage, $TenVerbiage, $Verbiage);

  if (length($Number) > 2) {
    $Hundreds = substr($Number, 0, 1);
    $HundredVerbiage = &HandleTwoDigit($Hundreds);
    if (length($HundredVerbiage) > 0) {
      $HundredVerbiage .= " HUNDRED";
    }
    $Number = substr($Number, 1);
  }
  $TenVerbiage = &HandleTwoDigit($Number);
  if ( (defined($HundredVerbiage)) && (length($HundredVerbiage) > 0) ) {
    $Verbiage = $HundredVerbiage;
    if (length($TenVerbiage)) { $Verbiage .= " " . $TenVerbiage; }
  } else {
    $Verbiage=$TenVerbiage;
  }
return($Verbiage);
}

# Helper function which handles two digits (from 99 to 0)
sub HandleTwoDigit {
  my $Number = shift(@_);
  my($Verbiage, $Tens, $Ones);

  if (length($Number) < 2) {
    return($MD[$Number]);
  } else {
    if ($Number < 20) {
      return($MD[$Number]);
    } else {
      $Tens = substr($Number, 0, 1);
      $Tens = $Tens * 10;
      $Ones = substr($Number, 1, 1);
      if (length($MD[$Ones]) > 0) {
        $Verbiage = $MD[$Tens] . "-" . $MD[$Ones];
      } else {
        $Verbiage = $MD[$Tens];
      }
    }
  }
return($Verbiage);
}

sub HandleDecimal {
  my $DecNumber = shift(@_);
  my $KeepTrailingZeros = shift(@_);
  my $Verbiage = "";
  my $CategoriesIndex = 0;
  my $CategoryVerbiage = '';

  # I'm choosing to do this string-wise rather than mathematically
  # because the error in the mathematics can alter the number from
  # exactly what was sent in for high significance numbers
  # NOTE: Changed "if" to regex 06/08/1998 by LHH because the int()
  #       was preventing the code from doing very large numbers
  #       by restricting the precision of $Number.
  if ( ! ($DecNumber =~ /\./) ) {
    return('');
  } else {
    $DecNumber = substr($DecNumber, rindex($DecNumber, '.') + 1);
    # Trim off any trailing zeros...
    if (! $KeepTrailingZeros) { $DecNumber =~ s/0+$//; }
  }

  $CategoriesIndex = length($DecNumber);
  $CategoryVerbiage = $Categories[$CategoriesIndex - 1];
  if (length($DecNumber) && $DecNumber == 1) {
    # if the value of what is after the decimal place is one, then
    # we need to chop the "s" off the end of the $CategoryVerbiage
    # to make is singular
    chop($CategoryVerbiage);
  }
  $Verbiage = &num2word($DecNumber) . " " . $CategoryVerbiage;
return($Verbiage);
}

# NOTE: sprintf(%f) fails on very large decimal numbers, thus the
# need for RoundToTwoDecimalPlaces().
sub RoundToTwoDecimalPlaces($) {
  my $Number=shift @_;

  my($Int,$Dec,$UserScrewUp) = split(/\./, $Number, 3);
  if (defined($UserScrewUp) && length($UserScrewUp)) {
                warn "num2usdollars() given invalid value."; }
  if (! length($Int)) { $Int=0; }
  $Dec = 0 if not defined($Dec);
  my $DecPart=int(sprintf("%0.3f", "." . $Dec) * 100 + 0.5);

  $Number=$Int . '.' . $DecPart;
return $Number;
}

# This function initializes our static, file-global variables.
sub init_mod_vars {
  @Categories =		(
				"TENTHS",
				"HUNDREDTHS",
				"THOUSANDTHS",
				"TEN-THOUSANDTHS",
				"HUNDRED-THOUSANDTHS",
				"MILLIONTHS",
				"TEN-MILLIONTHS",
				"HUNDRED-MILLIONTHS",
				"BILLIONTHS",
				"TEN-BILLIONTHS",
				"HUNDRED-BILLIONTHS",
				"TRILLIONTHS",
				"QUADRILLIONTHS",
				"QUINTILLIONTHS",
				"SEXTILLIONTHS",
				"SEPTILLIONTHS",
				"OCTILLIONTHS",
				"NONILLIONTHS",
				"DECILLIONTHS",
				"UNDECILLIONTHS",
				"DUODECILLIONTHS",
				"TREDECILLIONTHS",
				"QUATTUORDECILLIONTHS",
				"QUINDECILLIONTHS",
				"SEXDECILLIONTHS",
				"SEPTEMDECILLIONTHS",
				"OCTODECILLIONTHS",
				"NOVEMDECILLIONTHS",
				"VIGINTILLIONTHS"
			);

  ###################################################

  $MD[0]  =  "";
  $MD[1]  =  "ONE";
  $MD[2]  =  "TWO";
  $MD[3]  =  "THREE";
  $MD[4]  =  "FOUR";
  $MD[5]  =  "FIVE";
  $MD[6]  =  "SIX";
  $MD[7]  =  "SEVEN";
  $MD[8]  =  "EIGHT";
  $MD[9]  =  "NINE";
  $MD[10] =  "TEN";
  $MD[11] =  "ELEVEN";
  $MD[12] =  "TWELVE";
  $MD[13] =  "THIRTEEN";
  $MD[14] =  "FOURTEEN";
  $MD[15] =  "FIFTEEN";
  $MD[16] =  "SIXTEEN";
  $MD[17] =  "SEVENTEEN";
  $MD[18] =  "EIGHTEEN";
  $MD[19] =  "NINETEEN";
  $MD[20] =  "TWENTY";
  $MD[30] =  "THIRTY";
  $MD[40] =  "FORTY";
  $MD[50] =  "FIFTY";
  $MD[60] =  "SIXTY";
  $MD[70] =  "SEVENTY";
  $MD[80] =  "EIGHTY";
  $MD[90] =  "NINETY";

  ###################################################

  @Classifications =		(
				"HUNDREDs-TENs-ONEs",
				"THOUSAND",
				"MILLION",
				"BILLION",
				"TRILLION",
				"QUADRILLION",
				"QUINTILLION",
				"SEXTILLION",
				"SEPTILLION",
				"OCTILLION",
				"NONILLION",
				"DECILLION",
				"UNDECILLION",
				"DUODECILLION",
				"TREDECILLION",
				"QUATTUORDECILLION",
				"QUINDECILLION",
				"SEXDECILLION",
				"SEPTEMDECILLION",
				"OCTODECILLION",
				"NOVEMDECILLION",
				"VIGINTILLION"
				);


  ###################################################

  $CardinalToOrdinalMapping{'ZERO'} =  "ZEROTH";
  $CardinalToOrdinalMapping{'ONE'} =  "FIRST";
  $CardinalToOrdinalMapping{'TWO'} =  "SECOND";
  $CardinalToOrdinalMapping{'THREE'} =  "THIRD";
  $CardinalToOrdinalMapping{'FOUR'} =  "FOURTH";
  $CardinalToOrdinalMapping{'FIVE'} =  "FIFTH";
  $CardinalToOrdinalMapping{'SIX'} =  "SIXTH";
  $CardinalToOrdinalMapping{'SEVEN'} =  "SEVENTH";
  $CardinalToOrdinalMapping{'EIGHT'} =  "EIGHTH";
  $CardinalToOrdinalMapping{'NINE'} =  "NINTH";
  $CardinalToOrdinalMapping{'TEN'} =  "TENTH";
  $CardinalToOrdinalMapping{'ELEVEN'} =  "ELEVENTH";
  $CardinalToOrdinalMapping{'TWELVE'} =  "TWELFTH";
  $CardinalToOrdinalMapping{'THIRTEEN'} =  "THIRTEENTH";
  $CardinalToOrdinalMapping{'FOURTEEN'} =  "FOURTEENTH";
  $CardinalToOrdinalMapping{'FIFTEEN'} =  "FIFTEENTH";
  $CardinalToOrdinalMapping{'SIXTEEN'} =  "SIXTEENTH";
  $CardinalToOrdinalMapping{'SEVENTEEN'} =  "SEVENTEENTH";
  $CardinalToOrdinalMapping{'EIGHTEEN'} =  "EIGHTEENTH";
  $CardinalToOrdinalMapping{'NINETEEN'} =  "NINETEENTH";
  $CardinalToOrdinalMapping{'TWENTY'} =  "TWENTIETH";
  $CardinalToOrdinalMapping{'THIRTY'} =  "THIRTIETH";
  $CardinalToOrdinalMapping{'FORTY'} =  "FORTIETH";
  $CardinalToOrdinalMapping{'FIFTY'} =  "FIFTIETH";
  $CardinalToOrdinalMapping{'SIXTY'} =  "SIXTIETH";
  $CardinalToOrdinalMapping{'SEVENTY'} =  "SEVENTIETH";
  $CardinalToOrdinalMapping{'EIGHTY'} =  "EIGHTIETH";
  $CardinalToOrdinalMapping{'NINETY'} =  "NINETIETH";
  $CardinalToOrdinalMapping{'HUNDRED'} =  "HUNDREDTH";
  $CardinalToOrdinalMapping{'THOUSAND'} =  "THOUSANDTH";
  $CardinalToOrdinalMapping{'MILLION'} =  "MILLIONTH";
  $CardinalToOrdinalMapping{'BILLION'} =  "BILLIONTH";
  $CardinalToOrdinalMapping{'TRILLION'} =  "TRILLIONTH";
  $CardinalToOrdinalMapping{'QUADRILLION'} =  "QUADRILLIONTH";
  $CardinalToOrdinalMapping{'QUINTILLION'} =  "QUINTILLIONTH";
  $CardinalToOrdinalMapping{'SEXTILLION'} =  "SEXTILLIONTH";
  $CardinalToOrdinalMapping{'SEPTILLION'} =  "SEPTILLIONTH";
  $CardinalToOrdinalMapping{'OCTILLION'} =  "OCTILLIONTH";
  $CardinalToOrdinalMapping{'NONILLION'} =  "NONILLIONTH";
  $CardinalToOrdinalMapping{'DECILLION'} =  "DECILLIONTH";
  $CardinalToOrdinalMapping{'TREDECILLION'} =  "TREDECILLIONTH";
  $CardinalToOrdinalMapping{'QUATTUORDECILLION'} =  "QUATTUORDECILLIONTH";
  $CardinalToOrdinalMapping{'QUINDECILLION'} =  "QUINDECILLIONTH";
  $CardinalToOrdinalMapping{'SEXDECILLION'} =  "SEXDECILLIONTH";
  $CardinalToOrdinalMapping{'SEPTEMDECILLION'} =  "SEPTEMDECILLIONTH";
  $CardinalToOrdinalMapping{'OCTODECILLION'} =  "OCTODECILLIONTH";
  $CardinalToOrdinalMapping{'NOVEMDECILLION'} =  "NOVEMDECILLIONTH";
  $CardinalToOrdinalMapping{'VIGINTILLION'} =  "VIGINTILLIONTH";

  ###################################################
  $CardinalToShortOrdinalMapping[0]='th';
  $CardinalToShortOrdinalMapping[1]='st';
  $CardinalToShortOrdinalMapping[11]='th'; # Special for low teens
  $CardinalToShortOrdinalMapping[2]='nd';
  $CardinalToShortOrdinalMapping[12]='th'; # Special for low teens
  $CardinalToShortOrdinalMapping[3]='rd';
  $CardinalToShortOrdinalMapping[13]='th'; # Special for low teens
  $CardinalToShortOrdinalMapping[4]='th';
  $CardinalToShortOrdinalMapping[5]='th';
  $CardinalToShortOrdinalMapping[6]='th';
  $CardinalToShortOrdinalMapping[7]='th';
  $CardinalToShortOrdinalMapping[8]='th';
  $CardinalToShortOrdinalMapping[9]='th';
}

1;



# PERL POD ####################################################################

=head1 NAME

Lingua::EN::Nums2Words - generate English verbiage from numerical values

=head1 SYNOPSIS

  use Lingua::EN::Nums2Words;
  
  $Number   = 42;
  $Verbiage = num2word($Number);
  $Verbiage = num2word_ordinal($Number);
  $Verbiage = num2word_short_ordinal($Number);
  $Verbiage = num2usdollars($Number);

=head1 DESCRIPTION

This module provides functions that can be used to generate English
verbiage for numbers.

To the best of my knowledge, this code can handle every real value
from negative infinity to positive infinity.

This module makes verbiage in "short scales" (1,000,000,000 is "one billion"
rather than "one thousand million"). For details see this Wikipedia article:

L<http://en.wikipedia.org/wiki/Long_and_short_scales>

=head1 SUBROUTINES

The following code illustrates use of the four functions in this module:

  use Lingua::EN::Nums2Words;
  
  $age = 45;
  print "I am ", num2word($age), " years old.\n";
  print "I've had my ", num2word_ordinal($age), " birthday.\n";
  print "I'm in my ", num2word_short_ordinal($age+1), " year.\n";
  print "Pay me ", num2usdollars($age), ".\n";

This prints out:

  I am FORTY-FIVE years old.
  I've had my FORTY-FIFTH birthday.
  I'm in my 46th year.
  Pay me FORTY-FIVE DOLLARS AND ZERO CENTS.

As shown above, the default is to return uppercase words.  If you would
prefer to have lowercase words returned, make this call once, early in
your program:

 Lingua::EN::Nums2Words::set_case('lower'); # Accepts upper|lower

=head1 COPYRIGHT

Copyright (C) 1996-2016, Lester H. Hightower, Jr. <hightowe@cpan.org>

=head1 LICENSE

As of version 1.13, this software is licensed under the OSI certified
Artistic License, one of the licenses of Perl itself.

L<http://en.wikipedia.org/wiki/Artistic_License>

=cut

###############################################################################

