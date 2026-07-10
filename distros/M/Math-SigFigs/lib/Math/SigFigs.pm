package Math::SigFigs;

# Copyright (c) 1995-2019 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

########################################################################

require 5.004;
require Exporter;
use Carp;
use strict;
use warnings;

our (@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
use base qw(Exporter);
@EXPORT     = qw(FormatSigFigs
                 CountSigFigs
               );
@EXPORT_OK  = qw(FormatSigFigs
                 CountSigFigs
                 addSF subSF multSF divSF
                 VERSION);

%EXPORT_TAGS = ('all' => \@EXPORT_OK);

our($VERSION);
$VERSION='1.22';

use strict;

sub addSF {
   my($n1,$n2)=@_;
   _add($n1,$n2,0);
}

sub subSF {
   my($n1,$n2)=@_;
   _add($n1,$n2,1);
}

sub _add {
   my($n1in,$n2in,$sub) = @_;

   my($n1,$sig1,$lsp1,$s1,$int1,$dec1,$n2,$sig2,$lsp2,$s2,$int2,$dec2);

   if (defined($n1in)) {
      ($n1,$sig1,$lsp1,$s1,$int1,$dec1) = _Simplify($n1in);
   }
   return   if (! defined($n1));

   if (defined($n2in)) {
      ($n2,$sig2,$lsp2,$s2,$int2,$dec2) = _Simplify($n2in);
   }
   return   if (! defined($n2));

   if ($sub) {
      if ($n2<0) {
         $n2 =~ s/\-//;
         $s2 = '';
      } elsif ($n2 > 0) {
         $n2 =~ s/^\+?/-/;
         $s2 = '-';
      }
   }

   return $n2    if ($n1in eq '0');
   return $n1    if ($n2in eq '0');

   my $lsp = ($lsp1 > $lsp2 ? $lsp1 : $lsp2);

   ($n1) = _ToExp($s1,$int1,$dec1,$lsp);
   ($n2) = _ToExp($s2,$int2,$dec2,$lsp);

   my($n,$sig,$tmp,$s,$int,$dec) = _Simplify($n1+$n2);
   $n = sprintf("%.0f",$n) . ".e$lsp";
   ($n,$sig,$lsp,$tmp,$int,$dec) = _Simplify("${n}");
   return $n;
}

sub multSF {
   my($n1,$n2)=@_;
   _mult($n1,$n2,0);
}

sub divSF {
   my($n1,$n2)=@_;
   _mult($n1,$n2,1);
}

sub _mult {
   my($n1,$n2,$div)=@_;
   my($sig1,$sig2);

   if (defined($n1)) {
      ($n1,$sig1) = _Simplify($n1);
   }
   return   if (! defined($n1));

   if (defined($n2)) {
      ($n2,$sig2) = _Simplify($n2);
   }
   return   if (! defined($n2)  ||
                ($div  &&  $n2 == 0));

   my $sig = ($sig1 < $sig2 ? $sig1 : $sig2);
   my($n)  = ($div ? $n1/$n2 : $n1*$n2);
   return FormatSigFigs($n,$sig);
}

sub FormatSigFigs {
   my($N,$n) = @_;
   return ''  if ($n !~ /^\d+$/  ||  $n == 0);

   my($ret,$sig,$lsp,$s,$int,$dec);
   ($N,$sig,$lsp,$s,$int,$dec) = _Simplify($N);
   return ""  if (! defined($N));
   return '0.0'  if ($N==0  &&  $n==1);

   return $N  if ($sig eq $n);

   # Convert $N to an exponential where the numeric part with the exponent
   # ignored is 0.1 <= $num < 1.0.  i.e. 0.#####e## where the first '#' is
   # non-zero.  Then we can format it using a simple sprintf command.

   my($num,$e);
   if ($int > 0) {
      $num = "0.$int$dec";
      $e   = length($int);
   } elsif ($dec ne ''  &&  $dec > 0) {
      $dec =~ s/^(0*)//;
      $num = "0.$dec";
      $e   = -length($1);
   } else {
      $e = 0;
      $num = "$int.$dec";
   }

   # sprintf doesn't round 5 up, so convert a 5 to 6 in the n+1'th position

   if ($n < $sig  &&  substr($num,$n+2,1) eq '5') {
      substr($num,$n+2,1) = '6';
   }

   # We have to handle the one special case:
   #    0.99 (1) => 1.0
   # If sprintf rounds a number to 1.0 or higher, then we reduce the
   # number of decimal points by 1.

   my $tmp = sprintf("%.${n}f",$num);
   if ($tmp >= 1.0) {
      $n--;
      $tmp = sprintf("%.${n}f",$num);
   }
   ($N,$sig,$lsp,$s,$int,$dec) = _Simplify("$s${tmp}e$e");
   return $N;
}

sub CountSigFigs {
   my($N) = @_;
   my($sig);
   ($N,$sig) = _Simplify($N);
   return ()  if (! defined($N));
   return $sig;
}

########################################################################
# NOT FOR EXPORT
#
# These are for internal use only.  They are not guaranteed to remain
# backward compatible (or even to exist at all) in future versions.
########################################################################

# This takes the parts of a number ($int and $dec) and turns it into
# an exponential with the LSP in the 1's place.  The exponent is
# returned (rather than appended to the number).
#
sub _ToExp {
   my($s,$int,$dec,$lsp) = @_;

   if ($lsp == 0) {
      return ("$s$int.${dec}",0);
   }

   if ($lsp > 0) {
      my $z = ($lsp > length($int) ?
               "0"x($lsp-length($int)) : "");
      $int  = "$z$int";
      $dec  = substr($int,-$lsp) . $dec;
      $int  = substr($int,0,length($int)-$lsp);
      return ("$s$int.${dec}",-$lsp);
   }

   $dec .= "0"x(-$lsp-length($dec))  if (-$lsp > length($dec));
   $int .= substr($dec,0,-$lsp);
   $dec  = substr($dec,-$lsp);
   return ("$s$int.${dec}",-$lsp);
}

# This prepares a number by converting it to it's simplest correct
# form.  All space is ignored.  It handles numbers of the form:
#    signed (+, -, or no sign)
#    integers
#    reals (###.###)
#    exponential (###.###e###)
#
# It returns:
#    the number in the simplest form
#    the number of significant figures
#    the power of the least significant digit
#
sub _Simplify {
   my($n)  = @_;
   return  if (! defined($n));
   $n      =~ s/\s+//g;
   $n      =~ s/^([+-])//;
   my $s   = $1  ||  '';
   return  if ($n eq '');
   my $exp;
   if ($n  =~ s/[eE]([+-]*\d+)$//) {
      $exp = $1;
   } else {
      $exp = 0;
   }

   my($int,$dec,$sig,$lsp);

   if ($n  =~ /^\d+$/) {                    # 00     0123     012300
      $int    = $n+0;                       # 0      123      12300
      $int    =~ /^(\d+?)(0*)$/;
      my($i,$z) = ($1,$2);                  # 0,''   123,''   123,00
      $lsp    = length($z);                 # 0      0        2
      $sig    = length($int) - $lsp;        # 1      3        3
      $dec    = '';

   } elsif ($n =~ /^0*\.(\d+)$/) {          # .000       .00123     .0012300
      $dec    = $1;                         # 000        00123      0012300
      $int    = '';
      $dec    =~ /^(0*?)([1-9]\d*?)?(0*+)$/;
      my($z0,$d,$z1) = ($1,$2,$3);          # '','',000  00,123,''  00,123,00
      $lsp    = -length($dec);              # -3         -5         -7
      $sig    = length($dec)-length($z0);   # 3          3          5

   } elsif ($n =~ /^0*(\d+)\.(\d*)$/) {     # 12.       12.3
      ($int,$dec) = ($1,$2);                # 12,''     12,3
      $lsp    = -length($dec);              # 0         -1
      $sig    = length($int) + length($dec);# 2         3

   } else {
      return;
   }

   # Handle the exponent, if any

   if ($exp > 0) {
      if ($exp >= length($dec)) {
         $int  = "$int$dec" . "0"x($exp-length($dec));
         $dec  = '';
      } else {
         $int .= substr($dec,0,$exp);
         $dec  = substr($dec,$exp);
      }
      $lsp += $exp;
      $int  =~ s/^0*//;
      $int  = '0'  if (! $int);

   } elsif ($exp < 0) {
      if (-$exp < length($int)) {
         $dec  = substr($int,$exp) . $dec;
         $int  = substr($int,0,length($int)+$exp);
      } else {
         $dec  = "0"x(-$exp-length($int)) . "$int$dec";
         $int  = "0";
      }
      $lsp += $exp;
   }

   # We have a decimal point if:
   #    There is a decimal section
   #    An integer ends with a significant 0 but is not exactly 0
   # We prepend a sign to anything except for 0

   my $num;
   if ($dec eq '') {
      $num  = $int;
      $num .= "."  if ($lsp == 0  &&  $int =~ /0$/  &&  $int ne '0');
   } else {
      $int  = "0"  if ($int eq '');
      $num  = "$int.$dec";
   }
   $s       = ''   if ($num == 0  ||  $s eq '+');
   $num     = "$s$num";

   return ($num,$sig,$lsp,$s,$int,$dec);
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
