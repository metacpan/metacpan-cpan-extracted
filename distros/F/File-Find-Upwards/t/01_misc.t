#!/usr/bin/env perl
use warnings;
use strict;
use File::Find::Upwards;
use FindBin '$Bin';
use Test::More tests => 6;
my $nonexisting_file =
  'some_random_name_if_you_have_this_it_is_your_own_fault.txt';
chdir $Bin;
my $changes = file_find_upwards('Changes');
ok(file_find_upwards('01_misc.t'), 'this test file exists');
ok($changes,                       'Changes exists above this');
ok( !file_find_upwards($nonexisting_file),
    'weirdly named file does not exist upwards'
);
my $dir = find_containing_dir_upwards('Changes');
is("$dir/Changes", $changes, 'find_containing_dir_upwards');
is(file_find_upwards($nonexisting_file, 'Changes'),
    $changes, 'find one of a list of files');
is(find_containing_dir_upwards($nonexisting_file, 'Changes'),
    $dir, 'find dir containing one of those files');
