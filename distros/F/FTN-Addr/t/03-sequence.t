#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 144;

BEGIN {
	use_ok( 'FTN::Addr' );
}

my @test_addrs = (
# from squish doc: 1:12/34 45 23/45 2:23/56 67 34/67
                  '1:12/34' => ['fidonet', 1, 12, 34, 0, '1:12/34', '1:12/34.0', '1:12/34@fidonet', '1:12/34.0@fidonet'],
		  '45' => ['fidonet', 1, 12, 45, 0, '1:12/45', '1:12/45.0', '1:12/45@fidonet', '1:12/45.0@fidonet'],
		  '23/45' => ['fidonet', 1, 23, 45, 0, '1:23/45', '1:23/45.0', '1:23/45@fidonet', '1:23/45.0@fidonet'],
		  '2:23/56' => ['fidonet', 2, 23, 56, 0, '2:23/56', '2:23/56.0', '2:23/56@fidonet', '2:23/56.0@fidonet'],
		  '67' => ['fidonet', 2, 23, 67, 0, '2:23/67', '2:23/67.0', '2:23/67@fidonet', '2:23/67.0@fidonet'],
		  '34/67' => ['fidonet', 2, 34, 67, 0, '2:34/67', '2:34/67.0', '2:34/67@fidonet', '2:34/67.0@fidonet'],
# from config
                  '2:451/30' => ['fidonet', 2, 451, 30, 0, '2:451/30', '2:451/30.0', '2:451/30@fidonet', '2:451/30.0@fidonet'],
		  '31.1' => ['fidonet', 2, 451, 31, 1, '2:451/31.1', '2:451/31.1', '2:451/31.1@fidonet', '2:451/31.1@fidonet'],
		  '.4' => ['fidonet', 2, 451, 31, 4, '2:451/31.4', '2:451/31.4', '2:451/31.4@fidonet', '2:451/31.4@fidonet'],
		  '5020/1042' => ['fidonet', 2, 5020, 1042, 0, '2:5020/1042', '2:5020/1042.0', '2:5020/1042@fidonet', '2:5020/1042.0@fidonet'],
		  '451/26' => ['fidonet', 2, 451, 26, 0, '2:451/26', '2:451/26.0', '2:451/26@fidonet', '2:451/26.0@fidonet'],
		  '16' => ['fidonet', 2, 451, 16, 0, '2:451/16', '2:451/16.0', '2:451/16@fidonet', '2:451/16.0@fidonet'],
		  '23' => ['fidonet', 2, 451, 23, 0, '2:451/23', '2:451/23.0', '2:451/23@fidonet', '2:451/23.0@fidonet'],
		  );
my $base;
my $node;

while (@test_addrs) {
  my $t_addr = shift @test_addrs;
  my $t_exp = shift @test_addrs;

  my $t = defined $node ? $node : 'FTN::Addr';

  $node = $t -> new( $t_addr )
    or die 'no';

  ok(defined $node, "new('$t_addr') returned something");
  ok($node -> isa('FTN::Addr'), "  and it's the right class\t($t_addr) in sequence");
  is($node -> domain, $t_exp -> [0], "  domain\t($t_addr) in sequence");
  is($node -> zone, $t_exp -> [1], "  zone\t($t_addr) in sequence");
  is($node -> net, $t_exp -> [2], "  net\t($t_addr) in sequence");
  is($node -> node, $t_exp -> [3], "  node\t($t_addr) in sequence");
  is($node -> point, $t_exp -> [4], "  point\t($t_addr) in sequence");
  is($node -> s4, $t_exp -> [5], "  short 4d\t($t_addr) in sequence");
  is($node -> f4, $t_exp -> [6], "  full 4d\t($t_addr) in sequence");
  is($node -> s5, $t_exp -> [7], "  short 5d\t($t_addr) in sequence");
  is($node -> f5, $t_exp -> [8], "  full 5d\t($t_addr) in sequence");
}
