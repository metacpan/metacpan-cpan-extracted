#! perl

use Test::More;
use File::Temp qw//;

use Language::LispPerl;

my $test = Language::LispPerl::Evaler->new();

$test->load("core");
$test->load("file");

my ( $fh, $tempfile )  = File::Temp::tempfile(UNLINK => 1);
note($tempfile);
$test->eval("(def tempfile \"".$tempfile."\")");

ok($test->load("t/file.clp"), 'file operations');

done_testing();

