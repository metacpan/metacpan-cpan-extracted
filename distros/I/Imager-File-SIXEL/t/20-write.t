use v5.24;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Test2::V0;

use File::Path qw(make_path);
use Imager;
use Imager::File::SIXEL;

sub encode($img, %opts) {
	my $data = '';
	return $img->write(data => \$data, type => 'sixel', %opts) ? $data : undef;
}

sub encodeError($img, %opts) {
	my $data = '';
	return $img->write(data => \$data, type => 'sixel', %opts) ? undef : $img->errstr;
}

sub decode($data) {
	my $img = Imager->new;
	$img->read(data => $data, type => 'sixel') or die $img->errstr;
	return $img;
}

# colour register definitions as { register => [r, g, b] } in percent
sub registers($data) {
	my %registers;
	while ($data =~ /#(\d+);2;(\d+);(\d+);(\d+)/g) {
		$registers{$1} = [$2, $3, $4];
	}
	return \%registers;
}

sub percentSample($percent) {
	return int(($percent * 255 + 50) / 100);
}

# RGB samples of an image as one string, for exact comparisons
sub rgbSamples($img) {
	return join '', map { scalar $img->getsamples(y => $_, channels => [0, 1, 2], type => '8bit') } 0 .. $img->getheight - 1;
}

# RGB samples of one row as a list
sub rowSamples($img, $y) {
	return unpack 'C*', scalar $img->getsamples(y => $y, channels => [0, 1, 2], type => '8bit');
}

sub psnr($original, $decoded) {
	my $originalSamples = rgbSamples($original);
	my $decodedSamples = rgbSamples($decoded);
	my $squared = 0;
	for my $i (0 .. length($originalSamples) - 1) {
		my $d = ord(substr($originalSamples, $i, 1)) - ord(substr($decodedSamples, $i, 1));
		$squared += $d * $d;
	}
	return 99 unless $squared;
	return 10 * log(255 * 255 * length($originalSamples) / $squared) / log(10);
}

# a deterministic pseudo random sequence, so that failures reproduce
{
	my $state = 12345;

	sub pseudoRandom($limit) {
		$state = ($state * 1103515245 + 12345) % 2147483648;
		return int($state / 2147483648 * $limit);
	}
}

# a smooth image with thousands of colours
sub gradientImage($width, $height) {
	my $img = Imager->new(xsize => $width, ysize => $height);
	for my $y (0 .. $height - 1) {
		my @row = map {
			Imager::Color->new(
				int(255 * $_ / ($width - 1)),
				int(255 * $y / ($height - 1)),
				int(128 + 127 * sin(($_ + $y) / 9)),
			)
		} 0 .. $width - 1;
		$img->setscanline(y => $y, pixels => \@row);
	}
	return $img;
}

# pixels drawn from colours SIXEL represents exactly
sub representableImage($width, $height, $colorCount) {
	my @colors = map { Imager::Color->new(map { percentSample(pseudoRandom(101)) } 1 .. 3) } 1 .. $colorCount;
	my $img = Imager->new(xsize => $width, ysize => $height);
	for my $y (0 .. $height - 1) {
		$img->setscanline(y => $y, pixels => [map { $colors[pseudoRandom(scalar @colors)] } 1 .. $width]);
	}
	return $img;
}

subtest 'stream structure' => sub {
	my $img = Imager->new(xsize => 4, ysize => 7);
	$img->box(filled => 1, color => '#FF0000');
	is(encode($img), "\eP0;0;0q\"1;1;4;7#0;2;100;0;0#0!4~-!4\@\e\\", 'exact stream for a solid image');

	my $data = encode(gradientImage(50, 20));
	ok($data !~ /[^\x20-\x7E\e]/, 'only printable ASCII and ESC are written');
};

subtest 'images with few colours round trip exactly' => sub {
	foreach my $size ([1, 1], [1, 5], [1, 6], [1, 7], [3, 13], [17, 12], [64, 37]) {
		my $img = representableImage($size->@*, 40);
		my $decoded = decode(encode($img));
		is([$decoded->getwidth, $decoded->getheight], $size, "size $size->@*");
		ok(rgbSamples($decoded) eq rgbSamples($img), "pixels of $size->@*");
	}

	my $img = Imager->new(xsize => 2, ysize => 1);
	$img->setpixel(x => 1, y => 0, color => [1, 0, 0]);
	is(scalar keys registers(encode($img))->%*, 1, 'colours that round alike share a register');
};

