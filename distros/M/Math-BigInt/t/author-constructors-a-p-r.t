#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for testing by the author";
        exit;
    }
}

# Test how accuracy and precision are set in the constructors. All of the
# constructors need to be tested:
#
#     new(), bzero(), bone(), binf(), bnan(), bpi(), and the from_*() methods.

use strict;
use warnings;

use Test::More tests => 160;

use Math::BigInt;
use Math::BigFloat;

my $classes =
  [
   'Math::BigInt',
   'Math::BigFloat',
  ];

# Each line in the table constains three elements. One with the class
# variables, one with the arguments to the constructor, and one with the
# resulting instance variables.

my $table1 =
  [

   [
    'new',
    [
     [{a =>  4, r => 'even'}, [                           ], [     0,     4, undef, 'even']],

     [{a =>  4, r => 'even'}, [     5,                    ], [     5,     4, undef, 'even']],
#     [{a =>  4, r => 'even'}, [     5, undef              ], [     5, undef, undef, 'even']],
     [{a =>  4, r => 'even'}, [     5, undef,    -3       ], [     5, undef,    -3, 'even']],
     [{a =>  4, r => 'even'}, [     5, undef,    -3, 'odd'], [     5, undef,    -3,  'odd']],
     [{a =>  4, r => 'even'}, [     5, undef, undef       ], [     5, undef, undef, 'even']],
     [{a =>  4, r => 'even'}, [     5, undef, undef, 'odd'], [     5, undef, undef,  'odd']],

     [{p => -3, r => 'even'}, [     5,                    ], [     5, undef,    -3, 'even']],
     [{p => -3, r => 'even'}, [     5,     4,             ], [     5,     4, undef, 'even']],
     [{p => -3, r => 'even'}, [     5,     4, undef       ], [     5,     4, undef, 'even']],
     [{p => -3, r => 'even'}, [     5,     4, undef, 'odd'], [     5,     4, undef,  'odd']],
     [{p => -3, r => 'even'}, [     5, undef, undef       ], [     5, undef, undef, 'even']],
     [{p => -3, r => 'even'}, [     5, undef, undef, 'odd'], [     5, undef, undef,  'odd']],

#     [{a =>  4, r => 'even'}, [ 'NaN',                    ], [ 'NaN',     4, undef, 'even']],
#     [{a =>  4, r => 'even'}, [ 'NaN', undef              ], [ 'NaN', undef, undef,  undef]],
#     [{a =>  4, r => 'even'}, [ 'NaN', undef,    -3       ], [ 'NaN', undef,    -3,  undef]],
#     [{a =>  4, r => 'even'}, [ 'NaN', undef,    -3, 'odd'], [ 'NaN', undef,    -3,  undef]],
#     [{a =>  4, r => 'even'}, [ 'NaN', undef, undef       ], [ 'NaN', undef, undef,  undef]],
#     [{a =>  4, r => 'even'}, [ 'NaN', undef, undef, 'odd'], [ 'NaN', undef, undef,  undef]],

     [{p => -3, r => 'even'}, [ 'NaN',                    ], [ 'NaN', undef,    -3,  undef]],
#     [{p => -3, r => 'even'}, [ 'NaN',     4,             ], [ 'NaN',     4, undef,  undef]],
#     [{p => -3, r => 'even'}, [ 'NaN',     4, undef       ], [ 'NaN',     4, undef,  undef]],
#     [{p => -3, r => 'even'}, [ 'NaN',     4, undef, 'odd'], [ 'NaN',     4, undef,  undef]],
#     [{p => -3, r => 'even'}, [ 'NaN', undef, undef       ], [ 'NaN', undef, undef,  undef]],
#     [{p => -3, r => 'even'}, [ 'NaN', undef, undef, 'odd'], [ 'NaN', undef, undef,  undef]],

#     [{a =>  4, r => 'even'}, [ '+inf',                    ], [ 'inf',     4, undef, 'even']],
#     [{a =>  4, r => 'even'}, [ '+inf', undef              ], [ 'inf', undef, undef,  undef]],
#     [{a =>  4, r => 'even'}, [ '+inf', undef,    -3       ], [ 'inf', undef,    -3,  undef]],
#     [{a =>  4, r => 'even'}, [ '+inf', undef,    -3, 'odd'], [ 'inf', undef,    -3,  undef]],
#     [{a =>  4, r => 'even'}, [ '+inf', undef, undef       ], [ 'inf', undef, undef,  undef]],
#     [{a =>  4, r => 'even'}, [ '+inf', undef, undef, 'odd'], [ 'inf', undef, undef,  undef]],

#     [{p => -3, r => 'even'}, [ '+inf',                    ], [ 'inf', undef,    -3,  undef]],
#     [{p => -3, r => 'even'}, [ '+inf',     4,             ], [ 'inf',     4, undef,  undef]],
#     [{p => -3, r => 'even'}, [ '+inf',     4, undef       ], [ 'inf',     4, undef,  undef]],
#     [{p => -3, r => 'even'}, [ '+inf',     4, undef, 'odd'], [ 'inf',     4, undef,  undef]],
#     [{p => -3, r => 'even'}, [ '+inf', undef, undef       ], [ 'inf', undef, undef,  undef]],
#     [{p => -3, r => 'even'}, [ '+inf', undef, undef, 'odd'], [ 'inf', undef, undef,  undef]],

#     [{a =>  4, r => 'even'}, [ '-inf',                    ], [ '-inf',     4, undef, 'even']],
#     [{a =>  4, r => 'even'}, [ '-inf', undef              ], [ '-inf', undef, undef,  undef]],
#     [{a =>  4, r => 'even'}, [ '-inf', undef,    -3       ], [ '-inf', undef,    -3,  undef]],
#     [{a =>  4, r => 'even'}, [ '-inf', undef,    -3, 'odd'], [ '-inf', undef,    -3,  undef]],
#     [{a =>  4, r => 'even'}, [ '-inf', undef, undef       ], [ '-inf', undef, undef,  undef]],
#     [{a =>  4, r => 'even'}, [ '-inf', undef, undef, 'odd'], [ '-inf', undef, undef,  undef]],

#     [{p => -3, r => 'even'}, [ '-inf',                    ], [ '-inf', undef,    -3,  undef]],
#     [{p => -3, r => 'even'}, [ '-inf',     4,             ], [ '-inf',     4, undef,  undef]],
#     [{p => -3, r => 'even'}, [ '-inf',     4, undef       ], [ '-inf',     4, undef,  undef]],
#     [{p => -3, r => 'even'}, [ '-inf',     4, undef, 'odd'], [ '-inf',     4, undef,  undef]],
#     [{p => -3, r => 'even'}, [ '-inf', undef, undef       ], [ '-inf', undef, undef,  undef]],
#     [{p => -3, r => 'even'}, [ '-inf', undef, undef, 'odd'], [ '-inf', undef, undef,  undef]],

    ]
   ],

   [
    'bzero',
    [

     [{a =>  4, r => 'even'}, [                   ], [0,     4, undef, 'even']],
     [{a =>  4, r => 'even'}, [undef              ], [0, undef, undef, 'even']],
     [{a =>  4, r => 'even'}, [undef,    -3       ], [0, undef,    -3, 'even']],
     [{a =>  4, r => 'even'}, [undef,    -3, 'odd'], [0, undef,    -3,  'odd']],
     [{a =>  4, r => 'even'}, [undef, undef       ], [0, undef, undef, 'even']],
     [{a =>  4, r => 'even'}, [undef, undef, 'odd'], [0, undef, undef,  'odd']],

     [{p => -3, r => 'even'}, [                   ], [0, undef,    -3, 'even']],
     [{p => -3, r => 'even'}, [    4,             ], [0,     4, undef, 'even']],
     [{p => -3, r => 'even'}, [    4, undef       ], [0,     4, undef, 'even']],
     [{p => -3, r => 'even'}, [    4, undef, 'odd'], [0,     4, undef,  'odd']],
     [{p => -3, r => 'even'}, [undef, undef       ], [0, undef, undef, 'even']],
     [{p => -3, r => 'even'}, [undef, undef, 'odd'], [0, undef, undef,  'odd']],

    ],
   ],

   [
    'bone',
    [

     [{a =>  4, r => 'even'}, [                        ], [ 1,     4, undef, 'even']],
     [{a =>  4, r => 'even'}, ['+',                    ], [ 1,     4, undef, 'even']],
     [{a =>  4, r => 'even'}, ['+', undef              ], [ 1, undef, undef, 'even']],
     [{a =>  4, r => 'even'}, ['+', undef,    -3       ], [ 1, undef,    -3, 'even']],
     [{a =>  4, r => 'even'}, ['+', undef,    -3, 'odd'], [ 1, undef,    -3,  'odd']],
     [{a =>  4, r => 'even'}, ['+', undef, undef       ], [ 1, undef, undef, 'even']],
     [{a =>  4, r => 'even'}, ['+', undef, undef, 'odd'], [ 1, undef, undef,  'odd']],

     [{p => -3, r => 'even'}, [                        ], [ 1, undef,    -3, 'even']],
     [{p => -3, r => 'even'}, ['+',                    ], [ 1, undef,    -3, 'even']],
     [{p => -3, r => 'even'}, ['+',     4,             ], [ 1,     4, undef, 'even']],
     [{p => -3, r => 'even'}, ['+',     4, undef       ], [ 1,     4, undef, 'even']],
     [{p => -3, r => 'even'}, ['+',     4, undef, 'odd'], [ 1,     4, undef,  'odd']],
     [{p => -3, r => 'even'}, ['+', undef, undef       ], [ 1, undef, undef, 'even']],
     [{p => -3, r => 'even'}, ['+', undef, undef, 'odd'], [ 1, undef, undef,  'odd']],

     [{a =>  4, r => 'even'}, ['-',                    ], [-1,     4, undef, 'even']],
     [{a =>  4, r => 'even'}, ['-', undef              ], [-1, undef, undef, 'even']],
     [{a =>  4, r => 'even'}, ['-', undef,    -3       ], [-1, undef,    -3, 'even']],
     [{a =>  4, r => 'even'}, ['-', undef,    -3, 'odd'], [-1, undef,    -3,  'odd']],
     [{a =>  4, r => 'even'}, ['-', undef, undef       ], [-1, undef, undef, 'even']],
     [{a =>  4, r => 'even'}, ['-', undef, undef, 'odd'], [-1, undef, undef,  'odd']],

     [{p => -3, r => 'even'}, ['-',                    ], [-1, undef,    -3, 'even']],
     [{p => -3, r => 'even'}, ['-',     4,             ], [-1,     4, undef, 'even']],
     [{p => -3, r => 'even'}, ['-',     4, undef       ], [-1,     4, undef, 'even']],
     [{p => -3, r => 'even'}, ['-',     4, undef, 'odd'], [-1,     4, undef,  'odd']],
     [{p => -3, r => 'even'}, ['-', undef, undef       ], [-1, undef, undef, 'even']],
     [{p => -3, r => 'even'}, ['-', undef, undef, 'odd'], [-1, undef, undef,  'odd']],

    ],
   ],

   [
    'binf',
    [

     [{a =>  4, r => 'even'}, [                        ], [ 'inf',     4, undef, 'even']],
     [{a =>  4, r => 'even'}, ['+',                    ], [ 'inf',     4, undef, 'even']],
     [{a =>  4, r => 'even'}, ['+', undef              ], [ 'inf', undef, undef, 'even']],
     [{a =>  4, r => 'even'}, ['+', undef,    -3       ], [ 'inf', undef,    -3, 'even']],
     [{a =>  4, r => 'even'}, ['+', undef,    -3, 'odd'], [ 'inf', undef,    -3,  'odd']],
     [{a =>  4, r => 'even'}, ['+', undef, undef       ], [ 'inf', undef, undef, 'even']],
     [{a =>  4, r => 'even'}, ['+', undef, undef, 'odd'], [ 'inf', undef, undef,  'odd']],

     [{p => -3, r => 'even'}, [                        ], [ 'inf', undef,    -3, 'even']],
     [{p => -3, r => 'even'}, ['+',                    ], [ 'inf', undef,    -3, 'even']],
     [{p => -3, r => 'even'}, ['+',     4,             ], [ 'inf',     4, undef, 'even']],
     [{p => -3, r => 'even'}, ['+',     4, undef       ], [ 'inf',     4, undef, 'even']],
     [{p => -3, r => 'even'}, ['+',     4, undef, 'odd'], [ 'inf',     4, undef,  'odd']],
     [{p => -3, r => 'even'}, ['+', undef, undef       ], [ 'inf', undef, undef, 'even']],
     [{p => -3, r => 'even'}, ['+', undef, undef, 'odd'], [ 'inf', undef, undef,  'odd']],

     [{a =>  4, r => 'even'}, ['-',                    ], ['-inf',     4, undef, 'even']],
     [{a =>  4, r => 'even'}, ['-', undef              ], ['-inf', undef, undef, 'even']],
     [{a =>  4, r => 'even'}, ['-', undef,    -3       ], ['-inf', undef,    -3, 'even']],
     [{a =>  4, r => 'even'}, ['-', undef,    -3, 'odd'], ['-inf', undef,    -3,  'odd']],
     [{a =>  4, r => 'even'}, ['-', undef, undef       ], ['-inf', undef, undef, 'even']],
     [{a =>  4, r => 'even'}, ['-', undef, undef, 'odd'], ['-inf', undef, undef,  'odd']],

     [{p => -3, r => 'even'}, ['-',                    ], ['-inf', undef,    -3, 'even']],
     [{p => -3, r => 'even'}, ['-',     4,             ], ['-inf',     4, undef, 'even']],
     [{p => -3, r => 'even'}, ['-',     4, undef       ], ['-inf',     4, undef, 'even']],
     [{p => -3, r => 'even'}, ['-',     4, undef, 'odd'], ['-inf',     4, undef,  'odd']],
     [{p => -3, r => 'even'}, ['-', undef, undef       ], ['-inf', undef, undef, 'even']],
     [{p => -3, r => 'even'}, ['-', undef, undef, 'odd'], ['-inf', undef, undef,  'odd']],

    ],
   ],

   #   [
   #    'bnan',
   #    [
   #
   #     [{a =>  4, r => 'even'}, [                   ], ['NaN',     4, undef, 'even']],
   #     [{a =>  4, r => 'even'}, [undef              ], ['NaN', undef, undef, 'even']],
   #     [{a =>  4, r => 'even'}, [undef,    -3       ], ['NaN', undef,    -3, 'even']],
   #     [{a =>  4, r => 'even'}, [undef,    -3, 'odd'], ['NaN', undef,    -3,  'odd']],
   #     [{a =>  4, r => 'even'}, [undef, undef       ], ['NaN', undef, undef, 'even']],
   #     [{a =>  4, r => 'even'}, [undef, undef, 'odd'], ['NaN', undef, undef,  'odd']],
   #
   #     [{p => -3, r => 'even'}, [                   ], ['NaN', undef,    -3, 'even']],
   #     [{p => -3, r => 'even'}, [    4,             ], ['NaN',     4, undef, 'even']],
   #     [{p => -3, r => 'even'}, [    4, undef       ], ['NaN',     4, undef, 'even']],
   #     [{p => -3, r => 'even'}, [    4, undef, 'odd'], ['NaN',     4, undef,  'odd']],
   #     [{p => -3, r => 'even'}, [undef, undef       ], ['NaN', undef, undef, 'even']],
   #     [{p => -3, r => 'even'}, [undef, undef, 'odd'], ['NaN', undef, undef,  'odd']],
   #
   #    ],
   #   ],

  ];

