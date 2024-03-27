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

my $account_info = $client->account('me');
print Dumper $account_info;

=account_info
{
    'success' => 1,
    'status' => 200,
    'data' => {
        'avatar' => 'https://imgur.com/user/SelfTaughtBot/avatar?maxwidth=290',
        'url' => 'SelfTaughtBot',
        'reputation_name' => 'Neutral',
        'is_blocked' => 0,
        'created' => 1710891360,
        'cover' => 'https://imgur.com/user/SelfTaughtBot/cover?maxwidth=2560',
        'bio' => undef,
        'user_follow' => {
            'status' => $VAR1->{'is_blocked'}
        },
        'id' => 179790421,
        'cover_name' => 'default/1-space',
        'pro_expiration' => $VAR1->{'is_blocked'},
        'reputation' => 14,
        'avatar_name' => 'default/S'
    }
}
=cut

my $account_albums = $client->account_albums('me');
print Dumper $account_albums;
=account_albums
{
    'success' => 1,
    'status' => 200,
    'data' => [
        {
        'order' => 0,
        'is_ad' => 0,
        'cover_width' => 256,
        'cover' => 'uUK2UnD',
        'link' => 'https://imgur.com/a/4rXNqk8',
        'nsfw' => undef,
        'cover_edited' => 0,
        'include_album_ads' => $VAR1->[0]{'is_ad'},
        'in_gallery' => $VAR1->[0]{'is_ad'},
        'description' => 'Test album',
        'id' => '4rXNqk8',
        'datetime' => 1710902273,
        'deletehash' => 'r6u0RJx95LXeDFZ',
        'title' => 'Mini Badges',
        'section' => undef,
        'account_id' => 179790421,
        'cover_height' => 256,
        'layout' => 'blog',
        'images_count' => 2,
        'is_album' => 1,
        'privacy' => 'hidden',
        'views' => 0,
        'account_url' => 'SelfTaughtBot',
        'favorite' => $VAR1->[0]{'is_ad'}
        }
    ]
}

=cut

my $account_album_count = $client->account_album_count('me');
print Dumper $account_album_count;
=account_album_count
{
    'success' => 1,
    'status' => 200,
    'data' => 1
}
=cut


my $account_album_ids = $client->account_album_ids('me');
print Dumper $account_album_ids;
=account_album_ids
{
    'success' => 1,
    'status' => 200
    'data' => [
        '4rXNqk8',
        'eowuWjA',
        'HLTYcbT',
        'vnYKlFI',
        'CfI4ATz',
        '80JCvKl'
    ],
}
=cut


# TODO
#my $account_album_delete = $client->account_album_delete('4rXNqk8');


my $account_block_create = $client->account_block_create('SelfTaught');
print Dumper $account_block_create;
=account_block_create
{
    'status' => 201,
    'data' => {
        'blocked' => 1
    },
    'success' => 1
}
=cut


my $account_blocks = $client->account_blocks;
print Dumper $accounaccount_blockst_album_ids;
=account_blocks
{
    'status' => 200,
    'data' => {
        'items' => [
            {
                'url' => 'selftaught'
            }
        ],
        'next' => undef
    },
    'success' => 1
}
=cut

my $account_block_status = $client->account_block_status('SelfTaught');
print Dumper $account_block_status;
=account_block_status
{
    'data' => {
        'blocked' => 1
    }
}
=cut

my $account_block_delete = $client->account_block_delete('SelfTaught');
print Dumper $account_block_delete;
=account_block_delete
{
    'status' => 204,
    'data' => {
        'blocked' => 0
    },
    'success' => 1
}
=cut


my $account_comments = $client->account_comments('me');
print Dumper $account_comments;
=account_comments
{
    'data' => [
        {
            'image_id' => 'YEj8sxk',
            'children' => [],
            'id' => 2386713745,
            'comment' => 'A classic',
            'album_cover' => 'Uewx2t5',
            'deleted' => 0,
            'downs' => 0,
            'author' => 'SelfTaughtBot',
            'datetime' => 1711335655,
            'points' => 1,
            'author_id' => 179790421,
            'parent_id' => 0,
            'vote' => undef,
            'on_album' => 1,
            'has_admin_badge' => $VAR1->{'data'}[0]{'deleted'},
            'ups' => 1,
            'platform' => 'desktop'
        }
    ],
    'success' => 1,
    'status' => 200
}
=cut