subtest 'images with many colours' => sub {
	foreach my $dither (qw(none ordered diffusion)) {
		my $img = gradientImage(96, 64);
		my $data = encode($img, sixel_dither => $dither);
		ok($data, "$dither encoded") or next;
		ok(keys(registers($data)->%*) <= 256, "$dither defines at most 256 registers");
		my $quality = psnr($img, decode($data));
		ok($quality > 27, "$dither quality") or diag("PSNR $quality");
	}

	my $limited = encode(gradientImage(96, 64), sixel_max_colors => 16);
	ok(keys(registers($limited)->%*) <= 16, 'sixel_max_colors limits the registers');

	my $exact = representableImage(20, 20, 12);
	ok(keys(registers(encode($exact, sixel_max_colors => 8))->%*) <= 8,
		'an image with more colours than sixel_max_colors is reduced');

	is(encode(gradientImage(96, 64)), encode(gradientImage(96, 64)), 'output is deterministic');
};

subtest 'nearest colours without dithering' => sub {
	my $img = Imager->new(xsize => 2, ysize => 1);
	$img->setpixel(x => 1, y => 0, color => '#030303');
	my $decoded = decode(encode($img, colors => ['#000000', '#030303'], sixel_dither => 'none'));
	is([rowSamples($decoded, 0)], [0, 0, 0, 3, 3, 3], 'each pixel takes its exactly nearest colour');
};

subtest 'webmap palette' => sub {
	my $data = encode(gradientImage(40, 30), sixel_palette => 'webmap');
	ok($data, 'encoded') or return;
	my @components = map { $_->@* } values %{registers($data)};
	ok(@components, 'registers defined');
	is([grep { $_ % 20 } @components], [], 'every component is a web-safe level');

	my $paletted = Imager->new(xsize => 4, ysize => 4, type => 'paletted');
	$paletted->addcolors(colors => [Imager::Color->new('#123456')]);
	is(registers(encode($paletted, sixel_palette => 'webmap', sixel_dither => 'none')), { 8 => [0, 20, 40] }, 'webmap takes precedence over the image palette');
};

subtest 'caller supplied palette' => sub {
	my $data = encode(gradientImage(32, 18), colors => ['#FF0000', [0, 0, 255], Imager::Color->new(0, 255, 0)], sixel_dither => 'none');
	ok($data, 'encoded') or return;
	my %expected = map { $_ => 1 } '100 0 0', '0 0 100', '0 100 0';
	my @defined = map { "$_->@*" } values registers($data)->%*;
	ok(@defined && @defined <= 3, 'only palette colours are defined');
	is([grep { !$expected{$_} } @defined], [], 'registers hold the palette, given as string, array and object');

	my $grey = Imager->new(xsize => 16, ysize => 6);
	$grey->box(filled => 1, color => '#808080');
	my $dithered = decode(encode($grey, colors => ['#000000', '#FFFFFF'], sixel_dither => 'diffusion'));
	my %seen = map { $_ => 1 } rowSamples($dithered, 2);
	is([sort { $a <=> $b } keys %seen], [0, 255], 'the palette is dithered as set by sixel_dither');

	my $img = gradientImage(8, 6);
	encode($img, colors => ['red']);
	is($img->tags(name => 'colors'), undef, 'colors is not stored as a tag');

	like(encodeError(gradientImage(8, 6), colors => 'red'),             qr/colors must be an array reference/,   'colors must be an array');
	like(encodeError(gradientImage(8, 6), colors => []),                qr/colors must hold from 1 to 256/,      'empty palette');
	like(encodeError(gradientImage(8, 6), colors => [('red') x 257]),   qr/colors must hold from 1 to 256/,      'oversized palette');
	like(encodeError(gradientImage(8, 6), colors => ['no-such-color']), qr/colors entry 0 is not a valid color/, 'invalid colour');
	like(encodeError(gradientImage(8, 6), colors => ['red', undef]),    qr/colors entry 1 is not a valid color/, 'undefined colour');
	like(encodeError(gradientImage(8, 6), colors => [[300, 0, 0]]),     qr/colors entry 0 is not a valid color/, 'RGB value out of range');
};

subtest 'paletted images' => sub {
	my $img = Imager->new(xsize => 6, ysize => 6, type => 'paletted');
	$img->addcolors(colors => [map { Imager::Color->new($_) } '#000000', '#FF0000', '#00FF00', '#0000FF']);
	$img->box(filled => 1, color => '#0000FF');
	$img->box(filled => 1, color => '#00FF00', xmax => 2);
	my $data = encode($img);
	is(registers($data), { 2 => [0, 100, 0], 3 => [0, 0, 100] }, 'used palette entries become their registers');
	ok(rgbSamples(decode($data)) eq rgbSamples($img), 'pixels round trip');

	my $alike = Imager->new(xsize => 2, ysize => 1, type => 'paletted');
	$alike->addcolors(colors => [map { Imager::Color->new($_->@*) } [0, 0, 0], [1, 0, 0]]);
	$alike->setpixel(x => 1, y => 0, color => [1, 0, 0]);
	is(registers(encode($alike)), { 0 => [0, 0, 0] }, 'entries that round alike share a register');

	my $large = gradientImage(32, 32)->to_paletted(make_colors => 'mediancut', max_colors => 64);
	ok(keys(registers(encode($large, sixel_max_colors => 8))->%*) <= 8,
		'a palette larger than sixel_max_colors is reduced');
};

