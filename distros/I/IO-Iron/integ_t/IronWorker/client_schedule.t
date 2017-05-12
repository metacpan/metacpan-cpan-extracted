#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

use lib 't';
use lib 'integ_t';
use IronTestsCommon;

require IO::Iron::IronWorker::Client;

#use Log::Any::Adapter ('Stderr');    # Activate to get all log messages.
use Data::Dumper;
$Data::Dumper::Maxdepth = 4; ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

diag("Testing IO::Iron::IronWorker::Client, Perl $], $^X");

## Test case
diag('Testing IO::Iron::IronWorker::Client');

my $worker_as_string_rev_01 = <<'EOF';
#!/bin/sh
sleep 3
echo "Hello, World!"
EOF

my $worker_as_zip_rev_01;

my $iron_worker_client;
my $unique_code_package_name_01;
my $unique_code_executable_name_01;
my $code_package_id;
subtest 'Setup for testing' => sub {

	# Create an IronWorker client.
	$iron_worker_client =
	  IO::Iron::IronWorker::Client->new( 'config' => 'iron_worker.json', );

	# Create a new code package name.
	$unique_code_package_name_01    = IronTestsCommon::create_unique_code_package_name();
	$unique_code_executable_name_01 = $unique_code_package_name_01 . '.sh';

	my $zip           = Archive::Zip->new();
	my $string_member =
	  $zip->addString( $worker_as_string_rev_01,
		$unique_code_executable_name_01 );
	$string_member->desiredCompressionMethod(COMPRESSION_DEFLATED);

	use IO::String;
	my $io = IO::String->new($worker_as_zip_rev_01);
	{
		no warnings 'once'; ## no critic (TestingAndDebugging::ProhibitNoWarnings)
		tie *IO, 'IO::String'; ## no critic (Miscellanea::ProhibitTies)
	}
	$zip->writeToFileHandle($io);

	isnt(
		$worker_as_zip_rev_01,
		$unique_code_executable_name_01,
		'Compressed does not match with uncompressed.'
	);
	diag('Compressed two versions of the worker with zip.');
    done_testing();
};

subtest 'Upload worker' => sub {

	# Upload
	my $uploaded_code_id;
	$uploaded_code_id = $iron_worker_client->update_code_package(
		'name'      => $unique_code_package_name_01,
		'file'      => $worker_as_zip_rev_01,
		'file_name' => $unique_code_executable_name_01,
		##'runtime' => 'perl',
		##'runtime' => 'binary',
		'runtime' => 'sh',
	);
	isnt( $uploaded_code_id, undef, 'Code package uploaded.' );

	diag("Code package \'$unique_code_package_name_01\' rev 1 uploaded.");
    done_testing();
};

subtest 'confirm worker upload' => sub {

	# And confirm the upload...
	my @code_packages = $iron_worker_client->list_code_packages();
	foreach (@code_packages) {
		if ( $_->{'name'} eq $unique_code_package_name_01 ) {
			$code_package_id = $_->{'id'};
			last;
		}
	}
	isnt( $code_package_id, undef, 'Code package ID retrieved.' );

	diag('Code package rev 1 upload confirmed.');
    done_testing();
};

subtest
'Queue a task, confirm the creation, cancel it, retry, wait until finished, confirm log'
  => sub {

	# queue_task
	my $payload_01 =
	    'This is payload for code package '
	  . $unique_code_package_name_01
	  . '. Not used at this point!';
	my $task_01 = $iron_worker_client->create_task(
		'code_name' => $unique_code_package_name_01,
		'PAYLOAD'   => $payload_01,
		'run_every' => 120,
		'NAME'      => $unique_code_package_name_01 . '_scheduled_task',
		'run_times' => 5,
		'start_at'  => '2030-11-02T21:22:34Z',
	);
	isa_ok( $task_01, 'IO::Iron::IronWorker::Task',
		'create_task() returned a IO::Iron::IronWorker::Task object.' );

	my $payload_02 = 'This is payload 2 for code package ' . $unique_code_package_name_01;
	my $task_02 = $iron_worker_client->create_task(
		'code_name' => $unique_code_package_name_01,
		'PAYLOAD'   => $payload_02,
		'run_every' => 120,
		'NAME'      => $unique_code_package_name_01 . '_scheduled_task',
		'start_at'  => '2030-01-01T21:22:34Z',
		'end_at' => '2030-01-02T21:22:34Z',
	);

	my ($ret_task_01_id, $ret_task_02_id) = $iron_worker_client->schedule( 'tasks' => [$task_01, $task_02] );
	my $task_01_id = $task_01->id();
	my $task_02_id = $task_02->id();
	is( $ret_task_01_id, $task_01_id, 'task object 1 was updated with task id.' );
	is( $ret_task_02_id, $task_02_id, 'task object 2 was updated with task id.' );
	is( $task_02->run_times(), undef, 'Task initialized okay. No property \'run_times\'.' );

	# Task scheduled
	my $task_01_info =
	  $iron_worker_client->get_info_about_scheduled_task( 'id' => $task_01_id );
	is( $task_01_info->{'id'}, $task_01_id, 'Scheduled task id matches.' );
	is( $task_01_info->{'status'}, 'scheduled', 'Task is scheduled.' );

	# list scheduled tasks
	my $found;
	my @tasks = $iron_worker_client->scheduled_tasks();
	diag( 'Found ' . scalar @tasks . ' scheduled tasks.' );
	foreach (@tasks) {
		if ( $_->id() eq $task_01_id ) {
			$found = $_->id();
			last;
		}
	}
	isnt( $found, undef, 'Code package ID retrieved.' );

	# cancel task
	$task_01->cancel_scheduled();
	$task_01_info =
	  $iron_worker_client->get_info_about_scheduled_task( 'id' => $task_01_id );
	is( $task_01_info->{'status'}, 'cancelled', 'Scheduled task is cancelled.' );
	diag('Scheduled task 1 is cancelled.');
	$task_02->cancel_scheduled();

    done_testing();
};

subtest 'Get task results, set progress' => sub {

	my ( $downloaded, $file_name ) =
		$iron_worker_client->download_code_package(
			'id'       => $code_package_id,
			'revision' => 1,
		);
	my $zipped_contents = $downloaded;
	is( $zipped_contents, $worker_as_zip_rev_01,
		'Code package matches the original when zipped.' );
	is(
		$file_name,
		( $unique_code_package_name_01 . '_1.zip' ),
		'Code package file name matches the original with "_1.zip" suffix.'
	);
    # Needless to compare unzipped package with the original.
    # If zipped packages/strings match, the original is intact!

	diag('First release downloaded.');
    done_testing();
};

subtest 'Clean up.' => sub {

	my $deleted =
	  $iron_worker_client->delete_code_package( 'id' => $code_package_id );
	is( $deleted, 1, 'Code package deleted.' );

	my @code_packages = $iron_worker_client->list_code_packages();
	my $found;
	foreach (@code_packages) {
		if ( $_->{'name'} eq $unique_code_package_name_01 ) {
			$found = $_->{'id'};
			last;
		}
	}
	is( $found, undef, 'Code package not exists. Delete confirmed.' );

	diag('Code package deleted.');
    done_testing();
};

END {
	diag('Activating END sequence.');
	diag('Ensure that the package is deleted even if test aborted.');
	$iron_worker_client->delete_code_package( 'id' => $code_package_id );
}

done_testing();

