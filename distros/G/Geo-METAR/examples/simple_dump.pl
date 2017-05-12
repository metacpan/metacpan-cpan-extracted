#!/usr/bin/perl

# $Id: simple_dump.pl,v 1.1 2007/11/13 21:19:27 koos Exp $

# Example script for METAR.pm.

use Geo::METAR;

my $m = new Geo::METAR;
$m->metar("KFDY 251450Z 21012G21KT 8SM OVC065 04/M01 A3010 RMK 57014");
$m->dump;
exit;
