#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 83;
use lib 'lib';

use Clone qw(clone);

use_ok('Messaging::Courier');
use_ok( 'Messaging::Courier::ExampleMessage' );

ok( my $c = Messaging::Courier->new() );

my $undef;
my $string = 'string';
my $integer = 42;
my $float = 1.23;
my $arrayref = [1, 2, 4, 8];
my $hashref = {
  a => 1,
  b => 2,
  c => 3,
};
my $complicated = {
  undef     => $undef,
  string    => $string,
  integer   => $integer,
  float     => $float,
  arrayref  => $arrayref,
  arrayref2 => [$undef, $string, $integer, $float],
  hashref   => $hashref,
};

my $not_utf8 = ({
 'short' => 'IXS3',
 'compatible' => 0,
 'name' => 'Digital IXUS v³',
 'type' => 'camera'
});

my @data = ($undef, $string, $integer, $float, $arrayref, $hashref,
$complicated, $not_utf8);

foreach my $data (@data) {
  test($data);
}

sub test {
  my $data = shift;

  ok( my $m = Messaging::Courier::ExampleMessage->new() );
  ok( $m->username( $ENV{USER} || getlogin || getpwuid($>) ) );
  ok( $m->password( $data ) );
  ok( $c->send( $m ) );

  {
    my $query;
    while(1) {
      ok( $query = $c->receive() );
      last if $query->username() eq ( $ENV{USER} || getlogin || getpwuid($>) );
    }
    is_deeply($query->password, clone($data));
    my $reply = $query->reply->token( '42' );
    ok( $c->send( $reply ) );
  }

  my $response = $c->receive( 0, $m );
  is( $response->token, '42' );
  is( $response->frame->in_reply_to, $m->frame->id );
  ok( $response->sent_by($c) );
}

1;
