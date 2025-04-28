#!/usr/bin/env perl

use feature qw/say unicode_strings/;
use open qw(:std :utf8);
use strict;
use warnings;
use warnings qw(FATAL utf8);

use Lingua::EN::GivenNames::Database;

# -----------------------------------------------

Lingua::EN::GivenNames::Database -> new -> report_statistics;
