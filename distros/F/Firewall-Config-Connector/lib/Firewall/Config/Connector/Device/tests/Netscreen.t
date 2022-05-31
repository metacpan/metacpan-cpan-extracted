#!/usr/bin/env perl
use strict;
use warnings;
use 5.018;
use Mojo::Util qw(dumper);
use Firewall::Config::Connector::Device::Netscreen;

my @commands = ("cat /etc/hosts");
$fw = Firewall::Config::Connector::Device::Netscreen->new( host => '192.168.19.20' );
my $aa = $fw->execCommands( \@commands );
say dumper $aa;
