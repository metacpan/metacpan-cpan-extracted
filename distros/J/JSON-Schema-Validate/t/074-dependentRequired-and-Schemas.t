#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use lib './lib';
use open ':std' => 'utf8';
use JSON ();
use JSON::Schema::Validate;

my $schema =
{
    type => 'object',
    properties => {
        a => { type => 'integer' },
        b => { type => 'integer' },
        c => { type => 'integer' },
    },
    dependentRequired => {
        a => [ 'b' ],
    },
    dependentSchemas => {
        c => { properties => { b => { minimum => 10 } } },
    },
};

my $js = JSON::Schema::Validate->new( $schema );

ok(  $js->validate( { a => 1, b => 2 } ),          'a implies b present' ) or diag $js->error;
ok( !$js->validate( { a => 1 } ),                  'fails: a present but b missing' );
ok(  $js->validate( { c => 1, b => 10 } ),         'c present, b must be >=10 (ok)' ) or diag $js->error;
ok( !$js->validate( { c => 1, b => 5 } ),          'fails: c present but b < 10' );

done_testing;

__END__
