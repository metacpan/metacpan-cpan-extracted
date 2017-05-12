### 14-stage_dependencies.t ###################################################
# This file tests dependency handling

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More tests => 3;
use Test::Exception;

use File::Temp;

use HPCI;

my $cluster = $ENV{HPCI_CLUSTER} || 'uni';

my $tmp_dir = File::Temp->newdir(
	TEMPLATE => 'TEST.XXXX',
	DIR      => 'scratch',
	CLEANUP  => 0
	);

my @failure_arr = ( qw(abort_group ignore abort_deps) );
my %abort_list = (
	abort_group => [qw(Stage2 Stage3 Stage5)],
	ignore      => [],
	abort_deps  => [qw(Stage2 Stage3)],
	);

for my $failure_type (@failure_arr){
	subtest "With failure_action as $failure_type" => sub {
		plan tests => 1;
		my $group = HPCI->group(
			cluster  => $cluster,
			base_dir => 'scratch',
			name     => "T_Stage_Failure.$failure_type"
			);

		my $stage1 = $group->stage(
			name           => 'Stage1',
			command        => "touch $tmp_dir/1.pre_$failure_type && exit 1",
			failure_action => $failure_type
			);

		my $stage2 = $group->stage(
			name    => 'Stage2',
			command => "[ -d $tmp_dir ] && \
				touch $tmp_dir/2.pre_$failure_type && \
				touch $tmp_dir/2.post_$failure_type",
		);

		my $stage3 = $group->stage(
			name    => 'Stage3',
			command => "[ -d $tmp_dir ] && \
				touch $tmp_dir/3.pre_$failure_type && \
				touch $tmp_dir/3.post_$failure_type",
		);

		my $stage4 = $group->stage(
			name    => 'Stage4',
			command => "sleep 5 && \
				touch $tmp_dir/4.post_$failure_type",
		);

		my $stage5 = $group->stage(
			name    => 'Stage5',
			command => "touch $tmp_dir/5.pre_$failure_type && \
		      	sleep 2 && \
			   	touch $tmp_dir/5.post_$failure_type",
		);

		# order: 1 before (2,3); 4 before 5
		# 4 should start before 1 finishes
		# 5 should start after  1 finishes
		# so:
		#     ignore      will run all the stages
		#     abort_group will skip 2,3,5
		#     abort_deps  will skip 2,3 (but 5 will still run)
		$group->add_deps( pre_req => $stage1, deps => [ $stage2, $stage3] );
		$group->add_deps( pre_req => $stage4, dep => $stage5);

		my $results  = $group->execute();

		my @abort = grep { $results->{$_}[-1]{exit_status} =~ /Skip/ }
			qw(Stage1 Stage2 Stage3 Stage4 Stage5);

		is_deeply( \@abort, $abort_list{$failure_type}, "right set of stages aborted" );
		};
	}


#Check the exit statuses of all the stages













done_testing();

