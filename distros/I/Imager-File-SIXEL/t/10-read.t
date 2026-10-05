use v5.24;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Test2::V0;

use Imager;
use Imager::File::SIXEL;

sub sixel($body, $params = '') {
	return "\eP${params}q$body\e\\";
}

sub decode($data, %opts) {
	my $img = Imager->new;
	return $img->read(data => $data, type => 'sixel', %opts) ? $img : undef;
}

sub decodeError($data, %opts) {
	my $img = Imager->new;
	return $img->read(data => $data, type => 'sixel', %opts) ? undef : $img->errstr;
}

# RGBA of a pixel; images without an alpha channel report 255
sub pixel($img, $x, $y) {
	my @rgba = $img->getpixel(x => $x, y => $y)->rgba;
	$rgba[3] = 255 if $img->getchannels == 3;
	return \@rgba;
}

subtest 'a single sixel column' => sub {
	my $img = decode(sixel('#1;2;100;0;0~'));
	ok($img, 'decoded') or return;
	is([$img->getwidth, $img->getheight], [1, 6], 'one column of six rows');
	is($img->getchannels, 3, 'opaque background gives an RGB image');
	is($img->type, 'paletted', 'few colours give a paletted image');
	is(pixel($img, 0, $_), [255, 0, 0, 255], "row $_ is red") for 0 .. 5;
	is($img->tags(name => 'i_format'), 'sixel', 'i_format tag');
};

subtest 'sixel bits map to rows from the top' => sub {
	# '@' sets bit 0, 'A' bit 1, 'G' bits 0..3
	my $img = decode(sixel('#1;2;0;0;100#2;2;0;100;0#1@#2A'));
	ok($img, 'decoded') or return;
	is([$img->getwidth, $img->getheight], [2, 2], 'size covers the painted pixels');
	is(pixel($img, 0, 0), [0, 0, 255, 255], 'bit 0 is the top row');
	is(pixel($img, 1, 1), [0, 255, 0, 255], 'bit 1 is the second row');
	is(pixel($img, 1, 0), [0, 0, 0, 255], 'unpainted pixel shows register 0');
};

subtest 'repeat introducer' => sub {
	my $img = decode(sixel('#1;2;100;100;100!5~!0~!1~'));
	ok($img, 'decoded') or return;
	is($img->getwidth, 7, 'repeat 5 plus repeat 0 and 1 each painting once');
	is(pixel($img, 6, 5), [255, 255, 255, 255], 'last column painted');
};

subtest 'a space ends a numeric parameter' => sub {
	my $img = decode(sixel('#1 2;2;100;0;0#12~'));
	ok($img, 'decoded') or return;
	isnt(pixel($img, 0, 0), [255, 0, 0, 255], '#1 2 does not define register 12');
};

subtest 'carriage return and next line' => sub {
	my $img = decode(sixel('#1;2;100;0;0~~$#2;2;0;0;100?~-#1~'));
	ok($img, 'decoded') or return;
	is([$img->getwidth, $img->getheight], [2, 12], 'two bands');
	is(pixel($img, 0, 0), [255, 0, 0, 255], 'first colour kept where the overlay skips');
	is(pixel($img, 1, 0), [0, 0, 255, 255], 'overlay after $ paints over');
	is(pixel($img, 0, 6), [255, 0, 0, 255], '- starts the next band at column 0');
};

subtest 'HLS colours use the DEC hue circle' => sub {
	my $img = decode(sixel('#1;1;0;50;100~#2;1;120;50;100~#3;1;240;50;100~#4;1;0;50;0~#5;1;300;75;100~'));
	ok($img, 'decoded') or return;
	is(pixel($img, 0, 0), [0,   0,   255, 255], 'hue 0 is blue');
	is(pixel($img, 1, 0), [255, 0,   0,   255], 'hue 120 is red');
	is(pixel($img, 2, 0), [0,   255, 0,   255], 'hue 240 is green');
	is(pixel($img, 3, 0), [128, 128, 128, 255], 'saturation 0 is grey');
	is(pixel($img, 4, 0), [128, 255, 255, 255], 'hue 300 at lightness 75 is light cyan');

	my $beyond = decode(sixel('#1;1;400;50;100~'));
	is(pixel($beyond, 0, 0), [0, 0, 255, 255], 'hues above 360 are treated as 360');
};

