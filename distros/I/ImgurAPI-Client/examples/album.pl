#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use ImgurAPI::Client;

my $client = ImgurAPI::Client->new({
    client_id => $ENV{'CLIENT_ID'},
    client_secret => $ENV{'CLIENT_SECRET'},
    access_token => $ENV{'ACCESS_TOKEN'},
});

my $images = ['uUK2UnD', 'NWzreUw'];

my $album_create = $client->album_create({
    title => 'Test Album',
    description => 'This is a test album',
    privacy => 'public',
    ids => [$images->[0]],
});
my $album_id = $album_create->{'data'}->{'id'};
print Dumper $album_create;
=album_create
{
    'success' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
    'data' => {
        'id' => '09OHF8s',
        'deletehash' => '77XpjvzI36sO7Mf'
    },
    'status' => 200
}
=cut

my $updated_title = 'Test Album Updated';
my $updated_description = 'This is a test album updated';
my $album_update = $client->album_update($album_id, {
    title => $updated_title,
    description => $updated_description,
    privacy => 'hidden',
});
print Dumper $album_update;
=album_update
{
    'success' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
    'status' => 200,
    'data' => {
        'id' => '0b5xSH4',
        'deletehash' => 'yvRS5U3hChR5jFA'
    }
}
=cut

my $updated_album_info = $client->album($album_id);
print Dumper $updated_album_info;
=album
{
    'status' => 200,
    'success' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
    'data' => {
        'images_count' => 1,
        'is_album' => $VAR1->{'success'},
        'layout' => 'blog',
        'title' => 'Test Album Updated',
        'deletehash' => 'EMwCtKJNM8uX5Vp',
        'id' => 'oNh3L0g',
        'link' => 'https://imgur.com/a/oNh3L0g',
        'datetime' => 1711348754,
        'ad_config' => {
            'highRiskFlags' => [],
            'nsfw_score' => 0,
            'unsafe_flags' => [],
            'wallUnsafeFlags' => [],
            'wall_unsafe_flags' => [],
            'showAdLevel' => 2,
            'high_risk_flags' => [],
            'show_ad_level' => 2,
            'show_ads' => $VAR1->{'success'},
            'showsAds' => $VAR1->{'success'},
            'safeFlags' => [
                'not_in_gallery',
                'share'
            ],
            'unsafeFlags' => [],
            'safe_flags' => [
                'not_in_gallery',
                'share'
            ]
        },
        'include_album_ads' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
        'cover_width' => 256,
        'in_gallery' => $VAR1->{'data'}{'include_album_ads'},
        'nsfw' => $VAR1->{'data'}{'include_album_ads'},
        'favorite' => $VAR1->{'data'}{'include_album_ads'},
        'account_id' => 179790421,
        'account_url' => 'SelfTaughtBot',
        'description' => 'This is a test album updated',
        'images' => [
            {
                'datetime' => 1710891746,
                'vote' => undef,
                'id' => 'uUK2UnD',
                'link' => 'https://i.imgur.com/uUK2UnD.jpg',
                'deletehash' => 'aOKzwGKI7Kncqt5',
                'size' => 9490,
                'type' => 'image/jpeg',
                'title' => undef,
                'has_sound' => $VAR1->{'data'}{'include_album_ads'},
                'bandwidth' => 47450,
                'animated' => $VAR1->{'data'}{'include_album_ads'},
                'width' => 256,
                'ad_url' => '',
                'height' => 256,
                'ad_type' => 0,
                'in_most_viral' => $VAR1->{'data'}{'include_album_ads'},
                'name' => 'Q4hMS.jpg',
                'in_gallery' => $VAR1->{'data'}{'include_album_ads'},
                'account_url' => undef,
                'description' => undef,
                'nsfw' => undef,
                'account_id' => undef,
                'favorite' => $VAR1->{'data'}{'include_album_ads'},
                'views' => 5,
                'section' => undef,
                'edited' => '0',
                'tags' => [],
                'is_ad' => $VAR1->{'data'}{'include_album_ads'}
            }
        ],
        'cover' => 'uUK2UnD',
        'views' => 0,
        'cover_height' => 256,
        'section' => undef,
        'privacy' => 'hidden',
        'cover_edited' => undef,
        'is_ad' => $VAR1->{'data'}{'include_album_ads'}
    }
}
=cut

