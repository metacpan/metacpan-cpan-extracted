#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/unit";

use Test::Class::Load "$FindBin::RealBin/unit";

Test::Class->runtests();
