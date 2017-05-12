package Math::SigDig;

#Robert W. Leach
#Princeton University
#Carl Icahn Laboratory
#Lewis Sigler Institute for Integrative Genomics
#Bioinformatics Group
#Room 133A
#Princeton, NJ 08544
#rleach@genomics.princeton.edu
#Copyright 2014

#NOTICE
#
#This software (Math::SigDig) and ancillary information (herein
#called "SOFTWARE") is free: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This software is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#If SOFTWARE is modified to produce derivative works, such modified
#SOFTWARE should be clearly marked, so as not to confuse it with this
#version.



use 5.012003;
use strict;
use warnings;

use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = qw(sigdig getsigdig);
@EXPORT_OK   = ();
%EXPORT_TAGS = ();

sub sigdig
  {
    my $num    = $_[0];
    my $places = defined($_[1]) ? $_[1] : 3;

    #Pad with 0's by adding decimal places up to $places significant digits, or
    #if $places is 0, up to the pad value (note there can still be numbers in
    #this case with more significant digits than specified by the pad value)
    my $pad = defined($_[2]) ? ($places > 0 && $_[2] ? $places : $_[2]) : 0;

    my $new_num = '';

    if(!defined($places) || $places !~ /\d/ || $places =~ /\D/ || $places < 0)
      {
	print STDERR ("ERROR:sigdig(): An invalid number of significant ",
                      "digits was specified.");
	return($num);
      }
    #0 means all are significant digits
    elsif($places == 0)
      {
	$new_num = $num;
	my $cur_sig_dig = getsigdig($new_num);
	if($pad > $cur_sig_dig)
	  {
	    #If there's an exponent
	    if($new_num =~ /^([+\-]?[0-9\.]+)(e[+\-]?[0-9\.]+)$/i)
	      {
		my $pree = $1;
		my $e    = $2;
		return(sigdig($pree,$places,$pad).$e);
	      }
	    #If there's an exponent and no preceding number
	    elsif($new_num =~ /^([+\-]?)e[+\-]?[0-9\.]+$/i)
	      {
		my $sign = $1;
		my $e    = $2;
		return(sigdig($sign.'1',$places,$pad).$e);
	      }
	    #Pad the number
	    else
	      {
		if($new_num !~ /\./)
		  {$new_num .= '.'}
		$new_num .= '0' x ($pad - $cur_sig_dig);
		return($new_num);
	      }
	  }

	return($new_num);
      }

    #If there's an exponent with a preceding number
    if($num =~ /^([+\-]?[0-9\.]*)(e[+\-]?[0-9\.]+)$/i)
      {
	my $pree = $1;
	my $e    = $2;
	$pree = $pree . '1' if($pree !~ /\d/);
	return(sigdig($pree,$places,$pad).$e);
      }
    elsif($num =~ /[^0-9\.+\-]/ || $num =~ /\..*\./ || $num =~ /.[+\-]/)
      {
	print STDERR ("ERROR:sigdig(): Invalid number format: [$num].");
	return($num);
      }
    elsif($num == 0)
      {
	if($pad)
	  {
	    $new_num = '0.';
	    if($new_num !~ /\./)
	      {$new_num .= '.'}
	    $new_num .= '0' x $pad;
	    return($new_num);
	  }
	return(0);
      }

    my $first_real   = 0;
    my $num_added    = 0;
    my $decimal_seen = 0;
    my $last_digit   = 0;
    my $sign         = '';
    foreach my $digit (unpack("(A)*",$num))
      {
        if($digit =~ /\+|-/)
          {
            $sign = $digit;
            next;
          }
        if($digit =~ /[1-9]/)
          {$first_real = 1}
        elsif($digit eq '.')
          {
            $decimal_seen = 1;
            if($new_num eq '')
              {$new_num = '0'}
            if($num_added < $places)
              {$new_num .= '.'}
            elsif($num_added > $places)
              {last}
            next;
          }

        if($first_real)
          {
            if($num_added < $places)
              {
                $new_num .= $digit;
                $num_added++;
              }
            elsif($num_added == $places)
              {
                if($digit >= 5)
                  {
                    #This gets rid of the decimal
                    my $tmp_num = join("",split(/\D*/,$new_num)) + 1;
                    if($new_num =~ /\.(\d*)$/)
                      {
                        my $len = length($1);
                        unless($tmp_num =~ s/(?=\d{$len}\Z)/./)
                          {
                            if($new_num =~ /^(0\.0+)/)
                              {$tmp_num = "$1$tmp_num"}
                          }
                      }
                    $new_num = $tmp_num;
                  }

		#If we haven't gotten to the end of the whole number yet
                if(!$decimal_seen)
                  {
                    $new_num .= '0';
                    $num_added++;
                  }
                else
                  {last}
              }
            elsif(!$decimal_seen)
              {
                $new_num .= '0';
                $num_added++;
              }
            else
              {last}
            $last_digit = $digit;
          }
        elsif($decimal_seen)
          {$new_num .= '0'}
      }

    if($pad)
      {
	my $cur_sig_dig = getsigdig($new_num);
	if($pad > $cur_sig_dig && $new_num !~ /\./)
	  {$new_num .= '.'}
	$new_num .= '0' x ($pad - $cur_sig_dig);
      }
    #Trim the trailing zeros
    elsif($new_num =~ /\./i)
      {
	$new_num =~ s/0+$//;
	$new_num =~ s/\.$//;
      }

    return("$sign$new_num");
  }

