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
  unless  $host and $test_exception_installed and is_operative('ssh', $host);

########################################################################

  Test::Exception::lives_ok { 
    $machine = GRID::Machine->new(host => $host);
  } 'No fatals creating a GRID::Machine object';

########################################################################

my $r = $machine->sub( remote => q{
    my $rsub = shift;

    my $retval = $rsub->();
    return  1+$retval;
} );

ok($r->ok, "installed remote sub");

my $a =  $machine->callback( 
           sub { return 5; } 
         );

$r = $machine->remote( $a );
ok($r->noerr, "No errors not died on call to remote sub");

$r = $machine->remote( $a );
ok($r->noerr, "Twice: No errors not died on call to remote sub");

is($r->result, 6, "returned value from anonymous callback");

} # end SKIP block

