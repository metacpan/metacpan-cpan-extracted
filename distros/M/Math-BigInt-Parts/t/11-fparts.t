#!perl
#
# Author:      Peter John Acklam
# Time-stamp:  2010-08-24 16:16:42 +02:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

########################

use 5.008;              # required version of Perl
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings
use utf8;               # enable UTF-8 in source code

########################

local $| = 1;                   # disable buffering

#BEGIN {
#    chdir 't' if -d 't';
#    unshift @INC, '../lib';     # for running manually
#}

#########################

use Math::BigFloat;
use Math::BigInt::Parts qw(fparts);

sub bi { Math::BigInt   -> new($_[0]) }
sub bf { Math::BigFloat -> new($_[0]) }

my @data =
  (

   [ bf('+3.141592653589793e-12'), [ bf('+3.141592653589793'), bi('-12') ] ],
   [ bf('+3.141592653589793e-11'), [ bf('+3.141592653589793'), bi('-11') ] ],
   [ bf('+3.141592653589793e-10'), [ bf('+3.141592653589793'), bi('-10') ] ],
   [ bf('+3.141592653589793e-09'), [ bf('+3.141592653589793'), bi('-9') ] ],
   [ bf('+3.141592653589793e-08'), [ bf('+3.141592653589793'), bi('-8') ] ],
   [ bf('+3.141592653589793e-07'), [ bf('+3.141592653589793'), bi('-7') ] ],
   [ bf('+3.141592653589793e-06'), [ bf('+3.141592653589793'), bi('-6') ] ],
   [ bf('+3.141592653589793e-05'), [ bf('+3.141592653589793'), bi('-5') ] ],
   [ bf('+3.141592653589793e-04'), [ bf('+3.141592653589793'), bi('-4') ] ],
   [ bf('+3.141592653589793e-03'), [ bf('+3.141592653589793'), bi('-3') ] ],
   [ bf('+3.141592653589793e-02'), [ bf('+3.141592653589793'), bi('-2') ] ],
   [ bf('+3.141592653589793e-01'), [ bf('+3.141592653589793'), bi('-1') ] ],
   [ bf('+3.141592653589793e+00'), [ bf('+3.141592653589793'), bi('+0') ] ],
   [ bf('+3.141592653589793e+01'), [ bf('+3.141592653589793'), bi('+1') ] ],
   [ bf('+3.141592653589793e+02'), [ bf('+3.141592653589793'), bi('+2') ] ],
   [ bf('+3.141592653589793e+03'), [ bf('+3.141592653589793'), bi('+3') ] ],
   [ bf('+3.141592653589793e+04'), [ bf('+3.141592653589793'), bi('+4') ] ],
   [ bf('+3.141592653589793e+05'), [ bf('+3.141592653589793'), bi('+5') ] ],
   [ bf('+3.141592653589793e+06'), [ bf('+3.141592653589793'), bi('+6') ] ],
   [ bf('+3.141592653589793e+07'), [ bf('+3.141592653589793'), bi('+7') ] ],
   [ bf('+3.141592653589793e+08'), [ bf('+3.141592653589793'), bi('+8') ] ],
   [ bf('+3.141592653589793e+09'), [ bf('+3.141592653589793'), bi('+9') ] ],
   [ bf('+3.141592653589793e+10'), [ bf('+3.141592653589793'), bi('+10') ] ],
   [ bf('+3.141592653589793e+11'), [ bf('+3.141592653589793'), bi('+11') ] ],
   [ bf('+3.141592653589793e+12'), [ bf('+3.141592653589793'), bi('+12') ] ],
   [ bf('+3.141592653589793e+13'), [ bf('+3.141592653589793'), bi('+13') ] ],
   [ bf('+3.141592653589793e+14'), [ bf('+3.141592653589793'), bi('+14') ] ],
   [ bf('+3.141592653589793e+15'), [ bf('+3.141592653589793'), bi('+15') ] ],
   [ bf('+3.141592653589793e+16'), [ bf('+3.141592653589793'), bi('+16') ] ],
   [ bf('+3.141592653589793e+17'), [ bf('+3.141592653589793'), bi('+17') ] ],
   [ bf('+3.141592653589793e+18'), [ bf('+3.141592653589793'), bi('+18') ] ],
   [ bf('+3.141592653589793e+19'), [ bf('+3.141592653589793'), bi('+19') ] ],
   [ bf('+3.141592653589793e+20'), [ bf('+3.141592653589793'), bi('+20') ] ],

   [ bf('-3.141592653589793e-12'), [ bf('-3.141592653589793'), bi('-12') ] ],
   [ bf('-3.141592653589793e-11'), [ bf('-3.141592653589793'), bi('-11') ] ],
   [ bf('-3.141592653589793e-10'), [ bf('-3.141592653589793'), bi('-10') ] ],
   [ bf('-3.141592653589793e-09'), [ bf('-3.141592653589793'), bi('-9') ] ],
   [ bf('-3.141592653589793e-08'), [ bf('-3.141592653589793'), bi('-8') ] ],
   [ bf('-3.141592653589793e-07'), [ bf('-3.141592653589793'), bi('-7') ] ],
   [ bf('-3.141592653589793e-06'), [ bf('-3.141592653589793'), bi('-6') ] ],
   [ bf('-3.141592653589793e-05'), [ bf('-3.141592653589793'), bi('-5') ] ],
   [ bf('-3.141592653589793e-04'), [ bf('-3.141592653589793'), bi('-4') ] ],
   [ bf('-3.141592653589793e-03'), [ bf('-3.141592653589793'), bi('-3') ] ],
   [ bf('-3.141592653589793e-02'), [ bf('-3.141592653589793'), bi('-2') ] ],
   [ bf('-3.141592653589793e-01'), [ bf('-3.141592653589793'), bi('-1') ] ],
   [ bf('-3.141592653589793e+00'), [ bf('-3.141592653589793'), bi('+0') ] ],
   [ bf('-3.141592653589793e+01'), [ bf('-3.141592653589793'), bi('+1') ] ],
   [ bf('-3.141592653589793e+02'), [ bf('-3.141592653589793'), bi('+2') ] ],
   [ bf('-3.141592653589793e+03'), [ bf('-3.141592653589793'), bi('+3') ] ],
   [ bf('-3.141592653589793e+04'), [ bf('-3.141592653589793'), bi('+4') ] ],
   [ bf('-3.141592653589793e+05'), [ bf('-3.141592653589793'), bi('+5') ] ],
   [ bf('-3.141592653589793e+06'), [ bf('-3.141592653589793'), bi('+6') ] ],
   [ bf('-3.141592653589793e+07'), [ bf('-3.141592653589793'), bi('+7') ] ],
   [ bf('-3.141592653589793e+08'), [ bf('-3.141592653589793'), bi('+8') ] ],
   [ bf('-3.141592653589793e+09'), [ bf('-3.141592653589793'), bi('+9') ] ],
   [ bf('-3.141592653589793e+10'), [ bf('-3.141592653589793'), bi('+10') ] ],
   [ bf('-3.141592653589793e+11'), [ bf('-3.141592653589793'), bi('+11') ] ],
   [ bf('-3.141592653589793e+12'), [ bf('-3.141592653589793'), bi('+12') ] ],
   [ bf('-3.141592653589793e+13'), [ bf('-3.141592653589793'), bi('+13') ] ],
   [ bf('-3.141592653589793e+14'), [ bf('-3.141592653589793'), bi('+14') ] ],
   [ bf('-3.141592653589793e+15'), [ bf('-3.141592653589793'), bi('+15') ] ],
   [ bf('-3.141592653589793e+16'), [ bf('-3.141592653589793'), bi('+16') ] ],
   [ bf('-3.141592653589793e+17'), [ bf('-3.141592653589793'), bi('+17') ] ],
   [ bf('-3.141592653589793e+18'), [ bf('-3.141592653589793'), bi('+18') ] ],
   [ bf('-3.141592653589793e+19'), [ bf('-3.141592653589793'), bi('+19') ] ],
   [ bf('-3.141592653589793e+20'), [ bf('-3.141592653589793'), bi('+20') ] ],

   [ bi('+3'),                     [ bf('+3'),                 bi('+0') ] ],
   [ bi('+31'),                    [ bf('+3.1'),               bi('+1') ] ],
   [ bi('+314'),                   [ bf('+3.14'),              bi('+2') ] ],
   [ bi('+3141'),                  [ bf('+3.141'),             bi('+3') ] ],
   [ bi('+31415'),                 [ bf('+3.1415'),            bi('+4') ] ],
   [ bi('+314159'),                [ bf('+3.14159'),           bi('+5') ] ],
   [ bi('+3141592'),               [ bf('+3.141592'),          bi('+6') ] ],
   [ bi('+31415926'),              [ bf('+3.1415926'),         bi('+7') ] ],
   [ bi('+314159265'),             [ bf('+3.14159265'),        bi('+8') ] ],
   [ bi('+3141592653'),            [ bf('+3.141592653'),       bi('+9') ] ],
   [ bi('+31415926535'),           [ bf('+3.1415926535'),      bi('+10') ] ],
   [ bi('+314159265358'),          [ bf('+3.14159265358'),     bi('+11') ] ],
   [ bi('+3141592653589'),         [ bf('+3.141592653589'),    bi('+12') ] ],
   [ bi('+31415926535897'),        [ bf('+3.1415926535897'),   bi('+13') ] ],
   [ bi('+314159265358979'),       [ bf('+3.14159265358979'),  bi('+14') ] ],
   [ bi('+3141592653589793'),      [ bf('+3.141592653589793'), bi('+15') ] ],
   [ bi('+31415926535897930'),     [ bf('+3.141592653589793'), bi('+16') ] ],
   [ bi('+314159265358979300'),    [ bf('+3.141592653589793'), bi('+17') ] ],
   [ bi('+3141592653589793000'),   [ bf('+3.141592653589793'), bi('+18') ] ],
   [ bi('+31415926535897930000'),  [ bf('+3.141592653589793'), bi('+19') ] ],
   [ bi('+314159265358979300000'), [ bf('+3.141592653589793'), bi('+20') ] ],

   [ bi('-3'),                     [ bf('-3'),                 bi('+0') ] ],
   [ bi('-31'),                    [ bf('-3.1'),               bi('+1') ] ],
   [ bi('-314'),                   [ bf('-3.14'),              bi('+2') ] ],
   [ bi('-3141'),                  [ bf('-3.141'),             bi('+3') ] ],
   [ bi('-31415'),                 [ bf('-3.1415'),            bi('+4') ] ],
   [ bi('-314159'),                [ bf('-3.14159'),           bi('+5') ] ],
   [ bi('-3141592'),               [ bf('-3.141592'),          bi('+6') ] ],
   [ bi('-31415926'),              [ bf('-3.1415926'),         bi('+7') ] ],
   [ bi('-314159265'),             [ bf('-3.14159265'),        bi('+8') ] ],
   [ bi('-3141592653'),            [ bf('-3.141592653'),       bi('+9') ] ],
   [ bi('-31415926535'),           [ bf('-3.1415926535'),      bi('+10') ] ],
   [ bi('-314159265358'),          [ bf('-3.14159265358'),     bi('+11') ] ],
   [ bi('-3141592653589'),         [ bf('-3.141592653589'),    bi('+12') ] ],
   [ bi('-31415926535897'),        [ bf('-3.1415926535897'),   bi('+13') ] ],
   [ bi('-314159265358979'),       [ bf('-3.14159265358979'),  bi('+14') ] ],
   [ bi('-3141592653589793'),      [ bf('-3.141592653589793'), bi('+15') ] ],
   [ bi('-31415926535897930'),     [ bf('-3.141592653589793'), bi('+16') ] ],
   [ bi('-314159265358979300'),    [ bf('-3.141592653589793'), bi('+17') ] ],
   [ bi('-3141592653589793000'),   [ bf('-3.141592653589793'), bi('+18') ] ],
   [ bi('-31415926535897930000'),  [ bf('-3.141592653589793'), bi('+19') ] ],
   [ bi('-314159265358979300000'), [ bf('-3.141592653589793'), bi('+20') ] ],

   [ bf('+0.1'), [ bf('+1'),   bi('-1') ] ],
   [ bf('+1'),   [ bf('+1'),   bi('+0') ] ],
   [ bf('+10'),  [ bf('+1'),   bi('+1') ] ],

   [ bf('-0.1'), [ bf('-1'),   bi('-1') ] ],
   [ bf('-1'),   [ bf('-1'),   bi('+0') ] ],
   [ bf('-10'),  [ bf('-1'),   bi('+1') ] ],

   [ bf('+0'),   [ bf('+0'),   bi('+0') ] ],

   [ bf('+inf'), [ bf('+inf'), bi('+inf') ] ],
   [ bf('-inf'), [ bf('-inf'), bi('+inf') ] ],
   [ bf('nan'),  [ bf('nan'),  bi('nan')  ] ],

   [ bi('+inf'), [ bf('+inf'), bi('+inf') ] ],
   [ bi('-inf'), [ bf('-inf'), bi('+inf') ] ],
   [ bi('nan'),  [ bi('nan'),  bi('nan')  ] ],

  );

