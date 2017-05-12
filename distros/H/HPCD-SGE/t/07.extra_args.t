### 07-extra_args.t ##############################
# This file tests the process dealing with timeouts

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;
use Config;


# use Test::More tests => 3;
use Test::More
        (qx(which qsub))
        ? (tests => 3)
        : (skip_all => "SGE not available on this system");
use Test::Exception;

use HPCI;

my $cluster = 'SGE';

my $group = HPCI->group(
	cluster  => $cluster,
	base_dir => 'scratch',
	name     => "T_extra_args"
);

ok($group, "group created.");

my @argstrs = (
	"-pe smp 8",
	"-l hostname=cn3-244",
);
my $stagecnt = 0;
for my $argstr (@argstrs) {
	my $stagename = "argstr_$stagecnt";
	++$stagecnt;
	my $stage = $group->stage(
		name                  => $stagename,
		extra_sge_args_string => $argstr,
		command               => "sleep 1",
	);

	ok($stage, "stage created for arg ($argstr).");
}

my $res = $group->execute;


1;
