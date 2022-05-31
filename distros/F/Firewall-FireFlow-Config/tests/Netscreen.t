#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use Mojo::Util qw(dumper);
my $name = File::Basename::basename($0);
use 5.018;

#use Firewall::DBI::Oracle;
use Firewall::FireFlow::Config::Netscreen;
if ( scalar @ARGV == 0 ) {
  print("ERROR: 缺少输入参数\n");
  exit;
}

my $config = new Firewall::FireFlow::Config::Netscreen;

my $conn     = $config->connect( $ARGV[0], $ARGV[1], $ARGV[2] );
my @commands = (
  "set policy top from Untrust to NetBankDMZ Host_192.168.33.15 Host_192.168.36.62 http permit",
  "set policy id XXXXXX",
  "set service tcp_8080", "exit"
);

say dumper $config->execCommands( $conn, \@commands );

#格式 ./search.pl 'src|natSrc' 'dst|natDst' srv
#time ./search.pl 10.31.103.163/32 10.8.21.48/32 tcp/23
