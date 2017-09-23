#!/usr/bin/perl -w

#
# t/01-run.t
#
# Developed by Sheeju Alex <sheeju@exceleron.com>
#

use FindBin;
use lib 't';
use lib "$FindBin::Bin/../lib";

# Load all the testcases
use Test::Class::Load qw(t);

Test::Class->runtests;