subtest 'other colour spaces' => sub {
	my $img = decode(sixel('#1;2;0;100;0#2;2;100;0;0#1#2;3;10;20;30~'));
	ok($img, 'decoded') or return;
	is(pixel($img, 0, 0), [255, 0, 0, 255], 'an unknown colour space selects the register unchanged');
};

subtest 'RGB percentages convert exactly' => sub {
	my $img = decode(sixel('#1;2;50;1;99~#2;2;200;0;0~'));
	ok($img, 'decoded') or return;
	is(pixel($img, 0, 0), [128, 3, 252, 255], '50%, 1% and 99%');
	is(pixel($img, 1, 0), [255, 0, 0, 255], 'values above 100% are clamped');
};

subtest 'default colour registers' => sub {
	my $img = decode(sixel('~#2~#8~#40~'));
	ok($img, 'decoded') or return;
	is(pixel($img, 0, 0), [204, 204, 204, 255], 'register 15 (grey 75%) is selected initially');
	is(pixel($img, 1, 0), [204, 33, 33, 255], 'register 2 is the VT340 red');
	is(pixel($img, 2, 0), [66, 66, 66, 255], 'register 8 is the VT340 grey 25%');
	is(pixel($img, 3, 0), [0, 0, 0, 255], 'registers beyond 15 start black');
};

subtest 'colour register numbers wrap at 1024' => sub {
	my $img = decode(sixel('#1;2;0;100;0#1025~'));
	ok($img, 'decoded') or return;
	is(pixel($img, 0, 0), [0, 255, 0, 255], 'register 1025 is register 1');
};

subtest 'pixels keep the colour they were painted with' => sub {
	my $img = decode(sixel('#1;2;100;0;0~#1;2;0;0;100~'));
	ok($img, 'decoded') or return;
	is(pixel($img, 0, 0), [255, 0, 0, 255], 'pixel painted before the redefinition');
	is(pixel($img, 1, 0), [0, 0, 255, 255], 'pixel painted after it');

	my $body = join '', map { '#1;2;' . ($_ % 101) . ';' . int($_ / 101) . ';0~' } 0 .. 299;
	my $many = decode(sixel($body));
	ok($many, 'one register redefined 300 times') or return;
	is($many->type, 'direct', 'more than 256 colours give a direct colour image');
	is(pixel($many, 0, 0),   [0, 0, 0, 255],   'first colour');
	is(pixel($many, 299, 0), [247, 5, 0, 255], 'last colour (97%, 2%, 0%)');
};

subtest 'background selection' => sub {
	my $opaque = decode(sixel('#0;2;0;100;0#1;2;100;0;0@', '0;0'));
	ok($opaque, 'P2=0 decoded') or return;
	is([$opaque->getwidth, $opaque->getheight], [1, 1], 'bottom rows without bits are not part of the image');

	my $declared = decode(sixel('"1;1;3;2#0;2;0;100;0#1;2;100;0;0@', '0;2'));
	ok($declared, 'P2=2 decoded') or return;
	is($declared->getchannels, 3, 'P2=2 gives an RGB image');
	is(pixel($declared, 2, 1), [0, 255, 0, 255], 'unpainted pixels take register 0');

	my $final = decode(sixel('"1;1;2;1#0;2;0;100;0#1;2;100;0;0@#0;2;0;0;100'));
	is(pixel($final, 1, 0), [0, 0, 255, 255], 'the background is the final colour of register 0');

	my $transparent = decode(sixel('"1;1;3;2#1;2;100;0;0@', '0;1'));
	ok($transparent, 'P2=1 decoded') or return;
	is($transparent->getchannels, 4, 'P2=1 gives an image with alpha');
	is(pixel($transparent, 0, 0), [255, 0, 0, 255], 'painted pixel is opaque');
	is(pixel($transparent, 2, 1), [0, 0, 0, 0], 'unpainted pixel is transparent');
};

subtest 'raster attributes' => sub {
	my $img = decode(sixel('"1;1;10;8#1;2;100;0;0~'));
	ok($img, 'decoded') or return;
	is([$img->getwidth, $img->getheight], [10, 8], 'declared size is used');
	is($img->tags(name => 'sixel_pan'), 1, 'sixel_pan from raster attributes');
	is($img->tags(name => 'sixel_pad'), 1, 'sixel_pad from raster attributes');

	my $larger = decode(sixel('"1;1;2;2#1;2;100;0;0!4~'));
	ok($larger, 'decoded data beyond the declared size') or return;
	is([$larger->getwidth, $larger->getheight], [4, 6], 'painted pixels extend the image');

	my $late = decode(sixel('#1;2;100;0;0~"1;1;10;10'));
	ok($late, 'decoded late raster attributes') or return;
	is([$late->getwidth, $late->getheight], [1, 6], 'raster attributes after sixel data are ignored');
};

