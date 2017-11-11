use 5.006;
use strict;
use warnings;
use Test::More;
  
use_ok( 'HTML::SocialMeta' );
# Build Some Test Data Which Is Valid
my $meta_tags = HTML::SocialMeta->new(
    card_type => 'summary',
    site => '@example_twitter',
    site_name => 'Example Site, anything',
    title => 'You can have any title you wish here',
    description => 'Description goes here may have to do a little "validation"',
    image => 'www.urltoimage.com/blah.jpg',
    image_alt => 'A picture of some stuff.',
    url	 => 'www.someurl.com',
    player => 'www.somevideourl.com/url/url',
    player_width => '500',
    player_height => '500',
    fb_app_id	=> '1232342342354',
);

# Create - Valid Meta_Tags
my $tags = $meta_tags->create;

my $test_create_all = '<meta name="twitter:card" content="summary"/>
<meta name="twitter:site" content="@example_twitter"/>
<meta name="twitter:title" content="You can have any title you wish here"/>
<meta name="twitter:description" content="Description goes here may have to do a little &quot;validation&quot;"/>
<meta name="twitter:image" content="www.urltoimage.com/blah.jpg"/>
<meta name="twitter:image:alt" content="A picture of some stuff."/>
<meta property="og:type" content="thumbnail"/>
<meta property="og:title" content="You can have any title you wish here"/>
<meta property="og:description" content="Description goes here may have to do a little &quot;validation&quot;"/>
<meta property="og:url" content="www.someurl.com"/>
<meta property="og:image" content="www.urltoimage.com/blah.jpg"/>
<meta property="og:image:alt" content="A picture of some stuff."/>
<meta property="og:site_name" content="Example Site, anything"/>
<meta property="fb:app_id" content="1232342342354"/>';

is($tags, $test_create_all);

my $twitter_tags = $meta_tags->twitter;
my $twitter_create = $twitter_tags->create('featured_image');

my $test_twitter_featured = '<meta name="twitter:card" content="summary_large_image"/>
<meta name="twitter:site" content="@example_twitter"/>
<meta name="twitter:title" content="You can have any title you wish here"/>
<meta name="twitter:description" content="Description goes here may have to do a little &quot;validation&quot;"/>
<meta name="twitter:image" content="www.urltoimage.com/blah.jpg"/>
<meta name="twitter:image:alt" content="A picture of some stuff."/>';

is($twitter_create, $test_twitter_featured);

# check we still have the original card_type passed in available
my $generic_twitter_create = $twitter_tags->create();

my $test_twitter = '<meta name="twitter:card" content="summary"/>
<meta name="twitter:site" content="@example_twitter"/>
<meta name="twitter:title" content="You can have any title you wish here"/>
<meta name="twitter:description" content="Description goes here may have to do a little &quot;validation&quot;"/>
<meta name="twitter:image" content="www.urltoimage.com/blah.jpg"/>
<meta name="twitter:image:alt" content="A picture of some stuff."/>';

is($generic_twitter_create, $test_twitter);

my $create_featured = $meta_tags->create('featured_image');

my $test_featured_all = '<meta name="twitter:card" content="summary_large_image"/>
<meta name="twitter:site" content="@example_twitter"/>
<meta name="twitter:title" content="You can have any title you wish here"/>
<meta name="twitter:description" content="Description goes here may have to do a little &quot;validation&quot;"/>
<meta name="twitter:image" content="www.urltoimage.com/blah.jpg"/>
<meta name="twitter:image:alt" content="A picture of some stuff."/>
<meta property="og:type" content="article"/>
<meta property="og:title" content="You can have any title you wish here"/>
<meta property="og:description" content="Description goes here may have to do a little &quot;validation&quot;"/>
<meta property="og:url" content="www.someurl.com"/>
<meta property="og:image" content="www.urltoimage.com/blah.jpg"/>
<meta property="og:image:alt" content="A picture of some stuff."/>
<meta property="og:site_name" content="Example Site, anything"/>
<meta property="fb:app_id" content="1232342342354"/>';

is($create_featured, $test_featured_all);
my $create_player = $meta_tags->create('player');

my $test_player_card = '<meta name="twitter:card" content="player"/>
<meta name="twitter:site" content="@example_twitter"/>
<meta name="twitter:title" content="You can have any title you wish here"/>
<meta name="twitter:description" content="Description goes here may have to do a little &quot;validation&quot;"/>
<meta name="twitter:image" content="www.urltoimage.com/blah.jpg"/>
<meta name="twitter:image:alt" content="A picture of some stuff."/>
<meta name="twitter:player" content="www.somevideourl.com/url/url"/>
<meta name="twitter:player:width" content="500"/>
<meta name="twitter:player:height" content="500"/>
<meta property="og:type" content="video"/>
<meta property="og:site_name" content="Example Site, anything"/>
<meta property="og:url" content="www.someurl.com"/>
<meta property="og:title" content="You can have any title you wish here"/>
<meta property="og:image" content="www.urltoimage.com/blah.jpg"/>
<meta property="og:image:alt" content="A picture of some stuff."/>
<meta property="og:description" content="Description goes here may have to do a little &quot;validation&quot;"/>
<meta property="og:video:url" content="www.somevideourl.com/url/url"/>
<meta property="og:video:secure_url" content="www.somevideourl.com/url/url"/>
<meta property="og:video:width" content="500"/>
<meta property="og:video:height" content="500"/>
<meta property="fb:app_id" content="1232342342354"/>';

