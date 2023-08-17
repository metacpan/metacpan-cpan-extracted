#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use MVC::Neaf;
use MVC::Neaf::Route::Main;

my %opt = (
    parent => MVC::Neaf->new,
    path   => '/foo',
    method => 'GET',
    code   => sub {},
);

throws_ok {
    MVC::Neaf::Route->new( %opt, unknown_option => 1 );
} qr/unknown.*: unknown_option/, 'Unknown options not allowed';

throws_ok {
    MVC::Neaf::Route->new( %opt, code => \1 );
} qr/must be a subroutine/, 'Code must be code';

throws_ok {
    MVC::Neaf::Route->new( %opt, public => 1 );
} qr/public.*description/, 'Public endpoint must have description';

throws_ok {
    MVC::Neaf::Route->new( %opt, method => '+++' );
} qr/method/, 'Method should be something reasonable';

throws_ok {
    MVC::Neaf::Route->new( %opt, param_regex => qr/.../ );
} qr/param_regex/, 'something wrong in the param regex';

throws_ok {
    MVC::Neaf::Route->new( %opt, param_regex => { bar => undef } );
} qr/param_regex/, 'something wrong in the param regex';

throws_ok {
    MVC::Neaf::Route->new( %opt, cache_ttl => 'too much' );
} qr/cache_ttl.*number/, 'cache ttl must be a number';

done_testing;
