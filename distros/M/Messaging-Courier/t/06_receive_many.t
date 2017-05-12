#!/usr/bin/perl -w
use strict;
use warnings;
use Test::Exception;
use Test::More tests => 14;
use Time::HiRes qw(time);
use lib 'lib';

use_ok('Messaging::Courier');
my $c = Messaging::Courier->new();

use_ok( 'Messaging::Courier::ExampleMessage' );
my $m = Messaging::Courier::ExampleMessage->new();
$m->username( $ENV{USER} || getlogin || getpwuid($>) );
$m->password('bar');
$c->send($m);

foreach my $i (1..10) {
  my $m2 = Messaging::Courier::ExampleMessage->new();
  $m2->username( $ENV{USER} || getlogin || getpwuid($>) );
  $m2->password($i);
  $m2->in_reply_to($m);
  $c->send($m2);
}

my $time = time;
my @replies = $c->receive_many(1, $m);
is (scalar(@replies), 10);

my $diff = time - $time;
ok( $diff < 1.1, "Took much more than a second ($diff)");

foreach my $i (1..10) {
  my $m = shift @replies;
  is($m->password, $i);
}


