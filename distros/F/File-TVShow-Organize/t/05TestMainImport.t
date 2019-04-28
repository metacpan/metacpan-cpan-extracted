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

my $obj = File::TVShow::Organize->new( { Exceptions => 'S.W.A.T.2017:S.W.A.T 2017' } );

# Setup folder paths.
my $sourceDir = getcwd . '/t/test-data/done_list/';
my $ShowDirectory = getcwd . '/t/TV Shows';

#load paths into obj
$obj->show_folder($ShowDirectory);
$obj->new_show_folder($sourceDir);

$obj->create_show_hash();

subtest "About to process done_list Folder." => sub {
can_ok($obj, 'were_there_errors');
is($obj->{UnhandledFileNames}, undef, "No UnhandedFiles have been found");

can_ok($obj, 'process_new_shows');
$obj->process_new_shows();
can_ok($obj, 'move_show');

};

# Now test Delete folder processing run
$obj->delete(1);

$obj->new_show_folder(getcwd . '/t/test-data/delete_list/');
$obj->process_new_shows();

$obj->season_folder(0);
$obj->new_show_folder(getcwd . '/t/test-data/noseason_list/');
$obj->process_new_shows();


subtest "Check if there were errors" => sub {
$obj->were_there_errors();
ok($obj->{UnhandledFileNames} =~ /HASH/, "Unhandled files were found");
};

#diag explain $obj;

#my $d = Data::Dumper->new([$obj]);
#print $d->Dump;

done_testing();