print "1..242\n";

my $testno = 0;

### List context ###

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    ++ $testno;

    my $in                = $data[$i][0];
    my $out_expected_mant = $data[$i][1][0];
    my $out_expected_expo = $data[$i][1][1];

    #my $in_orig_val = $in -> copy();
    #my $in_orig_adr = Scalar::Util::refaddr($in);
    #my $in_orig_adr = overload::StrVal($in);

    # Get the actual output argument.

    my @out_actual = fparts($in);

    # First make sure that the input argument was unmodified.

    # xxx not implemented yet

    # Check the NUMBER of output arguments.

    my $noutargs = @out_actual;
    if ($noutargs != 2) {
        print "not ok ", $testno, "\n";
        print "  input ...: $in\n";
        print "  error ...: got $noutargs arg(s), expected 2\n";
        next;
    }

    # Check the DEFINEDNESS of the first output argument.

    unless (defined $out_actual[0]) {
        print "not ok ", $testno, "\n";
        print "  input ...: $in\n";
        print "  error ...: first output arg is undefined\n";
        next;
    }

    # Check the CLASS of the first output argument.

    if (ref($out_actual[0]) ne 'Math::BigFloat') {
        print "not ok ", $testno, "\n";
        print "  input ...: $in\n";
        print "  error ...: first output arg not a Math::BigFloat object\n";
        next;
    }

    # Check the VALUE of the first output argument.

    unless ($out_expected_mant -> is_nan() ?
            $out_actual[0] -> is_nan()   :
            $out_actual[0] == $out_expected_mant)
    {
        print "not ok ", $testno, "\n";
        print "  input ...............: $in\n";
        print "  output mantissa .....: $out_actual[0]\n";
        print "  expected mantissa ...: $out_expected_mant\n";
        next;
    }

    # Check the DEFINEDNESS of the second output argument.

    unless (defined $out_actual[1]) {
        print "not ok ", $testno, "\n";
        print "  input ...: $in\n";
        print "  error ...: second output arg is undefined\n";
        next;
    }

    # Check the CLASS of the second output argument.

    if (ref($out_actual[1]) ne 'Math::BigInt') {
        print "not ok ", $testno, "\n";
        print "  input ...: $in\n";
        print "  error ...: second output argument is not Math::BigInt object\n";
        next;
    }

    # Check the VALUE of the second output argument.

    unless ($out_expected_expo -> is_nan() ?
            $out_actual[1] -> is_nan()   :
            $out_actual[1] == $out_expected_expo)
    {
        print "not ok ", $testno, "\n";
        print "  input ...............: $in\n";
        print "  output exponent .....: $out_actual[1]\n";
        print "  expected exponent ...: $out_expected_expo\n";
        next;
    }

    print "ok ", $testno, "\n";
}

