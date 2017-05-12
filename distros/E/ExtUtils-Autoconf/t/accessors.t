#!perl

use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;
use ExtUtils::Autoconf;

my $ac = ExtUtils::Autoconf->new;
isa_ok( $ac, 'ExtUtils::Autoconf' );

is( $ac->wd, 'autoconf', 'wd default' );
is( $ac->wd('foo'), 'foo', 'set/get wd' );

is( $ac->autoconf('foo'), 'foo', 'get/set autoconf' );

is( $ac->autoheader('foo'), 'foo', 'get/set autoheader' );

is( ref $ac->env, 'HASH', 'get full env' );
is( $ac->env('osname'), $^O, 'get single env value' );

dies_ok(sub {
        $ac->env(qw( a b c ));
}, 'env dies with more than two arguments');
