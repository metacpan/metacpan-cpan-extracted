#!perl -w

use strict;
use Test::More tests => 10;
use File::Binary;
use Data::Dumper;

my $bin = File::Binary->new('t/le.fibonacci.n32.ints');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);



my %pos_2_value;

foreach (1..10) {
	my $key = $bin->tell();
	$pos_2_value{$key} = $bin->get_si32();
}


foreach my $key (keys %pos_2_value) {
	$bin->seek( $key );
	is( $bin->get_si32(), $pos_2_value{$key});
}

$bin->close();

