#!/usr/bin/perl

use Test::Most;

use lib 't/lib';

use_ok( 'Graphics::ColorNames' );

my $sxw = Graphics::ColorNames->new( qw/ X Test / );
isa_ok $sxw, 'Graphics::ColorNames';

is $sxw->hex('darkgreen'), '006400', 'DarkGreen (X)';

my $swx = Graphics::ColorNames->new( qw/ Test X / );
isa_ok $swx, 'Graphics::ColorNames';

is $swx->hex('darkgreen'), '008000', 'DarkGreen (Test)';

done_testing;
