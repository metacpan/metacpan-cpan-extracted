use Test::More tests => 11;
use strict;
use warnings;
use Google::ProtocolBuffers;

BEGIN{ $SIG{__DIE__} = \&Carp::confess; }

my @classes;

@classes = Google::ProtocolBuffers->parse("
  package my.test;
  message TestOneof {
    oneof test_oneof {
      string name = 1;
      int32 serial_number = 2;
    }
  }", {create_accessors=>1});

is(scalar @classes, 1);
is($classes[0], 'My::Test::TestOneof');
can_ok($classes[0], qw(which_oneof));

my $obj1 = new_ok($classes[0]);
ok(!defined($obj1->which_oneof('test_oneof')));
$obj1->name('My Name');
ok($obj1->name() eq 'My Name');
ok($obj1->which_oneof('test_oneof') eq 'name');
ok(!exists($obj1->{'serial_number'}));
$obj1->serial_number(12345);
ok($obj1->serial_number() == 12345);
ok($obj1->which_oneof('test_oneof') eq 'serial_number');
ok(!exists($obj1->{'name'}));
