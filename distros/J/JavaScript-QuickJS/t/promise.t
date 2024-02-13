#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use JavaScript::QuickJS;

my @out;
sub faux_print {
    push @out, [@_];
}

my $js = JavaScript::QuickJS->new();

faux_print('start');
my $p1 = $js->eval('Promise.resolve(123)');
faux_print('created promise');

my $p2 = $p1->then( sub {
    faux_print("first then", @_);
    return 234;
} );
faux_print('called then');

my $p3 = $p2->then( sub {
    faux_print("second then", @_);
    die 345;
} );

$p3->catch( sub {
    faux_print("catch", @_);
    return 456;
} )->finally( sub {
    faux_print("finally", @_);
} );

faux_print('before await');
$js->await();

cmp_deeply(
    \@out,
    [
        ['start'],
        ['created promise'],
        ['called then'],
        ['before await'],
        ['first then', 123],
        ['second then', 234],
        ['catch', re(345)],
        ['finally'],
    ],
);

done_testing;
