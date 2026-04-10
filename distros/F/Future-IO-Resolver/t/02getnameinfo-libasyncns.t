#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;

use Future::IO::Resolver;

Future::IO::Resolver::Using::LibAsyncNS::HAVE_LIBASYNCNS or
   plan skip_all => "Net::LibAsyncNS is not available";

@Future::IO::Resolver::BACKENDS = qw( Future::IO::Resolver::Using::LibAsyncNS );

do "./t/02getnameinfo.pl";
die $@ if $@;
