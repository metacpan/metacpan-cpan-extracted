#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep qw(cmp_details deep_diag bag);
use Test::Exception;
use Elastic::Model::SearchBuilder;

my $a = Elastic::Model::SearchBuilder->new;

test_queries(
    "TOP-LEVEL",

    "Query",
    \{ term => { foo => 1 } },
    { term  => { foo => 1 } },

    "Filter",
    { -filter => \{ term => { foo => 1 } } },
    { constant_score => { filter => { term => { foo => 1 } } } },

    "Filter Query",
    {   foo     => 1,
        -filter => { bar => 2, -query => \{ term => { baz => 3 } } }
    },
    {   filtered => {
            query  => { match => { foo => 1 } },
            filter => {
                and => [
                    { query => { term => { baz => 3 } } },
                    { term  => { bar  => 2 } }
                ]
            }
        }
    },

    "OR",
    { -filter => [ foo => 1, \{ term => { bar => 2 } } ] },
    {   constant_score => {
            filter => {
                or => [ { term => { foo => 1 } }, { term => { bar => 2 } } ]
            }
        }
    },

    "AND",
    { -filter => { -and => [ foo => 1, \{ term => { bar => 2 } } ] } },
    {   constant_score => {
            filter => {
                and => [ { term => { foo => 1 } }, { term => { bar => 2 } } ]
            }
        }
    }

);

done_testing;

#===================================
sub test_queries {
#===================================
    note "\n" . shift();
    while (@_) {
        my $name = shift;
        my $in   = shift;
        my $out  = shift;
        if ( ref $out eq 'Regexp' ) {
            throws_ok { $a->query($in) } $out, $name;
            next;
        }

        my $got = $a->query($in);
        my $expect = { query => $out };
        my ( $ok, $stack ) = cmp_details( $got, $expect );

        if ($ok) {
            pass $name;
            next;
        }

        fail($name);

        note("Got:");
        note( pp($got) );
        note("Expected:");
        note( pp($expect) );

        diag( deep_diag($stack) );

    }
}
