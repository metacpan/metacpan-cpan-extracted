#!/usr/bin/perl

use 5.026;
use utf8;
use strict;
use warnings;

use Device::Yeelight;

my $yeelight = Device::Yeelight->new;

say "Discovering devices...";
say "+ Discovered device $_->{id} ($_->{model})"
  foreach ( @{ $yeelight->search } );
say
"\nDevice $_->{id} ($_->{name}) supports following methods\n\t@{$_->{support}}"
  foreach ( @{ $yeelight->{devices} } );
