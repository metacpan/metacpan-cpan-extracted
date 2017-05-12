# Tests for basic functionality of the class

use Test::More tests => 24;

BEGIN { use_ok('Image::Compare'); }

# Test adding an image as an Imager object using set_image1
my $cmp = Image::Compare->new();
$cmp->set_image1(img => Imager->new(xsize => 50, ysize => 50));
isa_ok($cmp->{_IMG1}, 'Imager', 'set_image with Imager');

# Test adding an image as a URL using set_image1
SKIP: {
	my $url = 'http://mirrors.cpan.org/img/cpanlog.jpg';
	# There's a number of reasons to skip this test.
	# A lot of reasons, actually.  It's hardly worth the trouble.
	# Really, this test is kind of stupid.  I'm stupid.
	eval {
		# Make sure that imager supports JPEG.
		die 'JPEG not supported' unless $Imager::formats{'jpeg'};
		# We only do this test if we have the right modules around.
		eval 'use LWP::Simple;';
		die 'Missing LWP' if $@;
		# We'll also make sure we have a reasonable network connection.
		my($content_type) = head($url);
		die 'No network' unless (
			$content_type && $content_type eq 'image/jpeg'
		);
	};
	skip($@, 2) if $@;

	$cmp = Image::Compare->new();
	$cmp->set_image1(img => $url);
	isa_ok($cmp->{_IMG1}, 'Imager',       'set_image1 with URL'      );
	ok(($cmp->{_IMG1}->getwidth() == 88), 'Image fetched as expected');
};

SKIP: {
	my $img;
	for my $ext (qw/gif jpeg png/) {
		if ($Imager::formats{$ext}) {
			$img = "t/sample.$ext";
			last;
		}
	}
	skip(
		"You don't support GIF, JPEG *or* PNG.  " +
		"I'm not sure how you're going to use this module.",
		6
	) unless defined $img;

	# Test adding an image as a file path using set_image1
	$cmp = Image::Compare->new();
	$cmp->set_image1(img => $img);
	isa_ok($cmp->{_IMG1}, 'Imager',       'set_image1 with path'      );
	ok(($cmp->{_IMG1}->getwidth() == 48), 'Image loaded as expected 1');

	# Now let's test set_image2.  This test need only verify the basic
	# functionality and not be as exhaustive as those before.
	$cmp->set_image2(img => $img);
	isa_ok($cmp->{_IMG2}, 'Imager',       'set_image2 with path'      );
	ok(($cmp->{_IMG2}->getwidth() == 48), 'Image loaded as expected 2');

	# Test out get_image[12].
	ok(($cmp->get_image1()->getwidth() == 48), 'get_image1');
	ok(($cmp->get_image2()->getwidth() == 48), 'get_image2');
}

# Test out set_method
$cmp->set_method(
	method => &Image::Compare::THRESHOLD,
	args => 4
);
isa_ok($cmp->{_CMP}, 'Image::Compare::THRESHOLD', 'Set comparator'        );
ok(($cmp->{_CMP}->{args} == 4),                   'Set comparator\'s args');

# Test get_method
my %method = $cmp->get_method();
is(
	$method{method},
	&Image::Compare::THRESHOLD,
	'get_method returns correct comparator'
);
ok(($method{args} == 4), 'get_method returns correct args');

# Finally, let's make sure that calling new() with a bunch of arguments
# works the way it ought.
$cmp = Image::Compare->new(
	image1 => Imager->new(
		xsize => 51,
		ysize => 51,
	),
	image2 => Imager->new(
		xsize => 52,
		ysize => 52,
	),
	method => &Image::Compare::AVG_THRESHOLD,
	args   => {
		type  => &Image::Compare::AVG_THRESHOLD::MEDIAN,
		value => 3.5,
	},
);

isa_ok($cmp->{_IMG1},      'Imager',                        'new set IMG1');
isa_ok($cmp->{_IMG2},      'Imager',                        'new set IMG2');
isa_ok($cmp->{_CMP},       'Image::Compare::AVG_THRESHOLD', 'new set comp');
isa_ok($cmp->{_CMP}{args}, 'HASH',                          'new set args');
ok(($cmp->{_IMG1}->getwidth()  == 51), 'IMG1 width' );
ok(($cmp->{_IMG1}->getheight() == 51), 'IMG1 height');
ok(($cmp->{_IMG2}->getwidth()  == 52), 'IMG2 width' );
ok(($cmp->{_IMG2}->getheight() == 52), 'IMG2 height');
ok(($cmp->{_CMP}{args}{value} == 3.5), 'args value' );
ok(
	($cmp->{_CMP}{args}{type}  == &Image::Compare::AVG_THRESHOLD::MEDIAN),
	'args type'
);
