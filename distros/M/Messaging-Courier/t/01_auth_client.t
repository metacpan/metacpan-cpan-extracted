#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 9;

if (not fork) {
  exec $^X, 't/bin/auth_server.pl';
}

sleep 1;

use_ok('Messaging::Courier');
ok( my $c = Messaging::Courier->new() );

use_ok( 'Messaging::Courier::ExampleMessage' );
ok( my $m = Messaging::Courier::ExampleMessage->new() );
ok( $m->username( $ENV{USER} || getlogin || getpwuid($>) ) );
ok( $m->password( 'bar' ) );
my $response = $c->ask( $m );
ok( $response );
is( $response->token, '42' );
is( $response->frame->in_reply_to, $m->frame->id );
