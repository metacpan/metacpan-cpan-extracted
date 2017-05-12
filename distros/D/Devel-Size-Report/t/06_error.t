#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  $| = 1; 
  plan tests => 1;
  chdir 't' if -d 't';
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  }

use Devel::Size::Report qw/ report_size /;

eval { report_size("1", 123) };

like ($@, qr/needs a hash ref for options/, 'Need hash ref');

