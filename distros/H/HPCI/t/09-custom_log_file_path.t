### 09-custom_log_file_path.t ############################
# This file tests calls with a user specified log filepath (but no log object provided)

### Includes ###############################################

# Safe Perl
use warnings;
use strict;
use Carp;
use Test::More tests => 3;
use Test::Exception;

use Log::Log4perl qw(:easy get_logger);
use Log::Log4perl::Appender::Screen;
use Log::Log4perl::Level;

use File::Temp;

use HPCI;

my $tmp_dir = File::Temp->newdir ( TEMPLATE => 'TEST.XXXX', DIR => 'scratch', CLEANUP => 0);
print ("Creating custom logging directory named: ".$tmp_dir->dirname ."\n");

my $cluster = $ENV{HPCI_CLUSTER} ||'uni';

#Create the group
my $group = HPCI->group(
	cluster  => $cluster,
	base_dir => 'scratch',
	name     => "CUSTOM_LOG_FILE_PATH",
	log_dir  => ( $tmp_dir->dirname )
	);
ok ($group, "Group created");

my $stage1 = $group->stage(
	name    => "echoTest",
	command => "echo 3"
	);
ok ($stage1, "Stage 1 created");
$group->execute();

ok (-e (($tmp_dir->dirname)."/group.log"), "Log file created");
done_testing();
