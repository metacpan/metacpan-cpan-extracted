#!perl -w
use strict;
use Test::More;
use ExtUtils::Manifest 'fullcheck';

# by default EU::Manifest complains to STDERR, suppress that
$ExtUtils::Manifest::Quiet = 1;

my $dev_tests = -e '.svn';
if ($dev_tests) {
  plan tests => 2; # for local tests we check that there's no extras
}
else {
  plan tests => 1; # a user may have created junk playing with it
}

my ($missing, $extra) = fullcheck();

is_deeply($missing, [], "No files missing");
is_deeply($extra,   [], "No extra files")
  if $dev_tests;
