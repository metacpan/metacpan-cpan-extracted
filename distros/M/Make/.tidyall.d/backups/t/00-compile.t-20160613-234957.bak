use strict;
use warnings;

use Test::More;

eval "use Test::Compile";
plan skip_all => "Test::Compile required for testing compilation"
  if $@;

my @scripts = qw(pmake);
my $test    = Test::Compile->new();
$test->all_files_ok();
$test->pl_file_compiles($_) for @scripts;
$test->done_testing;
