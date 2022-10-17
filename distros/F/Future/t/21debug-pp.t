#!/usr/bin/perl

BEGIN { $ENV{PERL_FUTURE_NO_XS} = 1; }

do "./t/21debug.pl";
die $@ if $@;
