#!perl 
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 11;
use Test::Trap;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}


my $des = Devel::Examine::Subs->new(
                    file => 't/sample.data',
                    cache => 1,
                );

$des->has(include => [qw(one)]);
is ($des->_cache_safe, 0, "cache_safe() is correct");

$des->has(include => [qw(one)]);
is ($des->_cache_safe, 1, "cache_safe() is correct");

$des->has(include => [qw(one two)]);
is ($des->_cache_safe, 0, "cache_safe() is correct");

$des->has(include => [qw(two)]);
is ($des->_cache_safe, 0, "cache_safe() is correct");

$des->has(search => 'this');
is ($des->_cache_safe, 0, "cache_safe() is correct");

$des->has(search => 'this');
is ($des->_cache_safe, 1, "cache_safe() is correct");

$des->has();

$des->has();
is ($des->_cache_safe, 1, "cache_safe() is correct");

$des->has(extensions => [qw(pl pw)]);
is ($des->_cache_safe, 0, "cache_safe() is correct");

$des->all();
is ($des->_cache_safe, 1, "cache_safe() works with no params and " .
    "extensions set earlier");

$des->all();
is ($des->_cache_safe, 1, "cache_safe() is correct");


