#!/usr/local/bin/perl -w
use strict;
use Test::More tests => 6;
sub findVersion {
  my $pv = `perl -v`;
  my ($v) = $pv =~ /v(\d+\.\d+)\.\d+/;

  $v ? $v : 0;
}
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
    skip "Remote not operative or Test::Exception not installed", 5
  unless $host and  $test_exception_installed and is_operative('ssh', $host);

########################################################################

  Test::Exception::lives_ok { 
    $machine = GRID::Machine->new(host => $host);
  } 'No fatals creating a GRID::Machine object';

########################################################################

sub test_callback {
  return shift()+1;
} 

my $machine = GRID::Machine->new(host => $host);

my $r = $machine->sub( remote => q{
    return 1+test_callback(2);
} );
ok($r->ok, "remote sub installed");

$r = $machine->callback( 'test_callback' );
ok($r->ok, "callback made of named local sub"); 

$r = $machine->remote();
ok($r->noerr, "no errors on RPC");

is($r->result, 4, "result from RPC and named callback");

} # end SKIP block

