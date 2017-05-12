#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

require IO::Iron;
require IO::Iron::IronWorker::Client;

plan tests => 20;

BEGIN {
	use_ok('IO::Iron::IronWorker::Client') || print "Bail out!\n";
	can_ok('IO::Iron::IronWorker::Client', 'new');

	can_ok('IO::Iron::IronWorker::Client', 'list_code_packages');
	can_ok('IO::Iron::IronWorker::Client', 'update_code_package');
	can_ok('IO::Iron::IronWorker::Client', 'get_info_about_code_package');
	can_ok('IO::Iron::IronWorker::Client', 'delete_code_package');
	can_ok('IO::Iron::IronWorker::Client', 'download_code_package');
	can_ok('IO::Iron::IronWorker::Client', 'list_code_package_revisions');

	can_ok('IO::Iron::IronWorker::Client', 'tasks');
	can_ok('IO::Iron::IronWorker::Client', 'queue');
	can_ok('IO::Iron::IronWorker::Client', 'get_info_about_task');

	can_ok('IO::Iron::IronWorker::Client', 'scheduled_tasks');
	can_ok('IO::Iron::IronWorker::Client', 'schedule');
	can_ok('IO::Iron::IronWorker::Client', 'get_info_about_scheduled_task');

	can_ok('IO::Iron::IronWorker::Task', 'id');
	can_ok('IO::Iron::IronWorker::Task', 'log');
	can_ok('IO::Iron::IronWorker::Task', 'cancel');
	can_ok('IO::Iron::IronWorker::Task', 'set_progress');
	can_ok('IO::Iron::IronWorker::Task', 'retry');
	can_ok('IO::Iron::IronWorker::Task', 'cancel_scheduled');

}

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.

diag('Testing IO::Iron::IronCache::Client '
   . ($IO::Iron::IronWorker::Client::VERSION ? "($IO::Iron::IronWorker::Client::VERSION)" : '(no version)')
   . ", Perl $], $^X");

