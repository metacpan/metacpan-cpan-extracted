#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
plan tests => 4;

use_ok( 'MarpaX::Languages::PowerBuilder::PBR' )       || print "Bail out!\n";

my $parser = MarpaX::Languages::PowerBuilder::PBR->new;
is( ref($parser), 'MarpaX::Languages::PowerBuilder::PBR', 'testing new');
	
my $DATA = <<'DATA';
picture01.jpg
folder\picture02.bmp
mylib.pbl(d_users)
DATA
my $parsed = $parser->parse( $DATA );
is( $parsed->{error}, '', 'testing parse(FH) without error');

my $got = $parsed->{recce}->value;
my $expected = [
		{ file => 'picture01.jpg' },
		{ file => 'folder\picture02.bmp' },
		{ lib => 'mylib.pbl', entry => 'd_users' },
	];

is_deeply( $got, \$expected, 'testing parse(FH) value');
