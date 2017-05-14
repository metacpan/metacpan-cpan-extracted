# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5 };
use HPUX::FS;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

END {print "not ok 1\n" unless $main::loaded;}

use HPUX::FS;
$loaded=1;

$attr1="";
$attr2="";
$attr3="";
$attr4="";
$attr5="";

my $idx = 2;
print "ok ",$idx++,"\n";

# Create data structures

my $fsinfo_data = new HPUX::FS(
				persistance	=>"old",
				datafile	=>"./t/fsinfo.dat"
				);



$arref3 = $fsinfo_data->get_all_filesystems();

print "ok ",$idx++,"\n";
#print "Getting all Filesystems:\n";

	foreach $fs (@$arref3)	{
#		print "Filesystem: $fs\n";
		$fs_save = $fs;
				}
print "ok ",$idx++,"\n";
#print "Getting Filesystem attributes for $fs_save\n";

$attr1 = $fsinfo_data->get_filesystem_attr(
		filesystem	=> $fs_save,
		attribute	=> "backup_freq"
					);
$attr2 = $fsinfo_data->get_filesystem_attr(
		filesystem	=> $fs_save,
		attribute	=> "capture_date"
					);
$attr3 = $fsinfo_data->get_filesystem_attr(
		filesystem	=> $fs_save,
		attribute	=> "directory"
					);
$attr4 = $fsinfo_data->get_filesystem_attr(
		filesystem	=> $fs_save,
		attribute	=> "percent_used"
					);
$attr5 = $fsinfo_data->get_filesystem_attr(
		filesystem	=> $fs_save,
		attribute	=> "type"
					);
print "ok ",$idx++,"\n";










	
