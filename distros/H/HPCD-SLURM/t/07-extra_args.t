### 06-time.t ##############################
# This file tests the process dealing with timeouts

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;
use Config;


# use Test::More tests => 2;
use Test::More
		(qx(which sbatch))
		? (tests => 2) # 2 should be changed to 4 once the mailing options are added
		: (skip_all => "SLURM not available on this system");
use Test::Exception;

use HPCI;

my $cluster = 'SLURM';

my $group = HPCI->group(
	cluster  => $cluster,
	base_dir => 'scratch',
	name     => "T_extra_args"
);

ok($group, "group created.");

my @argstrs = (
	"-N 2",
	# "--mail-type=ALL",
	# "--mail-user=...", insert your email address here and uncomment this line and the above line
);
my $stagecnt = 0;
for my $argstr (@argstrs) {
	my $stagename = "argstr_$stagecnt";
	++$stagecnt;
	my $stage = $group->stage(
		name                  => $stagename,
		native_args_string => $argstr,
		command               => "sleep 1",
	);

	ok($stage, "stage created for arg ($argstr).");
}

my $res = $group->execute;


1;
