#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.999_001';

# No POD coverage due to complaints about builtins when using Fatal.
use Test::Distribution ( distversion => 1, not => 'podcover' );
