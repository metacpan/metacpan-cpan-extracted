#!/usr/bin/perl

use blib;
use strict;
use warnings;
use Test::More tests => 3;
use Test::NoWarnings;

BEGIN{
  use_ok('HTML::StickyForm');
  use_ok('HTML::StickyForm::RequestHash');
}
