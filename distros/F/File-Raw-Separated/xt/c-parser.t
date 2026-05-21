use strict;
use warnings;
use Test::More;
use Config;
use File::Spec;
use File::Temp qw(tempdir);

# Author-only: drives the standalone C parser test (t/c/parser_test.c)
# through $Config{cc}. Skips when no compiler is available so a CPAN
# tester without a usable cc still installs cleanly.
plan skip_all => 'AUTHOR_TESTING / RELEASE_TESTING required'
    unless $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING};

my $cc = $Config{cc} || 'cc';
my $exit = system("$cc --version >/dev/null 2>&1");
plan skip_all => "$cc not invocable"
    if $exit != 0;

my $tmp = tempdir(CLEANUP => 1);
my $exe = File::Spec->catfile($tmp, 'parser_test');

# Build (no sanitizers — those go through docker, not the stock cc here,
# so the harness stays portable across testers).
my @cmd = (
    $cc,
    '-std=c99', '-Wall', '-Wextra',
    '-Iinclude',
    'separated_parser.c', 't/c/parser_test.c',
    '-o', $exe,
);
$exit = system(@cmd);
ok($exit == 0, "compile: @cmd")
    or BAIL_OUT("compile failed");

# Run all fixtures.
$exit = system($exe);
is($exit, 0, 'all C parser fixtures pass');

done_testing;
