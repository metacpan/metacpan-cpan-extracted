#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;
   
use_ok( 'HTML::SocialMeta' );
use_ok( 'HTML::SocialMeta::Base' );

# Build Some Test Data With a Missing Field - No title !!
my $bad_meta_tags = HTML::SocialMeta->new(
    card => 'summary',
    site => '@example_twitter',
    site_name => 'Example Site, anything',
    description => 'Description goes here may have to do a little validation',
    image => 'www.urltoimage.com/blah.jpg',
    url	 => 'www.someurl.com',
);

# it will run schema first so it won't have a name!! which is equivelant to title
throws_ok{$bad_meta_tags->twitter->create_summary} qr/you have not set this field value title/;
throws_ok{$bad_meta_tags->opengraph->create_article} qr/you have not set this field value title/;

my $social = HTML::SocialMeta->new();
my @social_required_fields = $social->required_fields('summary');

my @expected_fields = ( qw{name description image card site title type site_name fb_app_id} );
my @expected_player_fields = ( qw{name description image card site title player player_width player_height type site_name fb_app_id} );

is(@social_required_fields, @expected_fields);

my @social_featured_fields  = $social->required_fields('featured_image');

is(@social_featured_fields, @expected_fields);

my @social_player_fields = $social->required_fields('player');

is(@social_player_fields, @expected_player_fields);

done_testing;

1;
