### 23-subgroup.t #############################################################
# This file tests basic subgroup operation.

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More tests => 15;
use Test::Exception;

use HPCI;

my $cluster = $ENV{HPCI_CLUSTER} || 'uni';

-d 'scratch' or mkdir 'scratch';

my $group = HPCI->group( cluster => $cluster, base_dir => 'scratch', name => 'T_Definition' );

ok($group, "Group created.");

my $workdir = "scratch/SUBGROUP_BASE";
if ( -e $workdir ) {
	die "file exists where work directory was going to be used ($workdir)"
	  if -f _;
	system("rm -rf $workdir") if -d _;
	die "cannot remove old work directory $workdir" if -d $workdir;
}

my $stage1 = $group->stage(
	name => 'Stage1',
	resources_required => {
		h_vmem => '2G'
		},
	command => "mkdir $workdir && sleep 10",
	pre_req => [undef],
	);

ok($stage1, "Stage 1 created.");

my $subgroup = $group->subgroup(
    name => 'Subgroup',
    pre_req => $stage1,
);

ok($subgroup, "Subgroup created.");

my $stage1s = $subgroup->stage(
	name => 'Stage1',
	resources_required => {
		h_vmem => '2G'
		},
	command => "[ -d $workdir ] && touch $workdir/2.pre && sleep 2 && touch $workdir/2.post",
	);

ok($stage1s, "Stage 1 of Subgroup created.");

my $stage2s = $subgroup->stage(
	name => 'Stage2',
	resources_required => {
		h_vmem => '2G'
		},
	command => "[ -d $workdir ] && touch $workdir/3.pre && sleep 2 && touch $workdir/3.post",
	);

ok($stage2s, "Stage 2 of Subgroup created.");

my $stage3s = $subgroup->stage(
	name => 'Stage3',
	resources_required => {
		h_vmem => '2G'
		},
	command => "[ -d $workdir ] && touch $workdir/4.pre && sleep 10 && touch $workdir/4.post",
	pre_req => $stage2s,
	);

ok($stage3s, "Stage 3 of Subgroup created.");

my $stage2 = $group->stage(
	name => 'Stage2',
    pre_req => $subgroup,
	resources_required => {
		h_vmem => '2G'
		},
	command => "sleep 10;[ -d $workdir -a -f $workdir/2.pre -a -f $workdir/3.pre -a -f $workdir/4.pre -a -f $workdir/2.post -a -f $workdir/3.post -a -f $workdir/4.post ]",
	);

ok($stage2, "Stage 2 created.");

# order: 1 (1s,(2s,3s)) 2
# 1 is first, 2 is last
# 1s at same time as (2s,3s) but 2s and 3s sequentially

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
