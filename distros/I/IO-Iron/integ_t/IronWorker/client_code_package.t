#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use IO::String ();

use lib 't';
use lib 'integ_t';
require 'iron_io_integ_tests_common.pl';

plan tests => 6;

require IO::Iron::IronWorker::Client;

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
use Data::Dumper; $Data::Dumper::Maxdepth = 4;

diag("Testing IO::Iron::IronWorker::Client, Perl $], $^X");

## Test case
diag('Testing IO::Iron::IronWorker::Client');

my $worker_as_string_rev_01 = <<EOF;
#!/bin/sh
echo "Hello, World!"
EOF
my $worker_as_string_rev_02 = <<EOF;
#!/bin/sh
echo "Hello, World (Rev 2)!"
EOF
my $worker_as_zip_rev_01;
my $worker_as_zip_rev_02;


my $iron_worker_client;
my $unique_code_package_name_01;
my $unique_code_executable_name_01;
my $code_package_return_id;
my $code_package_id;
subtest 'Setup for testing' => sub {
	plan tests => 1;
	# Create an IronWorker client.
	$iron_worker_client = IO::Iron::IronWorker::Client->new(
		'config' => 'iron_worker.json' 
		);
	
	# Create a new code package name.
	$unique_code_package_name_01 = create_unique_code_package_name();
	$unique_code_executable_name_01 = $unique_code_package_name_01 . '.sh';
	
	my $zip = Archive::Zip->new();
	my $string_member = $zip->addString( $worker_as_string_rev_01, $unique_code_executable_name_01 );
	$string_member->desiredCompressionMethod( COMPRESSION_DEFLATED );
	my $io = IO::String->new($worker_as_zip_rev_01);
	{ no warnings 'once'; tie *IO, 'IO::String'; }
	$zip->writeToFileHandle($io);

	$zip = Archive::Zip->new();
	$string_member = $zip->addString( $worker_as_string_rev_02, $unique_code_executable_name_01 );
	$string_member->desiredCompressionMethod( COMPRESSION_DEFLATED );
	$io = IO::String->new($worker_as_zip_rev_02);
	{ no warnings 'once'; tie *IO, 'IO::String'; }
	$zip->writeToFileHandle($io);

	isnt($worker_as_string_rev_01, $worker_as_string_rev_02, "Zipped files are not equal.");

	diag("Compressed two versions of the worker with zip.");
};

my @send_message_ids;
subtest 'Upload worker' => sub {
	plan tests => 1;

	$code_package_return_id = $iron_worker_client->update_code_package(
		'name' => $unique_code_package_name_01, 
		'file' => $worker_as_zip_rev_01, 
		'file_name' => $unique_code_executable_name_01, 
		'runtime' => 'perl', 
		);
	isnt($code_package_return_id, undef, 'Code package upload successful.');
	diag("Returned new id: '$code_package_return_id'");
	
	diag("Code package rev 1 uploaded.");
};

subtest 'confirm worker upload' => sub {
	plan tests => 3;

	my @code_packages = $iron_worker_client->list_code_packages();
	foreach (@code_packages) {
		if($_->{'name'} eq $unique_code_package_name_01) {
			$code_package_id = $_->{'id'};
			last;
		}
	}
	isnt($code_package_id, undef, 'Code package ID retrieved.');
	diag("Discovered id: '$code_package_id'");
	is($code_package_return_id, $code_package_id, 'Code package ID retrieved matches with id got when uploading.');

	my $code_package = $iron_worker_client->get_info_about_code_package( 'id' => $code_package_id );
	is($code_package->{'name'}, $unique_code_package_name_01, 'Code package name matches with the uploaded package name.');

	diag("Worker rev 1 is uploaded.");
};

subtest 'Upload new release, query releases' => sub {
	plan tests => 3;

	$code_package_return_id = $iron_worker_client->update_code_package(
		'name' => $unique_code_package_name_01, 
		'file' => $worker_as_zip_rev_02, 
		'file_name' => $unique_code_executable_name_01, 
		'runtime' => 'perl', 
		);
	isnt($code_package_return_id, undef, 'Code package rev 2 uploaded.');
	diag("Code package rev 2 uploaded.");

	my @code_package_revisions = $iron_worker_client->list_code_package_revisions( 'id' => $code_package_id );
	is(scalar @code_package_revisions, 2, "Two code package revisions.");

	my $code_package = $iron_worker_client->get_info_about_code_package( 'id' => $code_package_id );
	is($code_package->{'rev'}, 2, 'Code package is revisions 2.');

	diag("Worker rev 2 uploaded.");
};

subtest 'First release downloaded' => sub {
	plan tests => 3;

	my ($downloaded, $file_name) = $iron_worker_client->download_code_package( 
		'id' => $code_package_id,
		'revision' => 1,
		);
	my $zipped_contents = $downloaded;
	is($zipped_contents, $worker_as_zip_rev_01, 'Code package matches the original when zipped.');
	is($file_name, ($unique_code_package_name_01 . '_1.zip'), 'Code package file name matches the original with "_1.zip" suffix.');

	my $io = IO::String->new($zipped_contents);
	tie *IO, 'IO::String';
	my $zip = Archive::Zip->new();
	$zip->readFromFileHandle($io);
	my $downloaded_unzipped = $zip->contents($unique_code_executable_name_01);
	is($downloaded_unzipped, $worker_as_string_rev_01, 'Code package matches the original unpacked.');

	diag("First release downloaded.");
};

subtest 'Clean up.' => sub {
	plan tests => 2;

	my $deleted = $iron_worker_client->delete_code_package( 'id' => $code_package_id );
	is($deleted, 1, 'Code package deleted.');

	my @code_packages = $iron_worker_client->list_code_packages();
	my $found;
	foreach (@code_packages) {
		if($_->{'name'} eq $unique_code_package_name_01) {
			$found = $_->{'id'};
			last;
		}
	}
	is($found, undef, 'Code package not exists. Delete confirmed.');

	diag("Code package deleted.");
};
