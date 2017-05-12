#!/usr/bin/perl

use blib;
use strict;
use warnings;
use Test::More tests => 4;
use Test::NoWarnings;

BEGIN{ use_ok('HTML::StickyForms'); }
BEGIN{ use_ok('HTML::StickyForm'); }

is($HTML::StickyForms::VERSION,$HTML::StickyForm::VERSION,'same version');
