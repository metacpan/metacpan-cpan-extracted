# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 701;

my $class;

BEGIN { $class = 'Math::BigFloat'; }
BEGIN { use_ok($class); }

my @data;
my $space = "\t\r\n ";

while (<DATA>) {
    s/#.*$//;           # remove comments
    s/\s+$//;           # remove trailing whitespace
    next unless length; # skip empty lines

    my ($in0, $out0) = split /:/;

    push @data, [ $in0, $out0 ],
                [ $in0 . $space, $out0 ],
                [ $space . $in0, $out0 ],
                [ $space . $in0 . $space, $out0 ];
}

for my $entry (@data) {
    my ($in0, $out0) = @$entry;

    # As class method.

    {
        my $x;
        my $test = qq|\$x = $class -> from_dec("$in0");|;

        eval $test;
        die $@ if $@;           # this should never happen

        subtest $test, sub {
            plan tests => 2,

            is(ref($x), $class, "output arg is a $class");
            is($x, $out0, 'output arg has the right value');
        };
    }

    # As instance method.

    {
        for my $str ("-1", "0", "1", "-inf", "+inf", "NaN") {
            my $x;
            my $test = qq|\$x = $class -> new("$str");|
                     . qq| \$x -> from_dec("$in0");|;

            eval $test;
            die $@ if $@;       # this should never happen

            subtest $test, sub {
                plan tests => 2,

                is(ref($x), $class, "output arg is a $class");
                is($x, $out0, 'output arg has the right value');
            };
        }
    }
}

__END__

# invalid input

NaN:NaN
+inf:NaN
-inf:NaN

0xff:NaN
0o377:NaN
0b11:NaN

# integers

0:0
-1:-1
+1:1
1:1
-10:-10
10:10
-314159:-314159
314159:314159
-314159.:-314159
314159.:314159
-314159.000:-314159
314159.000:314159
3.14159e+5:314159
31415900e-2:314159

0377:377

# finite non-integers

-314159.5:-314159.5
314159.5:314159.5

314159.5:314159.5
314.159e-2:3.14159