sub getsigdig
  {
    my $num           = $_[0];
    my $nowholetail   = defined($_[1]) ? $_[1] : 0;
    my $nodecimaltail = defined($_[2]) ? $_[2] : 0;

    #Remove sign
    $num =~ s/[+\-]+//g;

    #Repair exponents with assumed 1s
    if($num =~ /^e/i)
      {$num = "1$num"}
    #Remove exponent
    $num =~ s/e.*//i;

    #Remove leading zeros
    $num =~ s/^0+//;

    #If $nowholetail is true and there's no decimal point, remove trailing
    #whole-number zeros
    $num =~ s/0+$// if($nowholetail && $num !~ /\./);

    #Remove decimal point
    $num =~ s/\.//;

    #If $nodecimaltail is true, remove all trailing zeros
    $num =~ s/0+$// if($nodecimaltail);

    return(length($num));
  }






1;
__END__

=head1 NAME

Math SigDig - Perl extension for Math

=head1 SYNOPSIS
 
  #Example 1 (Using default of 3 significant digits):
 
  use Math::SigDig;
  print(sigdig(12.3456789));
  #prints "12.3"
 
  #Example 2 (Argument 2: Custom number of significant digits):
 
  use Math::SigDig;
  print(sigdig(12.3456789,4));
  #prints "12.35"

  #Example 3 (Signs & exponents are allowed):

  use Math::SigDig;
  print(sigdig("-12.345e-6789",2));
  #prints "-12e-6789"
 
  #Example 4 (No zero-padding by default):
 
  use Math::SigDig;
  print(sigdig(12.00456789,4));
  #prints "12"

  #Example 5 (Argument 3 [0 or non-zero]: Padding with zeros):

  use Math::SigDig;
  print(sigdig(12.00456789,4,1));
  #prints "12.00"

  #Example 6 (Fill/no-chop mode where arg2 = 0 & arg3 > 0):

  use Math::SigDig;
  print(sigdig(12.00456789,0,4),",",sigdig(12,0,4));
  #prints "12.00456789,12.00"

  #Example 7 (Getting number of significant digits):

  use Math::SigDig;
  $n = getsigdig(12.3456789);
  #$n = 9

  #Example 8 (Signs & exponents are allowed):

  use Math::SigDig;
  $n = getsigdig("+12.3456789e+123");
  #$n = 9

  #Example 9 (Assumed significance except leading whole-number zeros):

  use Math::SigDig;
  $n = getsigdig("0001000.000");
  #$n = 7

  #Example 10 (Using the significant digits argument (arg 2) [0 or non-zero]:
  #            No trailing zeros, unless decimal present):

  use Math::SigDig;
  $n = getsigdig(1000,1);
  #$n = 1
  $n = getsigdig("1000.000",1);
  #$n = 7

  #Example 11 (Using the pad argument (arg 3) [0 or non-zero]:
  #            No trailing zeros, inc. decimals):

  use Math::SigDig;
  $n = getsigdig("1000.000",0,1); #Arg 2 is ignored when arg3 is non-zero
  #$n = 1

  #Example 12 (Doing math):

  use Math::SigDig;
  $x = 12.3456789;
  $y = 12.34;
  $nx = getsigdig($x);
  $ny = getsigdig($y);
  $z = sigdig($x * $y,                #Multiplication
              ($nx<$ny ? $nx : $ny)); #The lesser number of significant digits
  #$z = 152.3


=head1 ABSTRACT

Math::SigDig allows you to edit numbers to a significant number of digits (whether they include a decimal point or not).  In scientific endeavors, the number of digits that are "significant" in the result of a calculation using 2 numbers is frequently the number of significant digits in the number with the least number of significant digits (e.g. 2.0 * 232.12 = 464.24, where 464.24 is reduced to 2 significant digits: 460).

=head1 DESCRIPTION

Math::SigDig is a module that provides methods to round a number to a specified number of significant digits and count the number of significant digits.

It trims leading zeros.  It counts, but trims trailing zeros after a decimal point, unless the pad argument (3) to sigdig is non-zero.

Math::SigDig differs from Math::SigFigs in a number of ways.  In this module, a "whole-number" zero in a number without a decimal point does not convey significance, however zeros to the right of a decimal point will make them significant.  Exponents are allowed ('e' or 'E'), but left untouched.  Prepends a 1 to a number if the first character is 'e' or 'E', indicating an assumed '1'.

=head1 NOTES

No operator overloads are provided, thus you must enforce significant digits by making calls to getsigdig and sigdig with every math operation, as in example 12 above.

Math::SigDig is intended for use in printing and is not reliable in using its outputs in mathematical calculations.  Returned values are strings, not floating point or integer values.

=head1 BUGS

No known bugs.  Please report them to I<E<lt>robleach@buffalo.eduE<gt>> if you find any.

=head1 SEE ALSO

L<Math>

=head1 AUTHOR

Robert William Leach, E<lt>rleach@princeton.eduE<gt>

=head1 COPYRIGHT AND LICENSE

This software (Math::SigDig) and ancillary information (herein
called "SOFTWARE") is free: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

If SOFTWARE is modified to produce derivative works, such modified
SOFTWARE should be clearly marked, so as not to confuse it with this
version.


=cut
