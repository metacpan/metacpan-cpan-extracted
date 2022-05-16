#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use JavaScript::QuickJS;

{
    my $return;

    my $js = JavaScript::QuickJS->new();

    $js->set_globals(  __return => sub { $return = shift } );

    my $ret = $js->eval('__return( a => a );');

    isa_ok(
        $return,
        'JavaScript::QuickJS::Function',
        'eval() of an arrow function',
    );

    like(
        "$return",
        qr<JavaScript::QuickJS::Function>,
        'stringification',
    );

    undef $return;

}

done_testing;
