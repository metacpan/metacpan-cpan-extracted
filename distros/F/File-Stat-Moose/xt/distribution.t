#!/usr/bin/perl

use strict;
use warnings;

our $VERSION = '0.999_001';

# No POD coverage due to complaints about builtins when using Fatal.
use Test::Distribution ();
Test::Distribution->import( distversion => 1, not => [ 'pod', 'podcover', 'prereq' ] );
