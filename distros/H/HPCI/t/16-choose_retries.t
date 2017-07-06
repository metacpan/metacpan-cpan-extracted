### 16-choose_retries.t ###########################################################
# This file tests the forced_retry attribute

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More;
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

my $num_tests_expected;

{
	my $num_retries  = 2;
	for my $num_choices (1..3) {
		my $name  = "T_Choose_Retry$num_choices-of-$num_retries";
		my $group = HPCI->group(
			cluster  => $cluster,
			base_dir => 'scratch',
			name     => "$name",
			);

		my $prev_retries = 0;
		my $chooser = sub {
			# test the args, choose to retry at most twice
			my $stats  = shift;
			my $stderr = shift;
			is( ref($stats), 'HASH', 'stats arg should be a hash' );
			like( $stderr, qr{/stderr$}, 'stderr filename must be stderr' );
			like( `cat $stderr`, qr{^\+ exit 1$}m, 'stderr contains exit 1 command echo' );
			return $prev_retries++ < 2;
		};

		$group->stage(
			command             => "exit 1",
			name                => "fail1",
			choose_retries      => $num_choices,
			should_choose_retry => $chooser,
		);

		my $results = $group->execute();
		my $runs    = scalar( @{ $results->{fail1} } );

		my $num_retries_expected = $num_choices;
		$num_tests_expected += 3*$num_retries_expected + 1;
		$num_retries_expected = 2 if $num_choices > 2;
		is( $runs, $num_retries_expected+1, "with $num_choices max retries, should have $num_retries_expected retries" );
	}
}

done_testing( $num_tests_expected );
