### 11-base_dir.t #############################################################
# This file tests setting base_dir with an absolute path
# (all other tests use a relative path)

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More tests => 3;
use Test::Exception;

use File::Slurp;

use HPCI;

my $cluster = $ENV{HPCI_CLUSTER} || 'uni';

my $dir_path=`pwd`;
chomp($dir_path);

my $group = HPCI->group(
	cluster => $cluster,
	base_dir => "$dir_path/scratch",
	name => 'T_Definition'
	);

ok($group, "Group created.");

my $stage1 = $group->stage(
	name    => "echoTest",
	command => "echo foo test"
);

ok ($stage1, "Stage 1 created");
$group->execute();

my $groupname = $group->_unique_name;
my $out = read_file( "scratch/$groupname/echoTest/final_retry/stdout" );

is ($out, "foo test\n", "Found stdout where expected in the custom directory");

done_testing();

1;
