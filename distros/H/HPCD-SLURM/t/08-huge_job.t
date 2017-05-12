### 08-huge_job.t #################################################################################
# This file tests 50 stages running all together

### Includes ######################################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

# use Test::More tests => 52;
use Test::More
		(qx(which srun))
		? (tests => 52)
		: (skip_all => "SLURM not available on this system");


use Test::Exception;

use HPCI;

my $cluster = 'SLURM';

my $group = HPCI->group( cluster => $cluster, base_dir => 'scratch', name => 'T_Huge_Job' );

ok($group, "Group created.");

foreach my $index (1..50) {
	my $stage = $group->stage(
		name => "Stage$index",
		resources_required => {
			mem => '100M'
			},
		native_args_string => "--acctg-freq=task=1 -N 4",
		command => "sleep 10",
		);
	ok($stage, "Stage $index created.");
}

my $start = time;
$group->execute();
my $end = time;

ok( ($end - $start) > 19, "elapsed time must be at least 19 seconds" );

1;
