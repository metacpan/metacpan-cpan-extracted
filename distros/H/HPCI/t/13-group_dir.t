### 13-group_dir.t ############################################################
# This file tests setting group_dir instead of base_dir

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More tests=>3;
use Test::Exception;

use File::Slurp;
use File::Temp;

use HPCI;

my $tmp_dir = File::Temp->newdir(
	TEMPLATE => 'TEST.XXXX',
	DIR      => 'scratch',
	CLEANUP  => 0
	);

my $cluster = $ENV{HPCI_CLUSTER} || 'uni';

# Create the group
my $group = HPCI->group(
	cluster   => $cluster,
	group_dir => "$tmp_dir",
	name      => 'CUSTOM_LOGGER'
);

ok($group, "Group created");

my $stage1 = $group->stage(
	name    => "echoTest",
	command => "echo foo test"
);

ok ($stage1, "Stage 1 created");
$group->execute();

my $out = read_file( "$tmp_dir/echoTest/final_retry/stdout" );

is ($out, "foo test\n", "Found stdout where expected in the custom directory");

done_testing();
