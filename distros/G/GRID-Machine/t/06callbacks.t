#!/usr/local/bin/perl -w
use strict;
use Test::More tests => 6;
BEGIN { use_ok('GRID::Machine', 'is_operative') };

sub findVersion {
  my $pv = `perl -v`;
  my ($v) = $pv =~ /v(\d+\.\d+)\.\d+/;

  $v ? $v : 0;
}


my $test_exception_installed;
BEGIN {
  $test_exception_installed = 1;
  eval { require Test::Exception };
  $test_exception_installed = 0 if $@;
}

my $host = $ENV{GRID_REMOTE_MACHINE} || '';

my $machine;
SKIP: {
    skip "Remote not operative or Test::Exception not installed", 5
  unless  $host and $test_exception_installed and is_operative('ssh', $host);

########################################################################

  Test::Exception::lives_ok { 
    $machine = GRID::Machine->new(host => $host);
  } 'No fatals creating a GRID::Machine object';

########################################################################

my $r = $machine->sub( 
  fact => q{
    my $x = shift;

    if ($x > 1) {
      my ($r) = localfact($x-1);
      return $x*$r;
    }
    else {
      return 1;
    }
  } 
);
ok($r->ok, "installed remote sub fact");

$r = $machine->callback( 

    localfact => sub {
      my $x = shift;

      if ($x > 1) {
        my $r = $machine->fact($x-1)->result;
        return $x*$r;
      }
      else {
        return 1;
      }

    } 

);
ok($r->ok, "installed callback localfact");

my $n = 5;

$r = $machine->fact($n);

ok($r->ok, "called recursive RPC without errors");

is($r->result, 120, "recursive RPC and callbacks");


} # end SKIP block

