#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 18;
use Test::Exception;
use Sys::Hostname;
use lib 'lib';

use_ok('Messaging::Courier');
my $c;
eval { $c = Messaging::Courier->new() };
if ($@) {
  die "

* Messaging::Courier requires Spread to be installed
* See the docs for details

";
}

eval {
  my $f = Messaging::Courier->new(
    Port => '125134523465' # unlikely to exist
  );
};
ok( $@ );
isa_ok( $@, 'EO::Error' );
isa_ok( $@, 'Messaging::Courier::Error::CouldNotConnect', $@ );

throws_ok {
  my $f = Messaging::Courier->new(Peer => 'not-here.example.com');
} qr /could not connect to spread daemon/;

throws_ok { $c->receive('not_a_number') } qr/timeout must be a number/;
throws_ok { $c->receive(-1) } qr/timeout must be a positive number/;

# First a simple case

use_ok( 'Messaging::Courier::ExampleMessage' );
ok( my $m = Messaging::Courier::ExampleMessage->new() );
ok( $m->username( $ENV{USER} || getlogin || getpwuid($>) ) );
ok( $m->password( 'bar' ) );
ok( $c->send( $m ) );

{
  my $query;
  while(1) {
    ok( $query = $c->receive() );
    last if $query->username() eq ( $ENV{USER} || getlogin || getpwuid($>) );
  }

  my $reply = $query->reply->token( '42' );
  ok( $c->send( $reply ) );
}

my $response = $c->receive( 0, $m );
is( $response->token, '42' );
is( $response->frame->in_reply_to, $m->frame->id );
ok( $response->sent_by($c) );

# Now let's time out
ok (not defined $c->receive( 1, $m ));



1;
