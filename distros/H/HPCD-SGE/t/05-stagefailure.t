### 05-stagefailure.t #########################################################
# This file tests the handing of stage failure

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

# use Test::More tests => 5;
use Test::More
        (qx(which qsub))
        ? (tests => 5)
        : (skip_all => "SGE not available on this system");
use Test::Exception;

use HPCI;

my $cluster = 'SGE';

my $group = HPCI->group( cluster => $cluster, base_dir => 'scratch', name => 'T_StageFailureSkip' );

my $stage1 = $group->stage(
	name => 'Stage1',
	resources_required => {
		h_vmem => '2G'
		},
	command => "exit 0",
	);

my $stage2 = $group->stage(
	name => 'Stage2',
	resources_required => {
		h_vmem => '2G'
		},
	command => "exit 1",
	);

my $stage3 = $group->stage(
	name => 'Stage3',
	resources_required => {
		h_vmem => '2G'
		},
	command => "exit 0",
	);

my $stage4 = $group->stage(
	name => 'Stage4',
	resources_required => {
		h_vmem => '2G'
		},
	command => "exit 0",
	);

my $stage5 = $group->stage(
	name => 'Stage5',
	resources_required => {
		h_vmem => '2G'
		},
	command => "exit 0",
	);

# order: (1,2), (3,4,5)
# 1&2 in any order, but both complete before any of 3,4,5
# since 2 fails, non of 3,4,5 should actually be submitted
$group->add_deps(
	pre_reqs => [ $stage1, $stage2 ],
	deps     => [ $stage3, $stage4, $stage5 ]
);

my $res = $group->execute();

my $skip = 'Skipped because of failure of stage Stage2',
is( $res->{Stage1}[0]{exit_status}+0,     0, 'Stage1 passes' );
is( $res->{Stage2}[0]{exit_status}+0,     1, 'Stage2 fails' );
is( $res->{Stage3}[0]{exit_status},   $skip, 'Stage3 skipped' );
is( $res->{Stage4}[0]{exit_status},   $skip, 'Stage4 skipped' );
is( $res->{Stage5}[0]{exit_status},   $skip, 'Stage5 skipped' );

1;
