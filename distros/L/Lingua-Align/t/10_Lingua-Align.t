#!/usr/bin/perl
#-*-perl-*-


use strict;
use FindBin;
use lib $FindBin::Bin.'/../lib';

use Test;
BEGIN { plan tests => 1 };
use Lingua::Align;
ok(1); # If we made it this far, we're ok.

