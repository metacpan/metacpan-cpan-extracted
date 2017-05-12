### 01-definition.t #############################################################################
# This file tests the process of defining and executing a pipeline.

### Includes ######################################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

# use Test::More tests => 14;
use Test::More
		(qx(which sbatch))
		? (tests => 14)
		: (skip_all => "SLURM not available on this system");


use Test::Exception;

use HPCI;

my $cluster = 'SLURM';

my $group = HPCI->group( cluster => $cluster, base_dir => 'scratch', name => 'T_Definition' );

ok($group, "Group created.");

my $workdir = "scratch/TEST.DEF.REMOVE.ME";
if ( -e $workdir ) {
	die "file exists where work directory was going to be used ($workdir)"
	  if -f _;
	system("rm -rf $workdir") if -d _;
	die "cannot remove old work directory $workdir" if -d $workdir;
}

my $stage1 = $group->stage(
	name => 'Stage1',
	resources_required => {
		mem => '2G'
		},
	command => "sleep 10;mkdir $workdir",
	);

ok($stage1, "Stage 1 created.");

my $stage2 = $group->stage(
	name => 'Stage2',
	resources_required => {
		mem => '2G'
		},
	command => "[ -d $workdir ] && touch $workdir/2.pre && sleep 2 && touch $workdir/2.post",
	);

ok($stage2, "Stage 2 created.");

my $stage3 = $group->stage(
	name => 'Stage3',
	resources_required => {
		mem => '2G'
		},
	command => "[ -d $workdir ] && touch $workdir/3.pre && sleep 2 && touch $workdir/3.post",
	);

ok($stage3, "Stage 3 created.");

my $stage4 = $group->stage(
	name => 'Stage4',
	resources_required => {
		mem => '2G'
		},
	command => "[ -d $workdir ] && touch $workdir/4.pre && sleep 10 && touch $workdir/4.post",
	);

ok($stage4, "Stage 4 created.");

my $stage5 = $group->stage(
	name => 'Stage5',
	resources_required => {
		mem => '2G'
		},
	command => "[ -d $workdir -a -f $workdir/2.pre -a -f $workdir/3.pre -a -f $workdir/4.pre -a -f $workdir/2.post -a -f $workdir/3.post -a -f $workdir/4.post ]",
	);

ok($stage5, "Stage 5 created.");

# order: 1 (2,3,4) 5
# 2,3,4 in any order, 1 is first, 5 is last
$group->add_deps( pre_req => $stage1, deps => [ $stage2, $stage3, $stage4 ] );
$group->add_deps( dep => $stage5, pre_reqs => [ $stage2, $stage3, $stage4 ] );

my $start = time;
$group->execute();
my $end = time;

ok( ($end - $start) > 19, "elapsed time must be at least 19 seconds" );

ok( -d $workdir, "directory $workdir must have been created" );
ok( -f $_, "file $_ must have been created" )
	for (
		map { ("$workdir/$_.pre", "$workdir/$_.post") } 2..4
	);

1;
