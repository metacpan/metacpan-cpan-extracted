#!/usr/bin/perl -w
use strict;
use warnings;
use Test::Exception;
use Test::More tests => 3;
use Time::HiRes qw(time);
use lib 'lib';

use_ok('Messaging::Courier');
my $c = Messaging::Courier->new();

use_ok( 'Messaging::Courier::ExampleMessage' );
my $m = Messaging::Courier::ExampleMessage->new();
$m->username( $ENV{USER} || getlogin || getpwuid($>) );
$m->password('bar');
$c->send($m);

foreach (1..20) {
  my $m2 = Messaging::Courier::ExampleMessage->new();
  $m2->username( $ENV{USER} || getlogin || getpwuid($>) );
  $m2->password('bar');
  $c->send($m2);
}

my $m3 = Messaging::Courier::ExampleMessage->new();
$m3->username('back');
$m3->password('return');
$m3->in_reply_to($m);
$c->send($m3);

my $time = time;
my $r = $c->receive(1, $m);
my $diff = time - $time;
ok( $diff < 1, "Took less than a second ($diff)");

