# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 57;

my @classes;

BEGIN {
    @classes = qw< Math::BigInt Math::BigRat Math::BigFloat >;
    for my $class (@classes) {
        use_ok($class);
    }
}

my $cases =
  [
   [ 0, "\x00" ],
   [ 255, "\xff" ],
   [ 10000, "\x27\x10" ],
   [ 51966, "\xCA\xFE" ],
   [ 3405691582, "\xCA\xFE\xBA\xBE" ],
   [ 3735928559, "\xDE\xAD\xBE\xEF" ],
  ];

for my $case (@$cases) {
    my ($in, $out) = @$case;

    for my $class (@classes) {

        # As class method with scalar input.

        {
            my $y;
            my $test = qq|\$y = $class -> to_bytes("$in");|;
            note("\n$test\n\n");

            eval $test;
            #die $@ if $@;           # this should never happen
            die "\nThe following test died when eval()'ed. This indicates a ",
              "broken test\n\n    $test\n\nThe error message was\n\n    $@\n"
              if $@;

            subtest $test, sub {
                plan tests => 2;

                is(ref($y), '', "output arg is a SCALAR");
                is($y, $out, 'output arg has the right value');
            };
        }

        # As class method with object input.

        {
            my ($x, $y);
            my $test = qq|\$x = $class -> new("$in");|
                     . qq| \$y = $class -> to_bytes(\$x);|;
            note("\n$test\n\n");

            eval $test;
            #die $@ if $@;           # this should never happen
            die "\nThe following test died when eval()'ed. This indicates a ",
              "broken test\n\n    $test\n\nThe error message was\n\n    $@\n"
              if $@;

            subtest $test, sub {
                plan tests => 2;

                is(ref($y), '', "output arg is a SCALAR");
                is($y, $out, 'output arg has the right value');
            };
        }

        # As instance method.

        {
            my ($x, $y);
            my $test = qq|\$x = $class -> new("$in");|
                     . qq| \$y = \$x -> to_bytes();|;
            note("\n$test\n\n");

            eval $test;
            #die $@ if $@;       # this should never happen
            die "\nThe following test died when eval()'ed. This indicates a ",
              "broken test\n\n    $test\n\nThe error message was\n\n    $@\n"
              if $@;

            subtest $test, sub {
                plan tests => 2;

                is(ref($y), '', "output arg is a SCALAR");
                is($y, $out, 'output arg has the right value');
            };
        }
    }
}
