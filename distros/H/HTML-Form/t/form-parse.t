#!perl

use strict;
use warnings;

use Test::More;
use HTML::Form ();
use Test::Warnings qw(warning);

$^W = 1;
like(
    warning {
        HTML::Form->parse( q{}, base => 'http://localhost/', foo => 1 )
    },
    qr/^Unrecognized option foo in HTML::Form/,
    'caught invalid option to parse()',
);

done_testing;
