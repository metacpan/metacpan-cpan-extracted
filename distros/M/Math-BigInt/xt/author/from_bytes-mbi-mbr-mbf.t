# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 39;

my @classes;

BEGIN {
    @classes = qw< Math::BigInt Math::BigRat Math::BigFloat >;
    for my $class (@classes) {
        use_ok($class);
    }
}

my $cases =
  [
   [ "\\x00", 0 ],
   [ "\\xff", 255 ],
   [ "\\x27\\x10", 10000 ],
   [ "\\xCA\\xFE", 51966 ],
   [ "\\xCA\\xFE\\xBA\\xBE", 3405691582 ],
   [ "\\xDE\\xAD\\xBE\\xEF", 3735928559 ],
  ];

for my $case (@$cases) {
    my ($in, $out) = @$case;

    for my $class (@classes) {

        # As class method.

        {
            my $x;
            my $test = qq|\$x = $class -> from_bytes("$in")|;
            note("\n$test\n\n");

            eval $test;
            #die $@ if $@;           # this should never happen
            die "\nThe following test died when eval()'ed. This indicates a ",
              "broken test\n\n    $test\n\nThe error message was\n\n    $@\n"
              if $@;

            subtest $test, sub {
                plan tests => 2;

                is(ref($x), $class, "output arg is a $class");
                is($x, $out, 'output arg has the right value');
            };
        }

        # As instance method.

        {
            my $x;
            my $test = qq|\$x = $class -> bnan(); \$x -> from_bytes("$in")|;
            note("\n$test\n\n");

            eval $test;
            #die $@ if $@;       # this should never happen
            die "\nThe following test died when eval()'ed. This indicates a ",
              "broken test\n\n    $test\n\nThe error message was\n\n    $@\n"
              if $@;

            subtest $test, sub {
                plan tests => 2;

                is(ref($x), $class, "output arg is a $class");
                is($x, $out, 'output arg has the right value');
            };
        }
    }
}