my $account_comment_ids = $client->account_comment_ids('me');
print Dumper $account_comment_ids;
=account_comment_ids
{
    'status' => 200,
    'success' => 1,
    'data' => [
        2386713745
    ]
}
=cut

# TODO: create a comment to delete and remove logic
if (my $comment_id = shift @{$account_comment_ids->{data}}) {
    my $account_comment_delete = $client->account_comment_delete('me', $comment_id);
}
=account_comment_delete
{
    'status' => 200,
    'data' => 1,
    'success' => 1
}
=cut

my $account_favorites = $client->account_favorites('me');
print Dumper $account_favorites;
=account_favorites
{
    'data' => [
        {
        'comment_count' => 18,
        'favorite' => 1,
        'type' => 'image/jpeg',
        'cover_height' => 973,
        'description' => '',
        'link' => 'https://imgur.com/gallery/YEj8sxk',
        'height' => 973,
        'datetime' => 1711310992,
        'in_gallery' => $VAR1->{'data'}[0]{'favorite'},
        'cover_width' => 800,
        'size' => 0,
        'title' => 'A little late, but 25 years ago last week, this Gem was first released.',
        'downs' => 4,
        'cover' => 'Uewx2t5',
        'points' => 121,
        'ups' => 125,
        'width' => 800,
        'favorite_count' => 11,
        'views' => 4698,
        'has_sound' => 0,
        'id' => 'YEj8sxk',
        'score' => 0,
        'tags' => undef,
        'account_id' => 168298761,
        'images_count' => 1,
        'animated' => $VAR1->{'data'}[0]{'has_sound'},
        'account_url' => 'NotAUserName69',
        'topic' => '',
        'is_album' => $VAR1->{'data'}[0]{'favorite'},
        'section' => undef,
        'images' => undef,
        'privacy' => '0',
        'nsfw' => $VAR1->{'data'}[0]{'has_sound'},
        'vote' => '',
        'in_most_viral' => $VAR1->{'data'}[0]{'has_sound'},
        'topic_id' => ''
        }
    ],
    'success' => $VAR1->{'data'}[0]{'favorite'},
    'status' => 200
}
=cut

my $account_tag_follow = $client->account_tag_follow('me', 'programming');
print Dumper $account_tag_follow;
=account_tag_follow
{
    'status' => 200,
    'data' => {
        'status' => 1
    },
    'success' => 1
}
=cut

my $account_tag_unfollow = $client->account_tag_unfollow('me', 'programming');
print Dumper $account_tag_unfollow;
=account_tag_unfollow
{
    'status' => 200,
    'data' => {
        'status' => 1
    },
    'success' => 1
}
=cut

my $account_gallery_favorites = $client->account_gallery_favorites('me');
print Dumper $account_gallery_favorites;
=account_gallery_favorites
{
    'data' => [
        {
        'link' => 'https://imgur.com/a/YEj8sxk',
        'is_album' => 1,
        'views' => 5269,
        'ups' => 132,
        'favorite' => $VAR1->{'data'}[0]{'is_album'},
        'in_most_viral' => 1,
        'tags' => [],
        'in_gallery' => $VAR1->{'data'}[0]{'is_album'},
        'account_url' => 'NotAUserName69',
        'ad_url' => '',
        'cover' => 'Uewx2t5',
        'score' => undef,
        'include_album_ads' => 0,
        'images_count' => 1,
        'title' => 'A little late, but 25 years ago last week, this Gem was first released.',
        'favorite_count' => 13,
        'section' => undef,
        'comment_count' => 19,
        'account_id' => 168298761,
        'topic' => undef,
        'points' => 128,
        'cover_width' => 800,
        'downs' => 4,
        'id' => 'YEj8sxk',
        'images' => [
            {
            'link' => 'https://i.imgur.com/Uewx2t5.jpg',
            'views' => 2336,
            'tags' => [],
            'type' => 'image/jpeg',
            'in_most_viral' => $VAR1->{'data'}[0]{'include_album_ads'},
            'ups' => undef,
            'favorite' => $VAR1->{'data'}[0]{'include_album_ads'},
            'size' => 173121,
            'in_gallery' => $VAR1->{'data'}[0]{'include_album_ads'},
            'account_url' => undef,
            'ad_url' => '',
            'bandwidth' => 404410656,
            'score' => undef,
            'animated' => $VAR1->{'data'}[0]{'include_album_ads'},
            'title' => undef,
            'has_sound' => $VAR1->{'data'}[0]{'include_album_ads'},
            'favorite_count' => undef,
            'width' => 800,
            'comment_count' => undef,
            'account_id' => undef,
            'points' => undef,
            'edited' => '0',
            'section' => undef,
            'height' => 973,
            'downs' => undef,
            'id' => 'Uewx2t5',
            'vote' => undef,
            'description' => undef,
            'datetime' => 1711310969,
            'nsfw' => undef,
            'is_ad' => $VAR1->{'data'}[0]{'include_album_ads'},
            'ad_type' => 0
            }
        ],
        'description' => undef,
        'datetime' => 1711310992,
        'topic_id' => undef,
        'layout' => undef,
        'vote' => undef,
        'nsfw' => undef,
        'cover_height' => 973,
        'ad_type' => 0,
        'is_ad' => $VAR1->{'data'}[0]{'include_album_ads'},
        'privacy' => undef
        }
    ],
    'status' => 200,
    'success' => 1
}
=cut

