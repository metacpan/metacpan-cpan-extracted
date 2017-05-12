#!/usr/bin/perl -wT

use strict;

use Test::Most tests => 2;

use FCGI::Buffer;

isa_ok(FCGI::Buffer->new(), 'FCGI::Buffer', 'Creating FCGI::Buffer object');
ok(!defined(FCGI::Buffer::new()));
