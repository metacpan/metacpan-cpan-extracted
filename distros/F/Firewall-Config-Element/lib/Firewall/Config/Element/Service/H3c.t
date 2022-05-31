#!/usr/bin/env perl
use strict;
use warnings;

use Mojo::Util qw(dumper);

use Firewall::Config::Element::Service::H3c;
use Firewall::Config::Element::ServiceMeta::H3c;

my $ser = Firewall::Config::Element::Service::H3c->new(
  srvName  => 'any',
  protocol => 'any'
);
say dumper $ser->range;
