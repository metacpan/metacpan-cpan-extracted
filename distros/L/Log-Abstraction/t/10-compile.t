#!perl -w

use strict;
use warnings;

use Test::Needs 'Test::Compile';

my $test = Test::Compile->new();

# Log::Any is only a recommended dependency, so the adapter can't compile without it
my $have_log_any = eval { require Log::Any::Adapter::Base; 1 };

for my $file ($test->all_pm_files()) {
	if(($file =~ m{Log/Any/Adapter/Abstraction\.pm$}) && !$have_log_any) {
		$test->skip("$file: Log::Any not installed");
		next;
	}
	$test->ok($test->pm_file_compiles($file), "$file compiles");
}
$test->all_pl_files_ok();
$test->done_testing();
