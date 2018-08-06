#!perl

use strict;
use warnings FATAL => 'all';
use FindBin;
use lib "$FindBin::Bin/../";
use Test::Most;

BEGIN { use_ok 't::Class3' };

{
    my $c = t::Class3->new(
        bool => undef, init => undef, chained => undef, chained => undef
    );
    ok ! defined $c->_bool,    '->_num is correct (undefined)';
    ok ! defined $c->_init,    '->_init is correct (undefined)';
    ok ! defined $c->chained,  '->chained is correct (undefined)';
    ok ! defined $c->chained2, '->chained2 is correct (undefined)';

    isa_ok $c->chained("foo")->chained2( 45 ), 't::Class3',
        'chained attributes return invocants';
    is $c->chained, "foo", 'chained attributes update values';
    is $c->chained2, 45,   'chained attributes update values';
}
done_testing;
