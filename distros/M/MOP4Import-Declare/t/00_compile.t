#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
use Test::More;

use rlib qw!../..!;

BEGIN { use_ok 'MOP4Import::Declare' }
BEGIN { use_ok 'MOP4Import::Types' }

done_testing();
