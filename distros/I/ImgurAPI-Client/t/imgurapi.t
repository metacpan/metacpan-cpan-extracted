use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More;
use Test::Exception;


use_ok('ImgurAPI::Client');

my $client_id      = '123456789';
my $client_secret  = 'myClI3nT$3cr3t';
my $access_token   = 'myAcc3ssT0k3n';
my $oauth_cb_state = 'someState';
my $rapidapi_key   = 'myR4p1d4p1K3y';

subtest 'Constructor defaults' => sub {
    my $imgur = ImgurAPI::Client->new;

    isa_ok $imgur->_lwp, 'LWP::UserAgent', 'ImgurAPI->_lwp';

    is $imgur->access_token, undef, 'access_token default is undef';
    is $imgur->client_id, undef, 'client_id default is undef';
    is $imgur->client_secret, undef, 'client_secret default is undef';
    is $imgur->format_type, 'json', 'format_type default is json';
    is $imgur->rapidapi_key, undef, 'rapidapi_key default is undef';
    is $imgur->response, undef, 'response default is undef';
    is $imgur->oauth_cb_state, undef, 'oauth_cb_state default is undef';
};

subtest 'Constructor params' => sub {
    my $imgur = ImgurAPI::Client->new({
        client_id      => $client_id,
        client_secret  => $client_secret,
        access_token   => $access_token,
        oauth_cb_state => $oauth_cb_state,
        format_type    => 'xml',
        rapidapi_key   => $rapidapi_key,
    });

    is $imgur->access_token, $access_token, 'access_token is set';
    is $imgur->client_id, $client_id, 'client_id is set';
    is $imgur->client_secret, $client_secret, 'client_secret is set';
    is $imgur->format_type, 'xml', 'format_type is set';
    is $imgur->rapidapi_key, $rapidapi_key, 'rapidapi_key is set';
    is $imgur->oauth_cb_state, $oauth_cb_state, 'oauth_cb_state is set';

    ok grep /client_id=$client_id/, $imgur->oauth2_authorize_url, 'client_id is set in oauth2_url';
};

subtest 'ImgurAPI endpoint methods' => sub {
    can_ok(ImgurAPI::Client->new, qw(
        account
        account_album
        account_album_ids
        account_album_count
        account_album_delete
        account_albums
        account_block_status
        account_blocks
        account_block_create
        account_block_delete
        account_delete
        account_favorites
        account_gallery_favorites
        account_image
        account_image_delete
        account_image_ids
        account_images
        account_reply_notifications
        account_settings
        account_settings_update
        account_submissions
        account_tag_follow
        account_tag_unfollow
        account_verify_email_send
        account_verify_email_status

        album
        album_create
        album_delete
        album_image
        album_images_add
        album_images_delete
        album_images_set
        album_update

        comment
        comment_create
        comment_delete
        comment_replies
        comment_reply
        comment_report
        comment_vote

        gallery_album
        gallery_image
        gallery_item
        gallery_item_comment
        gallery_item_comment_info
        gallery_item_comments
        gallery_item_report
        gallery_item_tags
        gallery_item_tags_update
        gallery_item_vote
        gallery_item_votes
        gallery_image_remove
        gallery_search
        gallery_share_image
        gallery_share_album
        gallery_subreddit
        gallery_subreddit_image
        gallery_tag
        gallery_tag_info
        gallery_tags

        image_upload
        image_delete
        image_favorite
        image_update
    ));
};

subtest 'Setters' => sub {
    my $imgur = ImgurAPI::Client->new;

    $imgur->set_access_token($access_token);
    is $imgur->access_token, $access_token, 'set_access_token';

    $imgur->set_client_id($client_id);
    is $imgur->client_id, $client_id, 'set_client_id';

    $imgur->set_client_secret($client_secret);
    is $imgur->client_secret, $client_secret, 'set_client_secret';

    $imgur->set_format_type('xml');
    is $imgur->format_type, 'xml', 'set_format_type';

    $imgur->set_rapidapi_key($rapidapi_key);
    is $imgur->rapidapi_key, $rapidapi_key, 'set_rapidapi_key';

    $imgur->set_oauth_cb_state($oauth_cb_state);
    is $imgur->oauth_cb_state, $oauth_cb_state, 'set_oauth_cb_state';
};

subtest 'OAuth2 Authorization URL' => sub {
    my $imgur = ImgurAPI::Client->new;

    throws_ok { $imgur->oauth2_authorize_url } qr/missing required client_id/, 'oauth2_authorize_url throws with undef client_id';
    $imgur->set_client_id($client_id);
    lives_ok { $imgur->oauth2_authorize_url } 'oauth2_authorize_url lives when client_id is set';

    my $auth_url = $imgur->oauth2_authorize_url;

    ok grep /client_id=$client_id/, $auth_url, 'client_id is set in oauth2_authorize_url';
    ok grep /state=$/, $auth_url, 'state parameter value is empty in oauth2_authorize_url';

    $imgur->set_oauth_cb_state($oauth_cb_state);

    ok grep /state=$oauth_cb_state$/, $imgur->oauth2_authorize_url, 'oauth2_authorize_url state parameter value is set to expected value';
};

done_testing();