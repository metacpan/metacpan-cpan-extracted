# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 57;

BEGIN { use_ok( 'List::NSect', qw{spart} ); }

#diag("nominal cases");

{
my $s=spart;
is(scalar(@$s), 0);
}
{
my $s=spart();
is(scalar(@$s), 0);
}
{
my $s=spart(undef);
is(scalar(@$s), 0);
}
{
my $s=spart(0);
is(scalar(@$s), 0);
}
{
my $s=spart(undef,1,2,3);
is(scalar(@$s), 0);
}
{
my $s=spart(0,1,2,3);
is(scalar(@$s), 0);
}

#diag("trival cases");

{
my $s=spart(1);
is(scalar(@$s), 0);
}
{
my $s=spart(1, ());
is(scalar(@$s), 0);
}
{
my $s=spart(4);
is(scalar(@$s), 0);
}
{
my $s=spart(8, ());
is(scalar(@$s), 0);
}

#diag("normal cases");

{
my $s=spart(1,2,3,4);
is(scalar(@$s), 3);
isa_ok($s->[0], "ARRAY");
isa_ok($s->[1], "ARRAY");
isa_ok($s->[2], "ARRAY");
is($s->[0]->[0], 2);
is($s->[1]->[0], 3);
is($s->[2]->[0], 4);
}
{
my $s=spart(3,2,3,4);
is(scalar(@$s), 1);
isa_ok($s->[0], "ARRAY");
is($s->[0]->[0], 2);
is($s->[0]->[1], 3);
is($s->[0]->[2], 4);
}
{
my $s=spart(4, 1 .. 17);
is(scalar(@$s), 5);
isa_ok($s->[0], "ARRAY");
isa_ok($s->[1], "ARRAY");
isa_ok($s->[2], "ARRAY");
isa_ok($s->[3], "ARRAY");
isa_ok($s->[4], "ARRAY");
is(scalar(@{$s->[0]}), 4);
is(scalar(@{$s->[1]}), 4);
is(scalar(@{$s->[2]}), 4);
is(scalar(@{$s->[3]}), 4);
is(scalar(@{$s->[4]}), 1);
is($s->[0]->[0], 1);
is($s->[0]->[1], 2);
is($s->[0]->[2], 3);
is($s->[0]->[3], 4);
is($s->[1]->[0], 5);
is($s->[1]->[1], 6);
is($s->[1]->[2], 7);
is($s->[1]->[3], 8);
is($s->[2]->[0], 9);
is($s->[2]->[1], 10);
is($s->[2]->[2], 11);
is($s->[2]->[3], 12);
is($s->[3]->[0], 13);
is($s->[3]->[1], 14);
is($s->[3]->[2], 15);
is($s->[3]->[3], 16);
is($s->[4]->[0], 17);
}

#diag("edge case n > count");

{
my $s=spart(100, 1,2,3);
is(scalar(@$s), 1);
isa_ok($s->[0], "ARRAY");
is(scalar(@{$s->[0]}), 3);
is($s->[0]->[0], 1);
is($s->[0]->[1], 2);
is($s->[0]->[2], 3);
}