subtest 'transparency' => sub {
	my $img = Imager->new(xsize => 8, ysize => 8, channels => 4);
	$img->box(filled => 1, color => Imager::Color->new(255, 0, 0, 255), xmax => 3);
	$img->box(filled => 1, color => Imager::Color->new(0, 0, 255, 100), xmin => 4);

	my $data = encode($img);
	like($data, qr/\A\eP0;1;0q/, 'P2=1 for images with alpha');
	my $decoded = decode($data);
	is($decoded->getchannels, 4, 'decoded with alpha');
	is([$decoded->getpixel(x => 0, y => 0)->rgba], [255, 0, 0, 255], 'opaque pixel');
	is([$decoded->getpixel(x => 7, y => 7)->rgba], [0, 0, 0, 0], 'alpha below the threshold is transparent');

	my $atThreshold = decode(encode($img->copy, sixel_alpha_threshold => 100));
	is([$atThreshold->getpixel(x => 7, y => 7)->rgba], [0, 0, 255, 255], 'alpha at the threshold is painted');

	my $clear = Imager->new(xsize => 2, ysize => 2, channels => 4);
	my $all = decode(encode($clear, sixel_alpha_threshold => 0));
	is([$all->getpixel(x => 1, y => 1)->rgba], [0, 0, 0, 255], 'threshold 0 paints every pixel');

	my $empty = Imager->new(xsize => 3, ysize => 2, channels => 4);
	my $blank = decode(encode($empty));
	is([$blank->getwidth, $blank->getheight], [3, 2], 'fully transparent image keeps its size');
	like(encode(Imager->new(xsize => 3, ysize => 2, channels => 4)), qr/"1;1;3;2\$\e\\\z/,
		'a carriage return makes every decoder apply the raster attributes');
	is([$blank->getpixel(x => 2, y => 1)->rgba], [0, 0, 0, 0], 'and is transparent');

	my $paletted = Imager->new(xsize => 2, ysize => 1, channels => 4, type => 'paletted');
	$paletted->addcolors(colors => [Imager::Color->new(255, 0, 0, 255), Imager::Color->new(0, 255, 0, 50)]);
	$paletted->setpixel(x => 1, y => 0, color => Imager::Color->new(0, 255, 0, 50));
	my $palettedDecoded = decode(encode($paletted));
	is([map { [$palettedDecoded->getpixel(x => $_, y => 0)->rgba] } 0, 1], [[255, 0, 0, 255], [0, 0, 0, 0]],
		'the threshold applies to the palette of paletted images');

	my $top = Imager->new(xsize => 5, ysize => 14, channels => 4);
	$top->box(filled => 1, color => '#FF0000', ymax => 2);
	unlike(encode($top), qr/-\e\\\z/, 'no band separator before trailing empty bands');
};

subtest 'grey and high bit depth images' => sub {
	my $grey = Imager->new(xsize => 5, ysize => 3, channels => 1);
	$grey->box(filled => 1, color => Imager::Color->new(51, 51, 51));
	is(registers(encode($grey)), { 0 => [20, 20, 20] }, 'grey becomes an RGB register');

	# channel 0 is grey and channel 1 alpha
	my $greyAlpha = Imager->new(xsize => 5, ysize => 3, channels => 2);
	$greyAlpha->setsamples(y => $_, data => pack('C*', (102, 255) x 2, (0, 0) x 3)) for 0 .. 2;
	my $decoded = decode(encode($greyAlpha));
	is([$decoded->getpixel(x => 0, y => 0)->rgba], [102, 102, 102, 255], 'grey with alpha, painted');
	is([$decoded->getpixel(x => 4, y => 0)->rgba], [0, 0, 0, 0],         'grey with alpha, transparent');

	my $deep = Imager->new(xsize => 7, ysize => 7, bits => 16);
	$deep->box(filled => 1, color => '#336699');
	is(registers(encode($deep)), { 0 => [20, 40, 60] }, '16-bit samples');
};

