# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 59;

BEGIN { use_ok( 'List::NSect', qw{deal} ); }

#diag("nominal cases");

{
my @s=deal;
is(scalar(@s), 0);
}
{
my @s=deal();
is(scalar(@s), 0);
}
{
my @s=deal(undef);
is(scalar(@s), 0);
}
{
my @s=deal(0);
is(scalar(@s), 0);
}
{
my @s=deal(undef,1,2,3);
is(scalar(@s), 0);
}
{
my @s=deal(0,1,2,3);
is(scalar(@s), 0);
}

#diag("trival cases");

{
my @s=deal(1);
is(scalar(@s), 0);
}
{
my @s=deal(1, ());
is(scalar(@s), 0);
}
{
my @s=deal(4);
is(scalar(@s), 0);
}
{
my @s=deal(8, ());
is(scalar(@s), 0);
}

#diag("normal cases");

{
my @s=deal(1,2,3,4);
is(scalar(@s), 1);
isa_ok($s[0], "ARRAY");
is($s[0]->[0], 2);
is($s[0]->[1], 3);
is($s[0]->[2], 4);
}
{
my @s=deal(3,2,3,4);
is(scalar(@s), 3);
isa_ok($s[0], "ARRAY");
isa_ok($s[1], "ARRAY");
isa_ok($s[2], "ARRAY");
is($s[0]->[0], 2);
is($s[1]->[0], 3);
is($s[2]->[0], 4);
}
{
my @s=deal(4, 1 .. 17);
is(scalar(@s), 4);
isa_ok($s[0], "ARRAY");
isa_ok($s[1], "ARRAY");
isa_ok($s[2], "ARRAY");
isa_ok($s[3], "ARRAY");
is(scalar(@{$s[0]}), 5);
is(scalar(@{$s[1]}), 4);
is(scalar(@{$s[2]}), 4);
is(scalar(@{$s[3]}), 4);
is($s[0]->[0], 1);
is($s[0]->[1], 5);
is($s[0]->[2], 9);
is($s[0]->[3], 13);
is($s[0]->[4], 17);
is($s[1]->[0], 2);
is($s[1]->[1], 6);
is($s[1]->[2], 10);
is($s[1]->[3], 14);
is($s[2]->[0], 3);
is($s[2]->[1], 7);
is($s[2]->[2], 11);
is($s[2]->[3], 15);
is($s[3]->[0], 4);
is($s[3]->[1], 8);
is($s[3]->[2], 12);
is($s[3]->[3], 16);
}

#diag("edge case n > count");

{
my @s=deal(100, 1,2,3);
is(scalar(@s), 3);
isa_ok($s[0], "ARRAY");
isa_ok($s[1], "ARRAY");
isa_ok($s[2], "ARRAY");
is(scalar(@{$s[0]}), 1);
is(scalar(@{$s[1]}), 1);
is(scalar(@{$s[2]}), 1);
is($s[0]->[0], 1);
is($s[1]->[0], 2);
is($s[2]->[0], 3);
}