my $account_image = $client->account_image('me', 'DcYwgVi');
print Dumper $account_image;
=account_image
{
    'data' => {
        'size' => 740611,
        'is_ad' => 0,
        'bandwidth' => 740611,
        'ad_url' => '',
        'account_id' => 179790421,
        'in_gallery' => 1,
        'width' => 2371,
        'views' => 1,
        'id' => 'DcYwgVi',
        'edited' => '0',
        'in_most_viral' => $VAR1->{'data'}{'is_ad'},
        'type' => 'image/jpeg',
        'ad_config' => {
            'safeFlags' => [
            'in_gallery'
            ],
            'wallUnsafeFlags' => [],
            'safe_flags' => [
                'in_gallery'
            ],
            'show_ads' => $VAR1->{'data'}{'in_gallery'},
            'wall_unsafe_flags' => [],
            'unsafeFlags' => [],
            'unsafe_flags' => [],
            'highRiskFlags' => [],
            'high_risk_flags' => [],
            'show_ad_level' => 2,
            'nsfw_score' => 0,
            'showsAds' => $VAR1->{'data'}{'in_gallery'},
            'showAdLevel' => 2
        },
        'account_url' => undef,
        'has_sound' => $VAR1->{'data'}{'is_ad'},
        'name' => '',
        'section' => undef,
        'ad_type' => 0,
        'deletehash' => 'krYDnuTFOHnTPWV',
        'nsfw' => $VAR1->{'data'}{'is_ad'},
        'vote' => undef,
        'tags' => [],
        'link' => 'https://i.imgur.com/DcYwgVi.jpg',
        'title' => 'CuriousCodes Obverse',
        'favorite' => $VAR1->{'data'}{'is_ad'},
        'datetime' => 1710902271,
        'description' => 'CuriousCodes Obverse',
        'animated' => $VAR1->{'data'}{'is_ad'},
        'height' => 2349
    },
    'status' => 200,
    'success' => $VAR1->{'data'}{'in_gallery'}
}
=cut

my $account_images = $client->account_images('me');
print Dumper $account_images;
=account_images
{
    'success' => 1,
    'data' => [
        {
        'ad_type' => 0,
        'bandwidth' => 740611,
        'account_url' => 'SelfTaughtBot',
        'name' => '',
        'is_ad' => 0,
        'account_id' => 179790421,
        'tags' => [],
        'type' => 'image/jpeg',
        'vote' => undef,
        'favorite' => $VAR1->{'data'}[0]{'is_ad'},
        'title' => 'CuriousCodes Obverse',
        'in_gallery' => $VAR1->{'data'}[0]{'is_ad'},
        'id' => 'DcYwgVi',
        'in_most_viral' => $VAR1->{'data'}[0]{'is_ad'},
        'animated' => $VAR1->{'data'}[0]{'is_ad'},
        'section' => undef,
        'ad_url' => '',
        'nsfw' => undef,
        'link' => 'https://i.imgur.com/DcYwgVi.jpg',
        'datetime' => 1710902271,
        'edited' => '0',
        'width' => 2371,
        'deletehash' => 'krYDnuTFOHnTPWV',
        'has_sound' => $VAR1->{'data'}[0]{'is_ad'},
        'description' => 'CuriousCodes Obverse',
        'size' => 740611,
        'height' => 2349,
        'views' => 1
        }
    ],
    'status' => 200
}
=cut


my $account_image_count = $client->account_image_count('me');
print Dumper $account_image_count;
=account_image_count
{
    'status' => 200,
    'data' => 1,
    'success' => 1
}
=cut

