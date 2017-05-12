#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';
use Messaging::Courier;
use Messaging::Courier::ExampleMessage;

my $c = Messaging::Courier->new();
my $response;
eval {
  $response = $c->receive();
};
if ($@) {
  print ref($@), "\n";
  print $@;
}


my $reply = $response->reply;
$reply->token( '42' );
$c->send( $reply );