is($create_player, $test_player_card);

# Build Some Test Data Which Is Valid
my $android_app_tags = HTML::SocialMeta->new(
    card_type => 'summary',
    site => '@example_twitter',
    site_name => 'Example Site, anything',
    title => 'You can have any title you wish here',
    description => 'Description goes here may have to do a little validation',
    image => 'www.urltoimage.com/blah.jpg',
    image_alt => 'A picture of some stuff.',
    url  => 'www.someurl.com',
    operatingSystem => 'ANDROID',
    app_country => 'US',
    app_name => 'tester twitter',
    app_id => '1232',
    app_url => 'app.app.com/app',
    fb_app_id	=> '1232342342354',
);

my $android_test_tags = q(<meta name="twitter:card" content="app"/>
<meta name="twitter:site" content="@example_twitter"/>
<meta name="twitter:description" content="Description goes here may have to do a little validation"/>
<meta name="twitter:app:country" content="US"/>
<meta name="twitter:app:name:googleplay" content="tester twitter"/>
<meta name="twitter:app:id:googleplay" content="1232"/>
<meta name="twitter:app:url:googleplay" content="app.app.com/app"/>
<meta property="og:type" content="product"/>
<meta property="og:title" content="You can have any title you wish here"/>
<meta property="og:image" content="www.urltoimage.com/blah.jpg"/>
<meta property="og:image:alt" content="A picture of some stuff."/>
<meta property="og:description" content="Description goes here may have to do a little validation"/>
<meta property="og:url" content="app.app.com/app"/>
<meta property="fb:app_id" content="1232342342354"/>);

is($android_app_tags->create('app'), $android_test_tags);

# Build Some Test Data Which Is Valid
my $ios_app_tags = HTML::SocialMeta->new(
    card_type => 'summary',
    site => '@example_twitter',
    site_name => 'Example Site, anything',
    title => 'You can have any title you wish here',
    description => 'Description goes here may have to do a little validation',
    image => 'www.urltoimage.com/blah.jpg',
    image_alt => 'A picture of some stuff.',
    url  => 'www.someurl.com',
    operatingSystem => 'IOS',
    app_country => 'US',
    app_name => 'tester twitter',
    app_id => '1232',
    app_url => 'app.app.com/app',
    fb_app_id	=> '1232342342354',
);

my $ios_test_tags = q(<meta name="twitter:card" content="app"/>
<meta name="twitter:site" content="@example_twitter"/>
<meta name="twitter:description" content="Description goes here may have to do a little validation"/>
<meta name="twitter:app:country" content="US"/>
<meta name="twitter:app:name:iphone" content="tester twitter"/>
<meta name="twitter:app:name:ipad" content="tester twitter"/>
<meta name="twitter:app:id:iphone" content="1232"/>
<meta name="twitter:app:id:ipad" content="1232"/>
<meta name="twitter:app:url:iphone" content="app.app.com/app"/>
<meta name="twitter:app:url:ipad" content="app.app.com/app"/>
<meta property="og:type" content="product"/>
<meta property="og:title" content="You can have any title you wish here"/>
<meta property="og:image" content="www.urltoimage.com/blah.jpg"/>
<meta property="og:image:alt" content="A picture of some stuff."/>
<meta property="og:description" content="Description goes here may have to do a little validation"/>
<meta property="og:url" content="app.app.com/app"/>
<meta property="fb:app_id" content="1232342342354"/>);

is($ios_app_tags->create('app'), $ios_test_tags);

my $create_twitter_featured = $meta_tags->create('featured_image', 'twitter');

my $test_featured_twitter = '<meta name="twitter:card" content="summary_large_image"/>
<meta name="twitter:site" content="@example_twitter"/>
<meta name="twitter:title" content="You can have any title you wish here"/>
<meta name="twitter:description" content="Description goes here may have to do a little &quot;validation&quot;"/>
<meta name="twitter:image" content="www.urltoimage.com/blah.jpg"/>
<meta name="twitter:image:alt" content="A picture of some stuff."/>';

is($create_twitter_featured, $test_featured_twitter);

# Make sure that we can make a tags object with no optional tags defined
my $only_required_meta_tags = HTML::SocialMeta->new(
    card_type => 'summary',
    site => '@example_twitter',
    site_name => 'Example Site, anything',
    title => 'You can have any title you wish here',
    description => 'Description goes here may have to do a little validation',
    image => 'www.urltoimage.com/blah.jpg',
    player => 'www.somevideourl.com/url/url',
    url	 => 'www.someurl.com',
    player_width => '500',
    player_height => '500',
    fb_app_id	=> '1232342342354',
);

my $only_required_tags = $only_required_meta_tags->create;
like ( $only_required_tags, qr{<meta name="twitter:image:alt" content=""/>});

done_testing();

1;
