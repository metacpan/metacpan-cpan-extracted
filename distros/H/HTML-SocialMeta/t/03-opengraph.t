use 5.006;
use strict;
use warnings;
use Test::More;
  
use_ok( 'HTML::SocialMeta' );
use_ok( 'HTML::SocialMeta::Base' );
use_ok( 'HTML::SocialMeta::OpenGraph' );

# Build Some Test Data Which Is Valid
my $meta_tags = HTML::SocialMeta->new(
    site => '@example_twitter',
    site_name => 'Example Site, anything',
    title => 'You can have any title you wish here',
    description => 'Description goes here may have to do a little validation',
    image => 'www.urltoimage.com/blah.jpg',
    url	 => 'www.someurl.com',
    player => 'www.somevideourl.com/url/url',
    player_width => '500',
    player_height => '500',
    fb_app_id	=> '1232342342354',
);

ok($meta_tags);

my $opengraph_tags = $meta_tags->opengraph;
my $opengraph_article_card = $meta_tags->opengraph->create_article;
my $opengraph_thumbnail_card = $meta_tags->opengraph->create_thumbnail;
my $opengraph_viedo_card = $meta_tags->opengraph->create_video;

# Meta tags we need for OPENGRAPH to work
my $test_opengraph = '<meta property="og:type" content="article"/>
<meta property="og:title" content="You can have any title you wish here"/>
<meta property="og:description" content="Description goes here may have to do a little validation"/>
<meta property="og:url" content="www.someurl.com"/>
<meta property="og:image" content="www.urltoimage.com/blah.jpg"/>
<meta property="og:site_name" content="Example Site, anything"/>
<meta property="fb:app_id" content="1232342342354"/>';

is($opengraph_tags->create('featured_image'), $test_opengraph);
is($opengraph_article_card, $test_opengraph);

my $test_opengraph_thumbnail = '<meta property="og:type" content="thumbnail"/>
<meta property="og:title" content="You can have any title you wish here"/>
<meta property="og:description" content="Description goes here may have to do a little validation"/>
<meta property="og:url" content="www.someurl.com"/>
<meta property="og:image" content="www.urltoimage.com/blah.jpg"/>
<meta property="og:site_name" content="Example Site, anything"/>
<meta property="fb:app_id" content="1232342342354"/>';

is($opengraph_tags->create('summary'), $test_opengraph_thumbnail);
is($opengraph_thumbnail_card, $test_opengraph_thumbnail);

my $test_video_card = '<meta property="og:type" content="video"/>
<meta property="og:site_name" content="Example Site, anything"/>
<meta property="og:url" content="www.someurl.com"/>
<meta property="og:title" content="You can have any title you wish here"/>
<meta property="og:image" content="www.urltoimage.com/blah.jpg"/>
<meta property="og:description" content="Description goes here may have to do a little validation"/>
<meta property="og:video:url" content="www.somevideourl.com/url/url"/>
<meta property="og:video:secure_url" content="www.somevideourl.com/url/url"/>
<meta property="og:video:width" content="500"/>
<meta property="og:video:height" content="500"/>
<meta property="fb:app_id" content="1232342342354"/>';

is($opengraph_tags->create('player'), $test_video_card);
is($opengraph_viedo_card, $test_video_card);

my $app_meta_tags = HTML::SocialMeta->new(
    site => '@example_twitter',
    site_name => 'Example Site, anything',
    title => 'You can have any title you wish here',
    description => 'Description goes here may have to do a little validation',
    image => 'www.urltoimage.com/blah.jpg',
    app_url	 => 'www.someurl.com',
    fb_app_id	=> '1232342342354',
);

my $test_app = '<meta property="og:type" content="product"/>
<meta property="og:title" content="You can have any title you wish here"/>
<meta property="og:image" content="www.urltoimage.com/blah.jpg"/>
<meta property="og:description" content="Description goes here may have to do a little validation"/>
<meta property="og:url" content="www.someurl.com"/>
<meta property="fb:app_id" content="1232342342354"/>';

is($app_meta_tags->opengraph->create('app'), $test_app);

done_testing();
