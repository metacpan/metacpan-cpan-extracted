use strict;
use warnings;
my $VERSION = 3;

# Rubbish tests

use lib qw( lib ../lib );

BEGIN {
	use Test::More;
	plan tests => 103;
}

BEGIN {
	use_ok('HTML::TagCloud::Centred');
}

my $cloud = HTML::TagCloud::Centred->new(
	# size_min_pc => 50,
	# size_max_pc => 200,
	# scale_code => sub { ... },
	clr_max => '#FF0000',
	clr_min => '#000000',
);

isa_ok( $cloud, 'HTML::TagCloud::Centred');
is( $HTML::TagCloud::Centred::VERSION, 5, 'Version');

isa_ok( 
	$cloud->add( 'FirstWord', 'http://www.google.co.uk' ),
	'HTML::TagCloud::Centred'
);
		
foreach my $w (
	('Biggest')x7, ('Medium')x5, ('Small')x6, ('Smallest')x10 
){
	isa_ok(
		$cloud->add( $w ),
		'HTML::TagCloud::Centred'
	);
}

$cloud->add( 'LastWord', 'http://www.google.co.uk' ),

like( $cloud->css, qr/<style/, 'some kinda output from css' );
like( $cloud->html, qr/<a /, 'some links in html' );
like( $cloud->html_and_css, qr/<style/, 'some kinda output from html_and_css' );
like( $cloud->html_and_css, qr/<a /, 'some links in html_and_css' );

my @tags = $cloud->tags;
is( scalar @tags, 30, 'number of tags');
foreach my $i (@tags){
	isa_ok( $i, 'HASH', 'tag');
	ok( exists($i->{name}), 'has a name');
}
ok( defined( $tags[14]->{url} ), 'has a url');
is( $tags[14]->{url}, 'http://www.google.co.uk', 'centre tag is biggest');
is( $tags[14]->{level}, 14, 'centre tag is in place');
is( $tags[14]->{size}, $cloud->{size_max_pc}, 'centre tag has max size');

SKIP: {
	skip 'No Color::Spectrum', 1 unless $Color::Spectrum::VERSION;
	is( $tags[14]->{clr}, '#FF0000', 'centre tag has max color');
}

TODO : {
	local $TODO = 'wip';
	is( $tags[0]->{size}, $cloud->{size_min_pc}, 'outside tag has min size');
}

# open my $OUT, '>temp.html'; print $OUT $cloud->html_and_css;

