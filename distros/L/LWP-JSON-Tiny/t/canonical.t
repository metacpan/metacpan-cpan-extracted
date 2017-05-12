#!/usr/bin/env perl
# Tests for overriding canonical => 1 (i.e. sorting JSON)

use strict;
use warnings;
no warnings 'uninitialized';

use Test::Fatal;
use Test::More;

use HTTP::Request::JSON;

# Would normally use the package Foo { ... } syntax here, but need to
# support older Perls.

package LWP::JSON::Tiny::Random;

    use parent 'LWP::JSON::Tiny';
    sub default_json_arguments {
        return (shift->SUPER::default_json_arguments, canonical => 0);
    }

package HTTP::Request::JSON::Random;

    use parent 'HTTP::Request::JSON';
    sub json_object {
        LWP::JSON::Tiny::Random->json_object;
    }

package main;

# Right. We expect e.g.
# { 1 => 1, 2 => 2, 3 => 3, 4=> 4 }
# to be turned into
# {"1":1,"2":2,"3":3,"4":4}
# when we sort ("canonical" is the JSON term for this).
# So build up a mapping.
# We'll test this a number of times to cope with Perl hash key ordering
# being basically random. When sorting, we should always find a match;
# when not sorting, we should find a failure at least once.
# 9 is enough to (a) be pretty confident that this wasn't just a fluke,
# but (b) not be so much we need to care about human vs asciibetical sorting.

my $MAX_ELEMENTS = 9;
my (%request, %response_sorted);
for my $num_elements (1..$MAX_ELEMENTS) {
    $request{$num_elements} = { map { $_ => $_ } 1 .. $num_elements };
    $response_sorted{$num_elements}
        = '{'
        . join(',', map { sprintf(qq{"%d":%d}, $_, $_) } 1 .. $num_elements)
        . '}';
}

default_sorts();
subclass_doesnt_always_sort();

sub default_sorts {
    my $request = HTTP::Request::JSON->new;

    for my $num_elements (1 .. $MAX_ELEMENTS) {
        is(
            $request->json_content($request{$num_elements}),
            $response_sorted{$num_elements},
            "JSON with $num_elements elements is sorted"
        );
    }
}

sub subclass_doesnt_always_sort {
    my $request = HTTP::Request::JSON::Random->new;

    my $had_failure;
    for my $num_elements (1 .. $MAX_ELEMENTS) {
        if ($request->json_content($request{$num_elements})
            ne $response_sorted{$num_elements})
        {
            $had_failure++;
        }
    }
    ok($had_failure,
        q{At least one attempt at generating JSON}
      . q{ in Perl key order wasn't sorted}
    );
}

Test::More::done_testing();

