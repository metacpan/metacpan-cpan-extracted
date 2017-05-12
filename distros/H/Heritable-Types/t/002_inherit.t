# -*- perl -*-

use Test::More tests => 8;

use Test::Exception;

sub Object::test_dispatch {
    ok 0;
}

sub HASH::test_dispatch {
    ok 1;
}

my $obj1;
BEGIN { $obj1 = bless {}, 'SomeFirstClass' }

use Heritable::Types;
my $obj2 = bless {}, 'SomeClass';

ok $obj1->isa('HASH'), "Blessing before load";
$obj1->test_dispatch;
ok $obj2->isa('HASH'), "Blessing after load";
$obj2->test_dispatch;
dies_ok { $obj2->non_existent_method }
  "None existent methods throw exceptions";

sub SCALAR::test_dispatch {
  Test::More::ok 1, "Dispatches via SCALAR";
}

my $obj3;
(bless \$obj3, 'BuffyFan')->test_dispatch;

sub ARRAY::test_dispatch { Test::More::ok 1, "Dispatches via ARRAY" }

(bless [], 'BuffArray')->test_dispatch;

sub Object::only_in_object { Test::More::ok 1, "Reaches Object" }

$obj2->only_in_object;
