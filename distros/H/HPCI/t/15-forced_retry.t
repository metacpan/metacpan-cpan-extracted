### 15-forced_retry.t ###########################################################
# This file tests the forced_retry attribute

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More tests => 3;
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

my $cluster = $ENV{HPCI_CLUSTER} || 'uni';

{
	for my $num_retries (0..2) {
		my $name  = "T_Forced_Retry$num_retries";
		my $group = HPCI->group(
			cluster  => $cluster,
			base_dir => 'scratch',
			name     => "$name",
			);

		$group->stage(
			command       => "exit 1",
			name          => "fail1",
			force_retries => $num_retries,
		);

		my $results = $group->execute();
		my $runs    = scalar( @{ $results->{fail1} } );

		my $num_runs_expected = $num_retries + 1;
		is( $runs, $num_runs_expected, "with $num_retries retries, should have $num_runs_expected runs" );
	}
}

done_testing();
