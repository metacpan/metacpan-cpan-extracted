#!/usr/bin/perl
#
# Author:      Peter J. Acklam
# Time-stamp:  2010-02-20 00:01:05 +01:00
# E-mail:      pjacklam@cpan.org
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

use Math::BigInt::Random::OO;

use Math::BigInt;
use Math::BigFloat;

print "1..70\n";

my $class = 'Math::BigInt::Random::OO';

########################

# bigint2str BIGINT, BASE
#
# Converts a non-negative bigint to a string in the given base,
# where 2 <= BASE <= 36.

sub bigint2str {
    my $name = 'bigint2str';
    my $bint = $_[0];   # clones the input
    my $base = $_[1];

    # Check the base.

    die "$name: the base must be defined"
      unless defined $base;
    die "$name: the base must be an integer"
      unless $base == int $base;
    die "$name: the base must be in the range 2..36, inclusive"
      if $base < 2 || $base > 36;

    # Check the bigint.

    die "$name: the bigint must be defined"
      unless defined $bint;
    die "$name: the bigint must be a Math::BigInt object"
      unless UNIVERSAL::isa($bint, 'Math::BigInt');
    die "$name: the bigint must be non-negative"
      if $bint < 0;

    # Quick exit when the bigint is zero.

    if ($bint == 0) {
        return '0';
    }

    # Set of symbols for each digit.

    my $symset = '0123456789abcdefghijklmnopqrstuvwxyz';

    # Convert the bigint to a string.

    my $str = '';
    while ($bint > 0) {
        my $num = $bint % $base;
        my $sym = substr $symset, $num, 1;
        $str = $sym . $str;
        $bint /= $base;
    }

    return $str;
}

########################

my $testno = 0;

for my $base (2, 4, 8, 10, 16, 25, 36) {
    for my $len (5, 10, 20, 50, 100) {
       TEST: for my $num (1, 50) {

            ++ $testno;

            my $test = "\@x = $class -> new(length => $len, " .
                                           "base => $base) -> generate($num)";

            my @x = $class -> new(length => $len, base => $base)
                           -> generate($num);

            # Check the number of output arguments.

            unless (@x == $num) {
                print "not ok ", $testno, " - $test\n";
                print "  wrong number of output arguments\n";
                print "  actual number .........: ", scalar(@x), "\n";
                print "  expected number .......: $num\n";
                next TEST;
            }

            # Check each output argument.

            for my $x (@x) {

                unless (defined $x) {
                    print "not ok ", $testno, " - $test\n";
                    print "  array element was undefined\n";
                    next TEST;
                }

                my $refx = ref $x;
                unless ($refx eq 'Math::BigInt') {
                    print "not ok ", $testno, " - $test\n";
                    print "  array element was a ",
                              $refx ? $refx : "Perl scalar",
                              ", expected a Math::BigInt\n";
                    next TEST;
                }

                my $str = bigint2str $x, $base;
                my $strlen = length $str;

                unless ($strlen == $len) {
                    print "not ok ", $testno, " - $test\n";
                    print "  output length is incorrect\n";
                    print "  actual length .....: $strlen\n";
                    print "  expected length ...: $len\n";
                    next TEST;
                }

            }

            print "ok ", $testno, " - $test\n";
        }
    }
}

# Emacs Local Variables:
# Emacs coding: utf-8-unix
# Emacs mode: perl
# Emacs End:
