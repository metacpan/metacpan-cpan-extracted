#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;
use Elastic::Model::SearchBuilder;

my $a = Elastic::Model::SearchBuilder->new;

cmp_deeply $a->query( { k => { '=' => { query => 0 } } } ),
    { query => { match => { k => { query => 0 } } } },
    'False string hash_param';

throws_ok { $a->query( { k => { '=' => { query => undef } } } ) }
qr/missing required param/, 'Undefined hash_param';

done_testing;