subtest 'pixel aspect ratio' => sub {
	my $img = Imager->new(xsize => 2, ysize => 2);
	like(encode($img, sixel_pan => 2, sixel_pad => 1), qr/"2;1;2;2/, 'raster attributes from options');

	my $decoded = decode(encode(Imager->new(xsize => 2, ysize => 2), sixel_pan => 3, sixel_pad => 2));
	like(encode($decoded), qr/"3;2;2;2/, 'decoded tags are written back');
};

subtest 'options are stored as tags' => sub {
	my $img = gradientImage(16, 12);
	encode($img, sixel_dither => 'none', sixel_max_colors => 4);
	is($img->tags(name => 'sixel_dither'), 'none', 'sixel_dither tag');
	is(encode($img), encode(gradientImage(16, 12), sixel_dither => 'none', sixel_max_colors => 4),
		'a later write uses the stored options');
};

subtest 'ordered dithering with a fixed palette is stable' => sub {
	my $before = gradientImage(48, 24);
	my $after = gradientImage(48, 24);
	$after->box(filled => 1, color => '#FFFFFF', xmin => 40, ymin => 18);

	my %options = (sixel_palette => 'webmap', sixel_dither => 'ordered');
	my $first = decode(encode($before, %options));
	my $second = decode(encode($after, %options));
	my @changed = grep { join(',', rowSamples($first, $_)) ne join(',', rowSamples($second, $_)) } 0 .. 17;
	is(\@changed, [], 'rows above the change are identical');
};

subtest 'option validation' => sub {
	my @cases = (
		[[sixel_dither          => 'random'], qr/unknown sixel_dither value 'random'/],
		[[sixel_palette         => 'vga'],    qr/unknown sixel_palette value 'vga'/],
		[[sixel_palette         => "webmap\0x"], qr/unknown sixel_palette value/],
		[[sixel_dither          => {}],       qr/Unknown reference type HASH supplied for sixel_dither/],
		[[sixel_max_colors      => 0],        qr/sixel_max_colors must be an integer from 1 to 256/],
		[[sixel_max_colors      => 257],      qr/sixel_max_colors must be an integer from 1 to 256/],
		[[sixel_max_colors      => '12.7'],   qr/sixel_max_colors must be an integer from 1 to 256/],
		[[sixel_alpha_threshold => 256],      qr/sixel_alpha_threshold must be an integer from 0 to 255/],
		[[sixel_alpha_threshold => 'abc'],    qr/sixel_alpha_threshold must be an integer from 0 to 255/],
		[[sixel_pan             => 0],        qr/sixel_pan must be an integer from 1 to/],
		[[sixel_pan             => '2x'],     qr/sixel_pan must be an integer from 1 to/],
		[[sixel_pad             => -1],       qr/sixel_pad must be an integer from 1 to/],
	);
	foreach my $case (@cases) {
		my ($options, $message) = $case->@*;
		# options are stored as tags, so every check needs a fresh image
		my $img = Imager->new(xsize => 2, ysize => 2);
		like(encodeError($img, $options->@*), $message, "$options->@*");
	}
};

subtest 'multiple images' => sub {
	my @frames = map {
		my $frame = Imager->new(xsize => 4 + $_, ysize => 3);
		$frame->box(filled => 1, color => '#00FF00');
		$frame;
	} 0 .. 2;

	my $data = '';
	ok(Imager->write_multi({ data => \$data, type => 'sixel', sixel_dither => 'none' }, @frames), 'write_multi')
		or diag(Imager->errstr);
	is(scalar(() = $data =~ /\eP/g), 3, 'one control string per image');

	my @decoded = Imager->read_multi(data => $data, type => 'sixel');
	is([map { $_->getwidth } @decoded], [4, 5, 6], 'read back in order');

	my $invalid = Imager->new(xsize => 2, ysize => 2);
	$invalid->settag(name => 'sixel_dither', value => 'random');
	my $partial = '';
	ok(!Imager->write_multi({ data => \$partial, type => 'sixel' }, $frames[0], $invalid), 'invalid options fail');
	is($partial, '', 'nothing is written when any image has invalid options');

	ok(!Imager->write_multi({ data => \$partial, type => 'sixel' }), 'write_multi without images fails');
	like(Imager->errstr, qr/no images to write/, 'write_multi without images error message');
};

subtest 'files' => sub {
	make_path('testout');
	foreach my $extension (qw(six sixel)) {
		my $img = representableImage(9, 9, 5);
		ok($img->write(file => "testout/t20.$extension"), "type from the .$extension extension") or diag($img->errstr);
		my $read = Imager->new(file => "testout/t20.$extension");
		ok($read, 'read back with type detection') or next;
		ok(rgbSamples($read) eq rgbSamples($img), 'pixels round trip');
	}
};

done_testing;
