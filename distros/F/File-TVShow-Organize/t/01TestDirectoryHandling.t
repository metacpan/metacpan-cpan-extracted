# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01TestDirectoryHandling.t'

#########################

use strict;
use warnings;
use Data::Dumper;

use Test::More;
use Test::Carp;
use lib '../lib/';
BEGIN { use_ok('File::TVShow::Organize') };
BEGIN { use_ok('File::Path')};
BEGIN { use_ok('File::Copy')};
BEGIN { use_ok('Cwd')};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $obj = File::TVShow::Organize->new();
isa_ok($obj, 'File::TVShow::Organize');

subtest "Test Destintaiton Directory handling" => sub {
can_ok ($obj, 'show_folder');

subtest "Call show_folder with it never being set" => sub {
is ($obj->show_folder, undef, "show_folder was never set and returns undef as required");
};

subtest "Pass an invalid path" => sub {
is($obj->show_folder(getcwd . '/TV Shows'), undef, "Passed an invalid path");
};

subtest "Pass a valid path" => sub {
ok($obj->show_folder(getcwd . '/t/TV Shows') =~ m/.*\/TV Shows\/$/,  "Passed a valid Path without ending \/ character \/ was appended by funtion");
};

subtest "Pass an invalid path again to show_folder()" => sub {
is($obj->show_folder(getcwd . 't/TV Shows'), undef, "t/TV Shows is not a valid path missing leading /");
};

};

subtest "Test new_show_folder method" => sub {
can_ok ($obj, 'new_show_folder');
is ($obj->new_show_folder, undef, "New TV Show download folder is undefined as expected");

subtest "Pass invalid path to new_show_folder()" => sub {
is($obj->new_show_folder(getcwd . 'test-data'), undef, "Passed an invalid path");
};

ok($obj->new_show_folder(getcwd . '/t/test-data') =~ m/.*\/$/, "new_show_folder was passed a valid path not ending with \/. but returned path ending in \/");


subtest "Pass an invalid path again to new_show_folder" => sub {
is($obj->new_show_folder(getcwd . 't/test-data'), undef, "t/test-data is not a valid path missing leading /");
};

};

done_testing();
