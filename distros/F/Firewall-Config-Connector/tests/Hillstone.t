#!/usr/bin/env perl

use strict;
use warnings;
use 5.016;
use Mojo::Util qw(dumper);
use Firewall::Config::Connector::Device::Hillstone;

my $fw = Firewall::Config::Connector::Device::Hillstone->new(
  host     => '172.16.2.186',
  username => 'hillstone',
  password => 'hillstone',
  proto    => 'ssh'
);
say dumper $fw->getconfig();
