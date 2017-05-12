#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

BEGIN { use_ok('Log::Log4perl::Layout::LTSV'); }
BEGIN { use_ok('Log::Log4perl'); }

my $layout = Log::Log4perl::Layout::LTSV->new();
isa_ok( $layout, 'Log::Log4perl::Layout::LTSV' );

can_ok( $layout, ('render') );
