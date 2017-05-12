#!/usr/local/bin/perl -w
use strict;
my $numtests;
BEGIN {
$numtests = 3;
}

use Test::More tests => $numtests;
BEGIN { use_ok('GRID::Machine', 'is_operative') };

my $test_exception_installed;
BEGIN {
  $test_exception_installed = 1;
  eval { require Test::Exception };
  $test_exception_installed = 0 if $@;
}

my $host = $ENV{GRID_REMOTE_MACHINE} || '';

my $machine;
SKIP: {
    skip "Remote not operative or Test::Exception not installed", $numtests-1
  unless $test_exception_installed and  $host && is_operative('ssh', $host);

########################################################################

  Test::Exception::lives_ok { 
    $machine = GRID::Machine->new(
      host => $host,
      startenv => { ONE => 1, TWO => '2 2', 'THREE FOUR' => 3}
    );
  } 'No fatals creating a GRID::Machine object';

########################################################################

my $r = $machine->eval( q{
  print "$ENV{ONE}\n";
  print "$ENV{TWO}\n";
  print "$ENV{'THREE FOUR'}\n";
});

like("$r", qr{^1\s2\s2\s3\s$}, "startenv");

} # end SKIP block

