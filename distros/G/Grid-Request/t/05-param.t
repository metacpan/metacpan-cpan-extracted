#!/usr/bin/perl

# $Id: 05-param.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 13;
use Grid::Request::Param;

Log::Log4perl->init("$Bin/testlogger.conf");

my $param = Grid::Request::Param->new();

# Tests 1-4
can_ok($param, "type");
can_ok($param, "key");
can_ok($param, "value");
can_ok($param, "count");

# Test 5
is($param->type(), "PARAM", "Default param type is PARAM.");

# Test 6
$param->type("DIR");
is($param->type(), "DIR", "Getter/Setter behavior works for type().");

# Test 7
$param->value("VALUE");
is($param->value(), "VALUE", "Getter/Setter behavior works for value().");

# Test 8
$param->key("KEY");
is($param->key(), "KEY", "Getter/Setter behavior works for key().");

# Tests 9 & 10
eval { $param->type("BAD") };
ok(defined $@, "Setting a bad type caused an error.");
eval { $param->type("BAD") };
ok(defined $@, "Setting a bad type caused an error.");

# Test 11
my $p_file = Grid::Request::Param->new();
$p_file->type("FILE");
$p_file->value("$Bin/test_data/test_file.txt");
is($p_file->count(), 100, "Correct count for FILE param type.");

# Test 12
my $p_dir = Grid::Request::Param->new();
$p_dir->type("DIR");
$p_dir->value("$Bin/test_data/test_dir");
is($p_dir->count(), 100, "Correct count for DIR param type.");

# Test 13
my $p_array = Grid::Request::Param->new();
$p_array->type("ARRAY");
my $array_size = 100;
my @array = ();
for (my $i = 0; $i < $array_size; $i++) {
    push (@array, $i);
}
$p_array->value(\@array);
is($p_array->count(), $array_size, "Correct count for ARRAY param type.");
