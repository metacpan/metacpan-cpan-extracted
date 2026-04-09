#!/usr/bin/perl

use v5.20;
use warnings;

use Future::IO::Resolver;
@Future::IO::Resolver::BACKENDS = qw( Future::IO::Resolver::Using::Socket );

do "./t/01getaddrinfo.pl";
die $@ if $@;
