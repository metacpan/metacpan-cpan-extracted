#!perl -T

use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok( 'Log::Log4perl::Layout::GELF' ); }

my $layout = Log::Log4perl::Layout::GELF->new();
isa_ok($layout, "Log::Log4perl::Layout::GELF");

can_ok($layout, ("render"));
