# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 05MainTestOrganize.t'

#########################

use strict;
use warnings;
use Data::Dumper;
use Test::More; #tests => 6;
use Test::Carp;
BEGIN { use_ok( 'File::TVShow::Organize' ) };
use Cwd;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $file;
my $outputPath;
my $inputPath = "t/test-data/";

my $obj = File::TVShow::Organize->new({ Exceptions => 'S.W.A.T.2017:S.W.A.T 2017' });

# Setup folder paths.
my $sourceDir = getcwd . '/t/test-data/done_list/';
my $ShowDirectory = getcwd . '/t/TV Shows';

#load paths into obj
$obj->show_folder($ShowDirectory);
$obj->new_show_folder($sourceDir);


$obj->recursion(1);
$obj->create_show_hash();

$obj->process_new_shows();

subtest "Testing recursive processing with delete set as false" => sub {
$file = getcwd . "/t/test-data/done_list/test/";
ok(-e $file . "true.blood.S01E01.avi.done", "true.blood.S01E01.avi was processed. recursion enabled.");
ok(-e $ShowDirectory . "/True Blood/Season1/true.blood.S01E01.avi", "true.blood.S01E01.avi successfully imported.");

};

# Now test Delete folder processing run
$obj->delete(1);

$obj->new_show_folder(getcwd . '/t/test-data/delete_list/');
$obj->process_new_shows();

subtest "Testing recursive processing with delete set as true" => sub {
$file = getcwd . "/test-data/delete_list/test/";
ok(!-e $file . "true.blood.S02E01.avi", "true.blood.S02E01.avi was successfully deleted. Recursion enabled.");
ok(-e $ShowDirectory . "/True Blood/Season2/true.blood.S02E01.avi", "true.blood.S02E01.avi successfully imported.");

};

done_testing();
