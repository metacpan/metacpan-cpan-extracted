### 12-max_concurrent.t #######################################################
# This file tests the max_concurrent group parameter

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More tests => 63;
use Test::Exception;
use File::Temp 'tempfile';
use HPCI;

my $cluster = $ENV{HPCI_CLUSTER} || 'uni';

my $max_concur = 3;

my $group = HPCI->group(
	cluster => $cluster,
	base_dir => "scratch",
	name => 'T_Max_Concurrent',
	max_concurrent =>  $max_concur
);

ok($group, "Group created.");

#Create the file for each job to append to

my ($workhandle,$workfile) = tempfile( 'TEST.CONCUR.XXXX', DIR => 'scratch' );

#Create all of the jobs
my @job_names = ( 'job01' .. 'job12' );
my $num_jobs  = scalar(@job_names);
for my $job (@job_names) {
	$group->stage(
		command => "echo start $job >> $workfile && \
		            sleep 3 && \
					echo end $job >> $workfile",
		name    => $job,
		);
	}

my $results = $group->execute();

# Scan the append file to check how many were running concurrently.
#
# Track the number of start* files that have been seen where the corresponding
# end* files has not yet been seen.
#
# That number should never be larger the max_concurrent.

my $cur = 0;
my $concur = 0;
my $max = 0;
my %found;

for my $f (<$workhandle>) {
	chomp $f;
	my ( $se, $job, $nothere ) = split / /, $f;
	like( $se, qr(^(start|end)$), "must be start or end" );
	++$found{$se}{$job}{cnt};
	$found{$se}{$job}{pos} = ++$cur;
	if ( $f =~ /^start/ ) {
		++$concur;
		$max = $concur if $concur > $max;
		}
	elsif ( $f =~ /^end/ ) {
		--$concur;
		}
	}

#cmp_ok($max, '<=', $max_concur,
#	"must not exceed max_concurrent simultaneous stages running");
is( $max, $max_concur,
	"simultaneous stages running should reach but not exceed max_concurrent" );
is( $concur, 0, "balanced number of job starts and ends" );
for my $job (@job_names) {
	is( $found{start}{$job}{cnt}, 1, "job started once" );
	is( $found{end}{$job}{cnt},   1, "job finished once" );
	cmp_ok(
		$found{start}{$job}{pos},
		'<',
		$found{end}{$job}{pos},
		"job started before it finished"
		);
	}

done_testing();
