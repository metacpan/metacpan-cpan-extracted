#!/bin/env perl

use strict;
use warnings;
use Test::Most;

use lib "./lib";
use File::Valet;

# tests for find_home (kind of weak; needs improvement):
unless (-e "/home/smoker") {  # skipping test in Nigel Horne's highly-restrictive test environment
  my $home_dir = find_home;
  isnt $home_dir,  undef,     'find_home found something at all ' . ($home_dir // '<undef>');
  ok   -d $home_dir,          'find_home found something likely';
  ok   -w $home_dir,          'find_home found something writable';
}

# tests for find_temp (kind of weak; needs improvement):
my $temp_dir = find_temp;
isnt $temp_dir,  undef,     'find_temp found something at all ' . ($temp_dir // '<undef>');
ok   $temp_dir =~ /t/i,     'find_temp found something likely';
is $File::Valet::OK,    'OK', 'find_temp sets OK on success';
is $File::Valet::ERROR, '',   'find_temp sets error on success';
is $File::Valet::ERRNO, '',   'find_temp sets errno on success';

# tests for find_bin (also weak):
if ($^O eq 'MSWin32') {
    isnt find_bin('cmd.exe'), undef,       'find_bin found anything at all for cmd.exe';
    ok   find_bin('cmd.exe') =~ /cmd.exe/, 'find_bin found likely cmd.exe';
}
else {
    isnt find_bin('sh'), undef,      'find_bin found anything at all for sh';
    ok   find_bin('sh') =~ /bin.sh/, 'find_bin found likely /bin/sh';
}
is $File::Valet::OK,    'OK', 'find_bin sets OK on success';
is $File::Valet::ERROR, '',   'find_bin sets error on success';
is $File::Valet::ERRNO, '',   'find_bin sets errno on success';

done_testing();
exit(0);
