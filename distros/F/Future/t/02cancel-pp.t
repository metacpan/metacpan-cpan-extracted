#!/usr/bin/perl

use v5.20;
use warnings;

BEGIN { $ENV{PERL_FUTURE_NO_XS} = 1; }

do "./t/02cancel.pl";
die $@ if $@;
