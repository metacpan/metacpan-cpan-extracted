#!perl

# Each call allocates its own parser and its own copy of the input and frees
# both before returning, so there is no shared state for threads to fight
# over. This runs all three functions concurrently and checks that every
# thread gets the answer it would have got on its own.

use strict;
use warnings;

use Config;
use Test2::V0;

plan skip_all => 'this perl is not built with ithreads'
    unless $Config{useithreads};

require threads;

use HTTP::libsfparse qw( parse_item parse_list parse_dictionary );

# Parsing before the threads exist means the loaded extension is already
# warm, which is when a shared buffer would be most likely to show up.
is parse_item('1')->[1], 1, 'a parse in the parent first';

my @threads = map {
    my $n = $_;

    threads->create(
        sub {
            my $bad = 0;

            for ( 1 .. 200 ) {
                my $d = parse_dictionary("k$n=$n;p=2, other=\"x\"");
                $bad++ unless $d->[0][0] eq "k$n";
                $bad++ unless $d->[0][1][1] == $n;
                $bad++ unless $d->[0][1][2][0][1][1] == 2;
                $bad++ unless $d->[1][1][1] eq 'x';

                # An inner list exercises the recursive build as well.
                my $l = parse_list("(1 $n);p=2, b$n");
                $bad++ unless $l->[0][1][1][1] == $n;
                $bad++ unless $l->[1][1] eq "b$n";

                $bad++ unless parse_item("$n")->[1] == $n;

                # Malformed input has to fail in a thread too, and leave
                # nothing behind that the next parse would trip over.
                $bad++ if eval { parse_item('"unterminated'); 1 };
            }

            return $bad;
        }
    );
} 1 .. 4;

is [ map { $_->join } @threads ], [ 0, 0, 0, 0 ],
    'four threads parsed concurrently with no interference';

is parse_item('2')->[1], 2, 'and the parent still parses afterwards';

done_testing;
