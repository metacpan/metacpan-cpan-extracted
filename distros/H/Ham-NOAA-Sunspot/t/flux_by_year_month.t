# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp@psyphi.net
# Created: 2016-12-31
#
use strict;
use warnings;
use IO::File;
use English qw(-no_match_vars);
use lib qw(lib);
use Ham::NOAA::Sunspot;
use Test::More tests => 1;

our $VERSION = q[0.0.2];

{
  my $o = Ham::NOAA::Sunspot->new();

  no warnings qw(redefine once);
  local *LWP::UserAgent::get = sub {
    my $io      = IO::File->new('t/data/predicted-sunspot-radio-flux.txt');
    local $RS   = undef;
    return HTTP::Response->new(200, "OK", [], <$io>);
  };

  is_deeply($o->flux_by_year_month(2017, 1), {
					      low       => 79.5,		 
					      high      => 91.5,
					      predicted => 85.5,
					     });	   
}
