#!/usr/bin/perl

use v5.14;
use warnings;

BEGIN { $ENV{PERL_FUTURE_NO_XS} = 1; }

do "./t/06followed_by.pl";
die $@ if $@;
