
use strict;
use Test;
use Games::RolePlay::MapGen::MapQueue::Object;

my $s7 = new Games::RolePlay::MapGen::MapQueue::Object(7);
my $st = new Games::RolePlay::MapGen::MapQueue::Object("test");

plan tests => 21;

$s7->attr(t=>"number");
$st->attr(t=>"word");

ok($s7+0, 1);
ok($s7+2, 3);
ok($s7->desc+2, 9);
ok($s7/5, 1/5);

ok($st, "test");

$st->nonunique;
ok($st, "test #1");

$st->unique;
ok($st, "test");

$st->quantity(5);
ok($st+3, 8);
ok($st, "test");
ok($st->desc, "test (5)");

$st+=3; ok($st+1, 9);
$st-=1; ok($st+1, 8);
ok($st->quantity, 7);

$st->nonunique;
ok($st, "test #1");
ok($st->desc, "test (7) #1");

$st->set_item_number(30);
ok($st->desc, "test (7) #30");

my $st1 = new Games::RolePlay::MapGen::MapQueue::Object("test");
   $st1->nonunique;
ok($st1, "test #31");

my $st2 = new Games::RolePlay::MapGen::MapQueue::Object("test");
   $st2->nonunique(50);
ok($st2, "test #50");

my $st3 = new Games::RolePlay::MapGen::MapQueue::Object("test");
   $st3->nonunique;
ok($st3, "test #51");

ok($s7->attr('t'), 'number');
ok($st->attr('t'), 'word');
