#!/usr/bin/env perl

use feature qw/say unicode_strings/;
use open qw(:std :utf8);
use strict;
use warnings;
use warnings qw(FATAL utf8);

use Lingua::EN::GivenNames::Database::Create;

# ----------------------------

Lingua::EN::GivenNames::Database::Create -> new(verbose => 2) -> drop_all_tables;
