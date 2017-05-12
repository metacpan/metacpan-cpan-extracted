#!/usr/bin/perl -w

use strict;
use Test::Simple tests => 1;
use Lingua::Charsets;

ok ( Lingua::Charsets->new );
