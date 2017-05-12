use Test::More tests => 5;

use Image::Caa;
use Data::Dumper;


#
# create objects
#

sub test_dither {

	my ($dither, $compare) = @_;

	my $caa = Image::Caa->new('dither' => $dither, driver => 'DriverTest');

	$caa->draw_bitmap(0, 0, 1, 1);

	like($caa->{driver}->{buffer}, $compare, "Ditherer $dither output");
}

test_dither('DitherNone',	qr!\(7\:8\)\?\(7\:8\)\?\(13\:5\)\;\(13\:5\)\?!);
test_dither('DitherOrdered2',	qr!\(7\:8\)\?\(7\:8\)\?\(13\:5\)\=\(13\:5\)\?!);
test_dither('DitherOrdered4',	qr!\(7\:8\)\?\(7\:8\)\?\(13\:5\)\=\(13\:5\)\?!);
test_dither('DitherOrdered8',	qr!\(7\:8\)\?\(7\:8\)\?\(13\:5\)\=\(13\:5\)\?!);
test_dither('DitherRandom',	qr!\(7\:8\).\(7\:8\).\(13\:5\).\(13\:5\).!);