my $album_favorite = $client->album_favorite($album_id);
print Dumper $album_favorite;
=album_favorite
{
    'data' => 'favorited',
    'status' => 200,
    'success' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' )
}
=cut

my $album_images_add = $client->album_images_add($album_id, [$images->[1]]);
print Dumper $album_images_add;
=album_images_add
{
    'success' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
    'status' => 200,
    'data' => $VAR1->{'success'}
}
=cut

my $album_images = $client->album_images($album_id);
print Dumper $album_images;
=album_images
{
    'success' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
    'data' => [
        {
        'in_gallery' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
        'is_ad' => $VAR1->{'data'}[0]{'in_gallery'},
        'type' => 'image/jpeg',
        'ad_url' => '',
        'description' => undef,
        'id' => 'uUK2UnD',
        'deletehash' => 'aOKzwGKI7Kncqt5',
        'height' => 256,
        'section' => undef,
        'edited' => '0',
        'link' => 'https://i.imgur.com/uUK2UnD.jpg',
        'tags' => [],
        'account_id' => undef,
        'views' => 5,
        'favorite' => $VAR1->{'data'}[0]{'in_gallery'},
        'vote' => undef,
        'name' => 'Q4hMS.jpg',
        'in_most_viral' => $VAR1->{'data'}[0]{'in_gallery'},
        'ad_type' => 0,
        'nsfw' => undef,
        'bandwidth' => 47450,
        'datetime' => 1710891746,
        'animated' => $VAR1->{'data'}[0]{'in_gallery'},
        'has_sound' => $VAR1->{'data'}[0]{'in_gallery'},
        'account_url' => undef,
        'width' => 256,
        'size' => 9490,
        'title' => undef
        }
    ],
    'status' => 200
}
=cut


my $album_image = $client->album_image($album_id, $images->[0]);
print Dumper $album_image;
=album_image
{
    'status' => 200,
    'data' => {
        'datetime' => 1710891746,
        'in_most_viral' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
        'nsfw' => $VAR1->{'data'}{'in_most_viral'},
        'ad_type' => 0,
        'description' => undef,
        'has_sound' => $VAR1->{'data'}{'in_most_viral'},
        'bandwidth' => 47450,
        'account_url' => undef,
        'section' => undef,
        'animated' => $VAR1->{'data'}{'in_most_viral'},
        'id' => 'uUK2UnD',
        'account_id' => 179790421,
        'height' => 256,
        'name' => 'Q4hMS.jpg',
        'views' => 5,
        'size' => 9490,
        'in_gallery' => $VAR1->{'data'}{'in_most_viral'},
        'edited' => '0',
        'link' => 'https://i.imgur.com/uUK2UnD.jpg',
        'vote' => undef,
        'deletehash' => 'aOKzwGKI7Kncqt5',
        'ad_url' => '',
        'favorite' => $VAR1->{'data'}{'in_most_viral'},
        'is_ad' => $VAR1->{'data'}{'in_most_viral'},
        'tags' => [],
        'title' => undef,
        'width' => 256,
        'type' => 'image/jpeg',
        'ad_config' => {
            'wall_unsafe_flags' => [],
            'safe_flags' => [
                'not_in_gallery',
                'share'
            ],
            'safeFlags' => [
                'not_in_gallery',
                'share'
            ],
            'unsafeFlags' => [],
            'highRiskFlags' => [],
            'show_ads' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
            'showAdLevel' => 2,
            'wallUnsafeFlags' => [],
            'high_risk_flags' => [],
            'showsAds' => $VAR1->{'data'}{'ad_config'}{'show_ads'},
            'unsafe_flags' => [],
            'nsfw_score' => 0,
            'show_ad_level' => 2
        }
    },
    'success' => $VAR1->{'data'}{'ad_config'}{'show_ads'}
}
=cut


my $album_delete = $client->album_delete($album_id);
print Dumper $album_delete;
=album_delete
{
    'success' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
    'data' => $VAR1->{'success'},
    'status' => 200
}
=cut