subtest 'pixel aspect ratio tags' => sub {
	my %expected = ('' => [2, 1], 0 => [2, 1], 2 => [5, 1], 3 => [3, 1], 5 => [2, 1], 7 => [1, 1], 9 => [1, 1]);
	foreach my $p1 (sort keys %expected) {
		my $img = decode(sixel('~', $p1));
		ok($img, "P1='$p1' decoded") or next;
		is([$img->tags(name => 'sixel_pan'), $img->tags(name => 'sixel_pad')], $expected{$p1}, "P1='$p1' aspect ratio");
	}
	my $raster = decode(sixel('"3;2~', '2'));
	is([$raster->tags(name => 'sixel_pan'), $raster->tags(name => 'sixel_pad')], [3, 2], 'raster attributes override P1');
};

subtest 'palette order of a paletted image' => sub {
	my $img = decode(sixel('"1;1;4;1#5;2;0;100;0#2;2;100;0;0#5@#2@#5;2;0;0;100@', '0;1'));
	ok($img, 'decoded') or return;
	is([map { [$_->rgba] } $img->getcolors],
		[[255, 0, 0, 255], [0, 255, 0, 255], [0, 0, 255, 255], [0, 0, 0, 0]],
		'registers in order, then redefinitions, then transparency');
};

subtest 'more than 256 colours give a direct colour image' => sub {
	my $body = join '', map { "#$_;2;" . ($_ % 101) . ';' . int($_ / 101) . ';0~' } 0 .. 299;
	my $img = decode(sixel($body));
	ok($img, 'decoded') or return;
	is($img->type, 'direct', 'direct colour image');
	is($img->getwidth, 300, 'one column per colour');
	is(pixel($img, 299, 0), [247, 5, 0, 255], 'last colour (97%, 2%, 0%)');
};

subtest 'control string framing' => sub {
	my $eightBit = decode("\x90q#1;2;100;0;0~\x9c");
	ok($eightBit, '8-bit DCS and ST') or return;
	is(pixel($eightBit, 0, 0), [255, 0, 0, 255], '8-bit image decoded');

	my $mixed = decode("text\e[2J\eP\$q\"p\e\\" . sixel('#1;2;0;100;0~'));
	ok($mixed, 'skips text and other control strings') or return;
	is(pixel($mixed, 0, 0), [0, 255, 0, 255], 'sixel after other content decoded');

	my $private = decode("\eP>q~\e\\" . sixel('#1;2;0;0;100~'));
	ok($private, 'skips a control string with a private marker') or return;
	is(pixel($private, 0, 0), [0, 0, 255, 255], 'the following sixel is decoded');

	my $lineBreaks = decode("\ePq#1;2;\r\n100;0;0\r\n~~\r\n-~\e\\");
	ok($lineBreaks, 'line breaks inside the data') or return;
	is([$lineBreaks->getwidth, $lineBreaks->getheight], [2, 12], 'line breaks are ignored');
	is(pixel($lineBreaks, 0, 0), [255, 0, 0, 255], 'line breaks inside parameters are ignored');

	my $cancelled = decode("\ePq#1;2;100;0;0~\x18~~~");
	ok($cancelled, 'CAN ends the image') or return;
	is($cancelled->getwidth, 1, 'data after CAN is not part of the image');

	my $substituted = decode("\ePq#1;2;100;0;0~~\x1A~~~");
	ok($substituted, 'SUB ends the image') or return;
	is($substituted->getwidth, 2, 'data after SUB is not part of the image');

	my $spaces = decode(sixel('#1; 2; 0; 100; 0! 3~'));
	ok($spaces, 'spaces inside parameters') or return;
	is([$spaces->getwidth, pixel($spaces, 2, 0)], [3, [0, 255, 0, 255]], 'spaces inside parameters are ignored');

	# U+0110 is encoded as C4 90 and must not start a control string
	my @utf8 = Imager->read_multi(data => "Tr\xC6\xB0\xE1\xBB\x9Dng \xC4\x90qu\n" . sixel('#1;2;100;0;0~~~~'), type => 'sixel');
	is(scalar @utf8, 1, '0x90 within UTF-8 text is not a control string introducer');
};

