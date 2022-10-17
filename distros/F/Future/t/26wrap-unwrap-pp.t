#!/usr/bin/perl

BEGIN { $ENV{PERL_FUTURE_NO_XS} = 1; }

do "./t/26wrap-unwrap.pl";
die $@ if $@;
