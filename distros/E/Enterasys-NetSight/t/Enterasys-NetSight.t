#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 1;

use SOAP::Lite;
BEGIN { use_ok('Enterasys::NetSight') };
