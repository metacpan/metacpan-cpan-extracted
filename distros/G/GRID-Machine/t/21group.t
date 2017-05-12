#!/usr/local/bin/perl -w
use strict;
our (
$nt, 
$nt2,
$nt3,
$nt4,
$nt5,
$nt6,
$nt7,
);

BEGIN {
$nt  = 2;
$nt2 = 1;
$nt3 = 1;
$nt4 = 3;
$nt5 = 0;
$nt6 = 0;
$nt7 = 0;
};

use Test::More;

BEGIN { 
  use_ok('GRID::Machine', 'is_operative');
  use_ok('GRID::Machine::Group');
};

my $test_exception_installed;
BEGIN {
  $test_exception_installed = 1;
  eval { require Test::Exception };
  $test_exception_installed = 0 if $@;
}

my @MACHINE_NAMES = split /\s+/, $ENV{MACHINES} || '';
@MACHINE_NAMES = ('', '') unless @MACHINE_NAMES;

my $host = ($ENV{GRID_REMOTE_MACHINE} || ''); 
my $operative = 0;
if ($ENV{DEVELOPER}) {
  $operative = is_operative('ssh', $host,'perldoc -l Inline::C');

  for (@MACHINE_NAMES) {
    $operative = ($operative and is_operative('ssh', $_));
  }
}


SKIP: {
  skip "t/smallpar.pl not found", $nt2 unless ( $host && $operative &&  @MACHINE_NAMES && -r "t/smallpar.pl");

  my $r = qx{perl -I./lib/ t/smallpar.pl 2>&1};
  $r = eval $r;
  
  my $expected = bless( [
                 bless( { 'stderr' => '',
                          'errmsg' => '',
                          'type' => 'RETURNED',
                          'stdout' => '',
                          'errcode' => 0,
                          'results' => [ 1 ]
                        }, 'GRID::Machine::Result' ),
                 bless( {
                          'stderr' => '',
                          'errmsg' => '',
                          'type' => 'RETURNED',
                          'stdout' => '',
                          'errcode' => 0,
                          'results' => [ 1 ]
                        }, 'GRID::Machine::Result' )
               ], 'GRID::Machine::Group::Result' );

  is_deeply($r, $expected,'less args than machines. Using void()');
}


SKIP: {
  skip "t/smallpar1.pl not found", $nt3 unless ( $host && $operative &&  @MACHINE_NAMES && -r "t/smallpar1.pl");

  my $r = qx{perl -I./lib/ t/smallpar1.pl 2>&1};
  $r = eval $r;
  
  my $expected = bless( [
                 bless( { 'stderr' => '',
                          'errmsg' => '',
                          'type' => 'RETURNED',
                          'stdout' => '',
                          'errcode' => 0,
                          'results' => [ 1 ]
                        }, 'GRID::Machine::Result' ),
                 bless( {
                          'stderr' => '',
                          'errmsg' => '',
                          'type' => 'RETURNED',
                          'stdout' => '',
                          'errcode' => 0,
                          'results' => [ 1 ]
                        }, 'GRID::Machine::Result' )
               ], 'GRID::Machine::Group::Result' );

  is_deeply($r, $expected,'less args than machines. Using replicate value');
}

SKIP: {
  skip "t/smallpar3.pl not found", $nt4 unless ( $host && $operative &&  @MACHINE_NAMES && -r "t/smallpar3.pl");

  my $r = qx{perl -I./lib/ t/smallpar3.pl 2>&1};
  $r = eval $r;
  
  my $expected = bless( [
                 bless( {
                          'stderr' => '',
                          'errmsg' => '',
                          'type' => 'RETURNED',
                          'stdout' => '',
                          'errcode' => 0,
                          'results' => [
                                         {
                                           'sq' => 1
                                         }
                                       ]
                        }, 'GRID::Machine::Result' ),
                 bless( {
                          'stderr' => '',
                          'errmsg' => '',
                          'type' => 'RETURNED',
                          'stdout' => '',
                          'errcode' => 0,
                          'results' => [
                                         {
                                           'sq' => 4
                                         }
                                       ]
                        }, 'GRID::Machine::Result' )
               ], 'GRID::Machine::Group::Result' );


  my $m = $expected;
  $m = $r if @MACHINE_NAMES < 2; 

  isa_ok($r, 'GRID::Machine::Group::Result');

  is_deeply($r->[$_], $expected->[$_],'less args than machines. Using replicate code. Arrayref returned') for @$m;
}

SKIP: {
  skip "t/smallpar4.pl not found", $nt4 unless ($host && @MACHINE_NAMES && $operative &&  -r "t/smallpar4.pl");

  my $r = qx{perl -I./lib/ t/smallpar4.pl 2>&1};
  $r = eval $r;
  
  my $expected = bless( [
                 bless( {
                          'stderr' => '',
                          'errmsg' => '',
                          'type' => 'RETURNED',
                          'stdout' => '',
                          'errcode' => 0,
                          'results' => [
                                         {
                                           'sq' => 1
                                         }
                                       ]
                        }, 'GRID::Machine::Result' ),
                 bless( {
                          'stderr' => '',
                          'errmsg' => '',
                          'type' => 'RETURNED',
                          'stdout' => '',
                          'errcode' => 0,
                          'results' => [
                                         {
                                           'sq' => 4
                                         }
                                       ]
                        }, 'GRID::Machine::Result' )
               ], 'GRID::Machine::Group::Result' );


  my $m = $expected;
  $m = $r if @MACHINE_NAMES < 2; 

  isa_ok($r, 'GRID::Machine::Group::Result');

  is_deeply($r->[$_], $expected->[$_],'less args than machines. Using replicate code. Values returned') for @$m;
}

done_testing;
