### 03-submission.t ###########################################################
# This file tests the simple calls to the job submit function

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

my $num_jobs = 6;

BEGIN { $num_jobs = 6 }

use Test::More tests => $num_jobs+2;
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
	my $group = HPCI->group(
		cluster  => $cluster,
		base_dir => 'scratch',
		# log_no_file => 1,
		name     => 'T_Submission'
		);
	my $grpdir = $group->group_dir;

	my $use_command = 0;
	my $next_flip   = 2;
	my $prev_name;

	foreach my $i ( 1 .. $num_jobs ) {
		if ($i == $next_flip) {
			$use_command = ! $use_command;
			$next_flip += 2;
		}
		my $name = "otherjob$i";
		if ($use_command) {
			$group->stage(
				name    => $name,
				command => "echo 'yo, $i' >$grpdir/testfile$i.txt",
			);
		}
		else { # use a code subroutine
			$group->stage(
				name   => $name,
				code    => sub {
					open my $fh, '>', "$grpdir/testfile$i.txt"
					  or return "open failed ($!) for $grpdir/textfile$i.txt";
				    print $fh "yo, $i\n";
					close $fh or return "close failed ($!) for $grpdir/textfile$i.txt";
					return $i+1 >= $num_jobs && 'Fail last code job for testing purposes';
				},
			);
		}
		$group->add_deps( pre_req => $prev_name, dep => $name ) if $prev_name;
		$prev_name = $name;
	}

	my $results = $group->execute();

	my $cnt = 0;
	while ( my ( $name, $stats ) = each %$results ) {
		like( $name, qr{^otherjob\d$}, "result $name matches" );
		++$cnt;
		like( $stats->[-1]{exit_status},
			qr(^Skipped because of failure),
			'last job should have been skipped'
		) if $name eq 'otherjob6';
	}
	is( $cnt, $num_jobs, 'Number of finished jobs is correct' );
}

done_testing();
