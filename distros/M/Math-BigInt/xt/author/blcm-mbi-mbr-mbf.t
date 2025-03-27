# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 299;
use Scalar::Util qw< refaddr >;

my @classes;

BEGIN {
    @classes = qw< Math::BigInt Math::BigRat Math::BigFloat >;
    for my $class (@classes) {
        use_ok($class);
    }
}

my %cases =
  (

   # Common test cases for Math::BigInt, Math::BigRat, and Math::BigFloat.

   'common' =>
   [
    ['NaN', 'NaN', 'NaN'],
    ['inf', 'NaN', 'NaN'],
    ['NaN', 'inf', 'NaN'],

    ['0',  'NaN', 'NaN'],
    ['0',  'inf', 'NaN'],
    ['0', '-inf', 'NaN'],

    ['1',  'NaN', 'NaN'],
    ['1',  'inf', 'NaN'],
    ['1', '-inf', 'NaN'],

    ['-4',  '0', '0'],
    [ '0', '-4', '0'],
    ['-1',  '0', '0'],
    [ '0', '-1', '0'],
    [ '0',  '0', '0'],
    [ '1',  '0', '0'],
    [ '0',  '1', '0'],
    [ '4',  '0', '0'],
    [ '0',  '4', '0'],

    ['-6', '-4', '12'],
    ['-6',  '4', '12'],
    [ '4', '-6', '12'],
    [ '4',  '6', '12'],
   ],

   # Test cases for Math::BigInt only.

   'Math::BigInt' =>
   [
    ['0.8', '1.2', 'NaN'],
    ['1.2', '0.8', 'NaN'],
    [  '0', '0.8', 'NaN'],
    ['1.2',   '0', 'NaN'],
   ],

   # For Math::BigRat only:

   'Math::BigRat' =>
   [
    ['4/5', '6/5', '12/5'],
    ['6/5', '4/5', '12/5'],
   ],

   # For Math::BigFloat only:

   'Math::BigFloat' =>
   [
    ['0.8', '1.2', '2.4'],
    ['1.2', '0.8', '2.4'],
   ],
  );

for my $class (@classes) {

    my @cases = (@{ $cases{common} },  # common test cases
                 @{ $cases{$class} }); # class-specific test cases

    for my $case (@cases) {
        my ($in0, $in1, $out0) = @$case;

        # As class method.

        {
            my ($x, $z);
            my $test = qq|\$z = $class -> blcm("$in0", "$in1");|;

            note("\n$test\n\n");

            eval $test;
            die $@ if $@;       # this should never happen

            subtest $test, sub {
                is(ref($z), $class, "output arg is a $class");
                is($z, $out0, 'output arg has the right value');
            };
        }

        # As instance method.

        {
            my ($x, $y, $z);
            my $test = qq|\$x = $class -> new("$in0");|
              . qq| \$y = $class -> new("$in1");|
              . qq| \$z = \$x -> blcm(\$y);|;

            note("\n$test\n\n");

            eval $test;
            die $@ if $@;       # this should never happen

            subtest $test, sub {
                is(ref($z), $class, "output arg is a $class");
                is($z, $out0, 'output arg has the right value');
                is($x, $in0, 'first operand is unmodified')
                  unless $class eq "Math::BigInt" && $in0 =~ m|[./]|;
                is($y, $in1, 'second operand is unmodified')
                  unless $class eq "Math::BigInt" && $in1 =~ m|[./]|;
                isnt(refaddr($z), refaddr($x),
                     'output arg is not the first operand');
                isnt(refaddr($z), refaddr($y),
                     'output arg is not the second operand');
            };
        }

        # As function.
        #
        # For some reason, the original author decided that bgcd() and blcm()
        # should support being used functions, not methods. In addition, if
        # used as instance methods, they should not modify their invocand. This
        # is inconsistent with all other bxxx() methods, but there we are.

        {
            my ($x, $y, $z);
            my $test = qq|\$x = $class -> new("$in0");|
              . qq| \$y = $class -> new("$in1");|
              . qq| \$z = ${class}::blcm(\$x, \$y);|;

            note("\n$test\n\n");

            eval $test;
            die $@ if $@;       # this should never happen

            subtest $test, sub {
                is(ref($z), $class, "output arg is a $class");
                is($z, $out0, 'output arg has the right value');
                is($x, $in0, 'first operand is unmodified')
                  unless $class eq "Math::BigInt" && $in0 =~ m|[./]|;
                is($y, $in1, 'second operand is unmodified')
                  unless $class eq "Math::BigInt" && $in1 =~ m|[./]|;
                isnt(refaddr($z), refaddr($x),
                     'output arg is not the first operand');
                isnt(refaddr($z), refaddr($y),
                     'output arg is not the second operand');
            };
        }

        {
            my $z;
            my $test = qq|\$z = ${class}::blcm("$in0", "$in1");|;

            eval $test;
            die $@ if $@;       # this should never happen

            subtest $test, sub {
                is(ref($z), $class, "output arg is a $class");
                is($z, $out0, 'output arg has the right value');
            };
        }

    }
}
