#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use_ok( "Net::Async::FastCGI" );
use_ok( "FCGI::Async" );
