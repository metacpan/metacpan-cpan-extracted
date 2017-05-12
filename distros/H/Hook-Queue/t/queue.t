#!perl
use strict;
use Test::More tests => 3;
require_ok( 'Hook::Queue' );

sub foo {
    return "I'm the original foo";
}

Hook::Queue->import(
    'main::foo' => sub {
        my $arg = shift;
        return Hook::Queue->defer() if $arg eq 'defer';
        return "I'm the hooked foo";
    });

is( foo(),        "I'm the hooked foo",   "hook ok" );
is( foo('defer'), "I'm the original foo", "defer hook ok" );

