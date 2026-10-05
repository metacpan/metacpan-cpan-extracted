use v5.24;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Test2::V0;

use File::Spec;
use Imager;
use Imager::File::SIXEL;

# The .six files were produced by img2sixel from libsixel 1.10.5 and the
# .ppm files hold the same images as decoded by its sixel2png.

sub rgbSamples($img) {
	return join '', map { scalar $img->getsamples(y => $_, channels => [0, 1, 2], type => '8bit') } 0 .. $img->getheight - 1;
}

foreach my $name (qw(default p16 fixed)) {
	my $sixelFile = File::Spec->catfile('t', 'data', "libsixel-$name.six");
	my $expectedFile = File::Spec->catfile('t', 'data', "libsixel-$name.ppm");

	subtest $name => sub {
		my $expected = Imager->new(file => $expectedFile) or die Imager->errstr;
		my $img = Imager->new(file => $sixelFile);
		ok($img, 'decoded') or return diag(Imager->errstr);
		is([$img->getwidth, $img->getheight], [$expected->getwidth, $expected->getheight], 'size matches libsixel');
		ok(rgbSamples($img) eq rgbSamples($expected), 'pixels match libsixel');

		my $data = '';
		ok($img->write(data => \$data, type => 'sixel'), 're-encoded') or return diag($img->errstr);
		my $again = Imager->new;
		ok($again->read(data => $data, type => 'sixel'), 're-decoded') or return diag($again->errstr);
		ok(rgbSamples($again) eq rgbSamples($expected), 're-encoding a decoded image is lossless');
	};
}

done_testing;
