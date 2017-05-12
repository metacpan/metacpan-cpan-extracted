#!/usr/bin/env perl
use strict;
use warnings;
use Test::Moose;
use Test::More;
use Test::Warn;
use Test::Dir;
use Test::Fatal qw(lives_ok);
use HackaMol;
use Capture::Tiny;

my @attributes = qw(
  exe
  exe_endops
  command
);
my @methods = qw(
  exists_exe
);

map has_attribute_ok( 'HackaMol', $_ ), @attributes;
map can_ok( 'HackaMol', $_ ), @methods;
my $obj;

lives_ok {
    $obj = HackaMol->new(
                         scratch    => "t/tmp",
                         in_fn      => "t/tmp/foo",   # create a phony exe
                         exe        => "t/tmp/foo",
                         exe_endops => "-bar",
                        );
}
'Test creation of an obj with files exe, exe_endops';

$obj->scratch->mkpath;
dir_exists_ok($obj->scratch, 'scratch directory does exist after mkpath');

$obj->in_fn->spew(join("\n", map{sprintf("run %i",$_)} 1 .. 10 ));
ok($obj->exists_exe, 'fake exe exists');
$obj->command($obj->exe . " ". $obj->exe_endops);
is($obj->command, 't/tmp/foo -bar', "command set t/tmp/foo -bar");

$obj->scratch->remove_tree;
dir_not_exists_ok($obj->scratch, 'scratch directory deleted!');

warning_is { $obj->exists_exe }
    "t/tmp/foo does not exist",
     "carp warning if exe does not exist";

done_testing();