my $account_image_ids = $client->account_image_ids('me');
print Dumper $account_image_ids;
=account_image_ids
{
    'status' => 200,
    'data' => [
        'DcYwgVi',
        'uUK2UnD',
        'uJQXhz4',
        'UstNJZW',
        'NWzreUw',
        'ohm4DIb'
    ],
    'success' => 1
=cut

my $account_reply_notifications = $client->account_reply_notifications('me');
print Dumper $account_reply_notifications;
=account_reply_notifications
{
    'status' => 200,
    'data' => {
        'replies' => [
            {
                'id' => 2386713745,
                'content' => 'A classic',
                'author' => 'SelfTaughtBot',
                'author_id' => 179790421,
                'on_album' => 1,
                'image_id' => 'YEj8sxk',
                'comment_id' => 2386713745,
                'datetime' => 1711335655,
                'platform' => 'desktop',
                'vote' => undef,
                'deleted' => 0,
                'ups' => 1,
                'downs' => 0,
                'children' => []
            }
        ],
        'total' => 1
    },
    'success' => 1
}
=cut

my $account_settings = $client->account_settings('me');
print Dumper $account_settings;
=account_settings
{
    'success' => 1,
    'status' => 200,
    'data' => {
        'account_url' => 'SelfTaughtBot',
        'avatar' => undef,
        'pro_expiration' => 0,
        'blocked_users' => [],
        'newsletter_subscribed' => $VAR1->{'success'},
        'show_mature' => $VAR1->{'data'}{'pro_expiration'},
        'email' => 'email@example.com',
        'accepted_gallery_terms' => $VAR1->{'data'}{'pro_expiration'},
        'cover' => undef,
        'comment_replies' => $VAR1->{'success'},
        'active_emails' => [],
        'messaging_enabled' => $VAR1->{'success'},
        'album_privacy' => 'hidden',
        'first_party' => $VAR1->{'success'},
        'public_images' => $VAR1->{'data'}{'pro_expiration'}
    }
}
=cut

my $settings = {
    bio => 'SelfTaughtBot is a bot that posts programming memes',
    public_images => 1,
    album_privacy => 'hidden',
    messaging_enabled => 0,
    accepted_gallery_terms => 1,
    show_mature => 0,
    newsletter_subscribed => 0,
};

my $account_settings_update = $client->account_settings_update('me', $settings);
print Dumper $account_settings_update;
=account_settings_update
{
    'status' => 200,
    'success' => 1,
    'data' => 1
}
=cut

my $account_submissions = $client->account_submissions('me');
print Dumper $account_submissions;
=account_submissions
{
    'data' => [
        {
        'bandwidth' => 2221833,
        'comment_count' => 0,
        'favorite_count' => 0,
        'ad_type' => 0,
        'account_id' => 179790421,
        'downs' => 0,
        'vote' => undef,
        'in_most_viral' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
        'favorite' => $VAR1->{'data'}[0]{'in_most_viral'},
        'in_gallery' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
        'height' => 2349,
        'score' => 1,
        'ups' => 1,
        'section' => '',
        'title' => 'CuriousCodes Obverse',
        'is_album' => $VAR1->{'data'}[0]{'in_most_viral'},
        'nsfw' => $VAR1->{'data'}[0]{'in_most_viral'},
        'tags' => [],
        'views' => 3,
        'topic' => undef,
        'width' => 2371,
        'account_url' => 'SelfTaughtBot',
        'id' => 'DcYwgVi',
        'points' => 1,
        'ad_url' => '',
        'is_ad' => $VAR1->{'data'}[0]{'in_most_viral'},
        'animated' => $VAR1->{'data'}[0]{'in_most_viral'},
        'datetime' => 1710902324,
        'has_sound' => $VAR1->{'data'}[0]{'in_most_viral'},
        'link' => 'https://i.imgur.com/DcYwgVi.jpg',
        'topic_id' => 0,
        'type' => 'image/jpeg',
        'edited' => 0,
        'size' => 740611,
        'description' => 'CuriousCodes Obverse'
        }
    ],
    'status' => 200,
    'success' => $VAR1->{'data'}[0]{'in_gallery'}
}
=cut


my $account_verify_email_send = $client->account_verify_email_send('me');
print Dumper $account_verify_email_send;
=account_verify_email_send
{
    'data' => 1,
    'success' => 1,
    'status' => 200
}
=cut


my $account_verify_email_status = $client->account_verify_email_status('me');
print Dumper $account_verify_email_status;
=account_verify_email_status
{
    'success' => 1,
    'data' => 0,
    'status' => 200
}
=cut