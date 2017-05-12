#!/usr/bin/perl -w
use strict;
use warnings;
use Test::Exception;
use Test::More tests => 8;
use lib 'lib';

use_ok('Messaging::Courier');
my $c = Messaging::Courier->new();

use_ok('Messaging::Courier::Wiretap');
my $w = Messaging::Courier::Wiretap->new();

throws_ok { $w->tap('not_a_number') } qr/timeout must be a number/;
throws_ok { $w->tap(-1) } qr/timeout must be a positive number/;

my $user = $ENV{USER} || getlogin || getpwuid($>);
ok($user, "user is set to something");

use_ok( 'Messaging::Courier::ExampleMessage' );
my $m = Messaging::Courier::ExampleMessage->new();
$m->username($user);
$m->password('bar');
$c->send($m);

my $xml;

foreach (1..10) {
  $xml = $w->tap(0.1);
  next unless $xml;
  last if $xml =~ m{<Messaging__Courier__ExampleMessage>} && $xml =~ m{<username>$user</username>};
  warn $xml;
}

ok($xml, "Managed to tap XML");
like($xml, qr{<type>Messaging::Courier::ExampleMessage</type>});
