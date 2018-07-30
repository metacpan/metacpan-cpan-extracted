#!perl

use strict;
use warnings FATAL => 'all';
use FindBin;
use lib "$FindBin::Bin/../";
use Test::Most;

BEGIN { use_ok 't::Class2' };

throws_ok { t::Class2->new } qr/Missing required arguments: ar1, num/,
    'required args checked';

throws_ok { t::Class2->new( num => "zof", ar1 => 'var1' ) }
    qr/Must be a positive number/,
    'type is checked';

{
    my $c = t::Class2->new( num => 42, initizer => 'zoom!', ar1 => '42' );
    is $c->_num,  42,          '->_num is correct';
    is $c->_type, 'text/html', '->_type is correct';
    is $c->_cust, 'Zoffix',    '->_cust is correct';
    is $c->_init, 'zoom!',     '->_init is correct (custom init_arg)';
    ok ! defined $c->_bool,    '->_bool is correct (undefined)';

    isa_ok $c->chained("foo")->chained2( 45 ), 't::Class2',
        'chained attributes return invocants';

    is $c->chained, "foo", 'chained attributes update values';
    is $c->chained2, 45,   'chained attributes update values';
}

{
    my $c = t::Class2->new(
        num   => 43,
        bool  => 1,
        _cust => 'Bar',
        type  => 'fo',
        ar1   => 'var1',
        ar2   => 'var2',
    );
    is $c->_num,  43,     '->_num is correct';
    is $c->_type, 'fo',   '->_type is correct';
    is $c->_cust, 'Bar',  '->_cust is correct';
    is $c->_bool, 1,      '->_bool is correct';
    is $c->ar1,   'var1', '->ar1 is correct';
    is $c->_ar2,  'var2', '->_ar2 is correct';
}

done_testing;
