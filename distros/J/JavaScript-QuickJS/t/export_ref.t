#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;
use Data::Dumper;
use Config;

use Types::Serialiser;

use JavaScript::QuickJS;

{
    my $js = JavaScript::QuickJS->new();
    $js->set_globals( foo => sub { } );
}

{
    my $ret;

    {
        my $js = JavaScript::QuickJS->new()->set_globals(
            __return => sub { $ret = shift; () },
        );

        $js->eval('__return( function add1(a) { return 1 + a } )');

        $js->set_globals( __return => undef );
    }

    is(
        $ret->(1),
        2,
        'add1 called without QuickJS instance',
    );

    undef $ret;
}

{
    my $js = JavaScript::QuickJS->new();

    my $struct = $js->eval('[[[]]]');

    is_deeply($struct, [[[]]], 'nested arrays');

    my $gives_deep = $js->eval('a => [[[a]]]');
    my $got = $gives_deep->([]);
    is_deeply($got, [[[[]]]], 'nested arrays from funcref') or diag explain $got;
}

{
    my $ret;

    JavaScript::QuickJS->new()->set_globals(
        __return => sub { $ret = shift; () },
    )->eval(qq/
        __return( {
            add1: a => 1 + a,
            deepen: a => [a],
        } );
    /);

    my @to_deepen = (
        123,
        [],
        [123],
        {},
        { foo => 234 },
    );

    for my $specimen (@to_deepen) {
        my $out = $ret->{'deepen'}->($specimen);

        my $render = do {
            local $Data::Dumper::Terse = 1;
            local $Data::Dumper::Indent = 0;
            Data::Dumper::Dumper($specimen);
        };

        cmp_deeply( $out, [$specimen], "deepen: $render" ) or diag explain $out;
    }

    undef $ret;
}

done_testing;
