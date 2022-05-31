#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;
use Mojo::Util qw(dumper);
use Firewall::Config::Connector::Device::Fortinet;

my $fw = Firewall::Config::Connector::Device::Fortinet->new(
  host     => '192.168.19.99',
  username => 'admin',
  password => '1234567',
  proto    => 'telnet'
);
say dumper $fw->getconfig();
