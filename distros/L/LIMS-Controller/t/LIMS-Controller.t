#!/usr/bin/perl -w

use strict;


use Test::More tests => 4;
BEGIN { use_ok('LIMS::Base') };
BEGIN { use_ok('LIMS::Controller') };
BEGIN { use_ok('LIMS::Database::Util') };
BEGIN { use_ok('LIMS::Web::Interface') };