subtest 'multiple images' => sub {
	my $data = sixel('#1;2;100;0;0~') . "\r\n" . sixel('#1;2;0;100;0~~') . sixel('#1;2;0;0;100~~~');

	my @images = Imager->read_multi(data => $data, type => 'sixel');
	is(scalar @images, 3, 'read_multi returns every image');
	is([map { $_->getwidth } @images], [1, 2, 3], 'images in stream order');

	my $second = decode($data, page => 1);
	ok($second, 'page 1') or return;
	is(pixel($second, 0, 0), [0, 255, 0, 255], 'page 1 is the second image');

	like(decodeError($data, page => 3), qr/page 3 not found/, 'missing page');
	like(decodeError($data, page => '4294967297'), qr/page must be a non-negative integer/, 'page beyond the C int range');

	my $unterminated = "\ePq#1;2;100;0;0~" . sixel('#1;2;0;0;100~~');
	my @split = Imager->read_multi(data => $unterminated, type => 'sixel');
	is(scalar @split, 2, 'a new control string ends an unterminated image');
};

subtest 'truncated data' => sub {
	my $data = "\ePq#1;2;100;0;0~~";
	like(decodeError($data), qr/premature end of SIXEL data/, 'fails by default');

	my $img = decode($data, allow_incomplete => 1);
	ok($img, 'allow_incomplete returns the partial image') or return;
	is($img->getwidth, 2, 'partial image size');
	is($img->tags(name => 'i_incomplete'), 1, 'i_incomplete tag set');

	my @images = Imager->read_multi(data => sixel('~') . $data, type => 'sixel', allow_incomplete => 1);
	is(scalar @images, 2, 'read_multi includes the partial image');

	my @strict = Imager->read_multi(data => sixel('~') . $data, type => 'sixel');
	is(scalar @strict, 0, 'without allow_incomplete read_multi fails as a whole');
	like(Imager->errstr, qr/premature end of SIXEL data/, 'read_multi error message');
};

subtest 'errors' => sub {
	like(decodeError('no sixel here'),       qr/no SIXEL image found/,  'no image');
	like(decodeError("\r\n"),                qr/no SIXEL image found/,  'only line breaks');
	like(decodeError(sixel('#1;2;0;0;0')),   qr/contains no pixels/,    'image without pixels');
	like(decodeError(sixel('~'), page => -1),    qr/page must be a non-negative integer/, 'negative page');
	like(decodeError(sixel('~'), page => 'abc'), qr/page must be a non-negative integer/, 'non-numeric page');

	my @none = Imager->read_multi(data => 'nothing', type => 'sixel');
	is(scalar @none, 0, 'read_multi fails without images');
	like(Imager->errstr, qr/no SIXEL image found/, 'read_multi error message');
};

subtest 'image size limits' => sub {
	my @saved = Imager->get_file_limits;
	Imager->set_file_limits(width => 100, height => 100);

	like(decodeError(sixel('!101~')),         qr/image width/,  'painted width beyond the limit');
	like(decodeError(sixel('"1;1;50;101~')),  qr/image height/, 'declared height beyond the limit');
	ok(decode(sixel('!100~')), 'width at the limit');
	is(decode(sixel('!1000000000?~')), undef, 'cursor movement far beyond the limit fails when painting');

	Imager->set_file_limits(reset => 1, bytes => 24000);
	like(decodeError(sixel('!1000~-@$!1000F')), qr/storage size of 27000 exceeds limit of 24000/,
		'growing in steps does not exceed the memory limit');

	Imager->set_file_limits(reset => 1, width => $saved[0], height => $saved[1], bytes => $saved[2]);
};

subtest 'painting over the same pixels is limited' => sub {
	like(decodeError(sixel('!100000~$' x 1000)), qr/SIXEL data paints too many pixels/, 'endless repainting fails');
	ok(decode(sixel('!100000~$' x 4)), 'repainting a few times is fine');
};

subtest 'huge parameters saturate' => sub {
	like(decodeError(sixel('!99999999999999999999~')), qr/limit|too large/, 'huge repeat count is rejected');
	my $img = decode(sixel('#99999999999999999999;2;100;0;0~'));
	ok($img, 'huge register number wraps') or return;
	is(pixel($img, 0, 0), [255, 0, 0, 255], 'colour of the wrapped register');
};

subtest 'type detection' => sub {
	my $img = Imager->new;
	ok($img->read(data => sixel('#1;2;100;0;0~')), 'read without a type') or diag($img->errstr);
	is($img->tags(name => 'i_format'), 'sixel', 'detected as sixel');
};

done_testing;
