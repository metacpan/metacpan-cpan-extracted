#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

BEGIN {
    use_ok('ElasticSearch::SearchBuilder') || print "Bail out!";
}

diag "";
diag(
    "Testing ElasticSearch::SearchBuilder $ElasticSearch::SearchBuilder::VERSION, Perl $], $^X"
);

my $a;
ok $a = ElasticSearch::SearchBuilder->new, 'Instantiate';
ok $a = $a->new, 'Instantiate from ref';

is( scalar $a->filter(),      undef, 'Empty ()' );
is( scalar $a->filter(undef), undef, '(undef)' );
is( scalar $a->filter( [] ), undef, 'Empty []' );
is( scalar $a->filter( {} ), undef, 'Empty {}' );
is( scalar $a->filter( [ [], {} ] ), undef, 'Empty [[]{}]' );
is( scalar $a->filter( { [], {} } ), undef, 'Empty {[]{}}' );
is( scalar $a->filter( { -ids => [] } ), undef, 'IDS=>[]' );
cmp_deeply $a->filter( \{ term => { foo => 1 } } ),
    { filter => { term => { foo => 1 } } },
    '\\{}';

throws_ok { $a->filter( 1, 2 ) } qr/Too many params/, '1,2';
throws_ok { $a->filter( [undef] ) } qr/UNDEF in arrayref/, '[undef]';

done_testing;
