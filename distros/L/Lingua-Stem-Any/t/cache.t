use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 28;
use Lingua::Stem::Any;

my $s = new_ok 'Lingua::Stem::Any', [ language => 'en' ];
my $cache1 = { $s->source => { en => { fooing => 'foo' } } };
my $cache2 = { $s->source => { en => { gooing => 'goo' } } };

can_ok $s, qw( cache clear_cache _cache_data  );

ok !$s->cache, 'no caching by default';

is $s->stem('fooing'), 'foo', 'default stemming';

is_deeply $s->_cache_data, {}, 'cache is empty when not enabled';

$s->cache(1);

ok $s->cache, 'caching enabled via method';

is_deeply $s->_cache_data, {}, 'cache is empty by default';

is $s->stem('fooing'), 'foo', 'stemming with caching enabled';

is_deeply $s->_cache_data, $cache1, 'stem is cached';

is $s->stem('fooing'), 'foo', 'stemming using cache';

# don't try this at home!
$s->_cache_data->{$s->source}{en}{fooing} = 'goo';

is $s->stem('fooing'), 'goo', 'confirm caching with manual cache munging';

$s->clear_cache;

ok $s->cache, 'caching still enabled after clearing';

is_deeply $s->_cache_data, {}, 'cache is empty after clearing';

is $s->stem('fooing'), 'foo', 'stemming after cache is cleared';

is_deeply $s->_cache_data, $cache1, 'stem is cached';

$s->cache(0);

ok !$s->cache, 'caching is desabled';

is_deeply $s->_cache_data, {}, 'cache is cleared when disabling';

is $s->stem('fooing'), 'foo', 'stemming after disabling cache';

is_deeply $s->_cache_data, {}, 'cache unpopulated after stemming when disabled';

my $s2 = new_ok 'Lingua::Stem::Any', [
    language => 'en',
    cache    => 1,
];

ok $s2->cache, 'caching enabled via instantiator';

is_deeply $s2->_cache_data, {}, 'cache is empty by default';

is $s2->stem('fooing'), 'foo', 'stemming with caching enabled';

is_deeply $s2->_cache_data, $cache1, 'stem is cached';

my $s3 = new_ok 'Lingua::Stem::Any', [
    language => 'en',
    cache    => 1,
];

is $s3->stem('gooing'), 'goo', 'stemming with caching enabled';

is_deeply $s2->_cache_data, $cache1, 'cache is per object';
is_deeply $s3->_cache_data, $cache2, 'cache is per object';
