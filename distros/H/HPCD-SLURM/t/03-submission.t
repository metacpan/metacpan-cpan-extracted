### 03-submission.t ###########################################################
# This file tests the simple calls to the job submit function

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

# use Test::More tests => 5;
use Test::More
		(qx(which sbatch))
		? (tests => 5)
		: (skip_all => "SLURM not available on this system");
use Test::Exception;
use MooseX::Types::Path::Class qw(Dir File);
use File::Temp;
use File::pushd;
use File::ShareDir;
use HPCI;

use FindBin;
$ENV{PATH} = "$FindBin::Bin/../bin:$ENV{PATH}";

### Tests #####################################################################

-d 'scratch' or mkdir 'scratch';

my $cluster = 'SLURM';

{
	my $group = HPCI->group(
		cluster  => $cluster,
		base_dir => 'scratch',
		name     => 'T_Submission'
		);
	my $grpdir = $group->group_dir;

	my $num_jobs = 3;

	foreach my $i ( 0 .. $num_jobs ) {
		$group->stage(
			command => "echo 'yo, $i' >$grpdir/testfile$i.txt",
			name    => "otherjob$i",
		);
	}

	my $results = $group->execute();

	my $cnt = 0;
	while ( my ( $name, $stats ) = each %$results ) {
		like( $name, qr{^otherjob\d$}, "result $name matches" );
		++$cnt;
	}
	is( $cnt, $num_jobs + 1, 'Number of finished jobs is correct' );
}

done_testing();
