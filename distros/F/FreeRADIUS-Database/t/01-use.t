#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw( no_plan );

use_ok('FreeRADIUS::Database');
use_ok('FreeRADIUS::Database::Storage');
use_ok('FreeRADIUS::Database::Storage::Replicated');