### Scalar context ###

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    ++ $testno;

    my $in                = $data[$i][0];
    my $out_expected_mant = $data[$i][1][0];

    # Get the actual output argument.

    my @out_actual;
    $out_actual[0] = fparts($in);

    # Check the DEFINEDNESS of the output argument.

    unless (defined $out_actual[0]) {
        print "not ok ", $testno, "\n";
        print "  input ...: $in\n";
        print "  error ...: first output arg is undefined\n";
        next;
    }

    # Check the CLASS of the output argument.

    if (ref($out_actual[0]) ne 'Math::BigFloat') {
        print "not ok ", $testno, "\n";
        print "  input ...: $in\n";
        print "  error ...: first output arg not a Math::BigFloat object\n";
        next;
    }

    # Check the VALUE of the output argument.

    unless ($out_expected_mant -> is_nan() ?
            $out_actual[0] -> is_nan()   :
            $out_actual[0] == $out_expected_mant)
    {
        print "not ok ", $testno, "\n";
        print "  input ...............: $in\n";
        print "  output mantissa .....: $out_actual[0]\n";
        print "  expected mantissa ...: $out_expected_mant\n";
        next;
    }

    print "ok ", $testno, "\n";
}

# Emacs Local Variables:
# Emacs coding: utf-8-unix
# Emacs mode: perl
# Emacs End:
