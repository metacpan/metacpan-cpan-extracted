#!/usr/bin/perl

use v5.14;
use warnings;

BEGIN { $ENV{PERL_FUTURE_NO_XS} = 1; }

do "./t/03then.pl";
die $@ if $@;
