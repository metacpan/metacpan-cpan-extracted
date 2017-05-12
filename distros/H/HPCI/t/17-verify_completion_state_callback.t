### 17-verify_completion_state_callback.t #####################################
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

my %commands = (
	fail => 'exit 1',
	pass => 'exit 0',
);

my $group = HPCI->group(
	cluster  => $cluster,
	base_dir => 'scratch',
	name     => "T_Verify_State_Callback",
	);

my %expected = ();

for my $to (qw(pass fail nochange)) {
	while( my( $from, $code ) = each %commands ) {
		my $exit = $from eq 'pass' ? 0 : 1;
		for my $retry ( 0, 1 ) {
			my $name = "$from-to-$to-R$retry";
			my $iter = 0;
			$group->stage(
				command                 => $code,
				name                    => $name,
				verify_completion_state => sub {
					# test the args, choose to retry at most twice
					my $stats  = shift;
					my $stdout = shift;
					my $stderr = shift;
					is( ref($stats), 'HASH', 'stats arg should be a hash' );
					like( $stdout, qr{/stdout$}, 'stdout filename must be stdout' );
					like( $stderr, qr{/stderr$}, 'stderr filename must be stderr' );
					like( `cat $stderr`, qr{^\+ exit [01]$}, 'stderr contains echo of exit 0 or exit 1 command' );
					return 'retry' if $iter++ < $retry;
					return $to;
				},
			);
			$num_tests_expected += 4 * (1+$retry);
			$expected{$name} = [
				$retry ? "retry:$exit" : (),
				$to ne 'nochange' ? "$to:$exit" : "$from:$exit"
			];
		}
	}
}

my $result = $group->execute;

$num_tests_expected += 2;
is( scalar( keys %expected), 12, 'ran 12 test stages' );
is( scalar( keys %$result),  12, 'and got 12 result lists' );

while ( my ($stage, $exp_list) = each %expected ) {
	$num_tests_expected += 2;
	ok( exists $result->{$stage}, "stage $stage got a result list" );
	my @got_states = map { $_->{final_job_state} . ":" . $_->{exit_status} }
		@{ $result->{$stage} };
	is_deeply(
		$exp_list,
		\@got_states,
		"the final state for each run in stage $stage must match value and count"
	);
}

done_testing( $num_tests_expected );