my $table2 =
  [
#   qq|new(0, 4, -3);|,
#   qq|new(5, 4, -3);|,
#   qq|new("+inf", 4, -3);|,
#   qq|new("-inf", 4, -3);|,
#   qq|new("NaN", 4, -3);|,

   qq|bzero(4, -3);|,

   qq|bone("+", 4, -3);|,
   qq|bone("-", 4, -3);|,

#   qq|binf("+", 4, -3);|,
#   qq|binf("-", 4, -3);|,

#   qq|bnan(4, -3);|,
  ];

sub arg2str {
    my $arg = shift;
    return "undef" unless defined $arg; # undefined
    return $arg if $arg =~ /\d/;        # number
    return qq|"$arg"|;                  # string
}

for my $class (@$classes) {

    for my $entry (@$table1) {
        my $method = $entry -> [0];
        my $table  = $entry -> [1];
        for my $line (@$table) {

            # class variables, constructor arguments, and instance variables
            my ($cvars, $cargs, $ivars) = @$line;

            my $test = '';
            $test .= "$class -> accuracy("    . arg2str($cvars -> {a}) . ");"
              if exists $cvars -> {a};
            $test .= " $class -> precision("  . arg2str($cvars -> {p}) . ");"
              if exists $cvars -> {p};
            #$test .= " $class -> round_mode(" . arg2str($cvars -> {r}) . ");"
            #  if exists $cvars -> {r};
            $test .= " \$x = $class->$method(";
            $test .= join ", ", map arg2str($_), @$cargs;
            $test .= ");";

            my $x;
            eval $test;
            die $@ if $@;       # this should never happen

            subtest $test => sub {
                plan tests => 3;

                is($x -> bdstr(),      $ivars -> [0], '$x -> bdstr()');
                #is($x -> accuracy(),   $ivars -> [1], '$x -> accuracy()');
                is($x -> {_a},         $ivars -> [1], '$x -> {_a}');
                #is($x -> precision(),  $ivars -> [2], '$x -> precision()');
                is($x -> {_p},         $ivars -> [2], '$x -> {_p}');
                #is($x -> round_mode(), $ivars -> [3], '$x -> round_mode()');
                #is($x -> {_r},         $ivars -> [3], '$x -> {_r}');
            };
        }
    }

    # Setting both the accuracy and the precision to defined values is an
    # error.

    for my $entry (@$table2) {
        my $test = $class . " -> " . $entry;
        eval $test;
        like($@, qr/specify both accuracy and precision/, $test);
    }
}
