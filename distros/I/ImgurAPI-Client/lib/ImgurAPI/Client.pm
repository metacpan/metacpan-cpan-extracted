
package ImgurAPI::Client;

use strict;
use warnings;

use Data::Dumper;
use HTTP::Request::Common;
use JSON qw(decode_json encode_json);
use List::Util qw(first);
use LWP::UserAgent;
use Mozilla::CA;
use Scalar::Util;
use XML::LibXML;

our $VERSION = '1.1.3';

use constant ENDPOINTS => {
    'IMGUR' => 'https://api.imgur.com/3',
    'RAPIDAPI' => 'https://imgur-apiv3.p.rapidapi.com',
    'OAUTH_AUTHORIZE' => 'https://api.imgur.com/oauth2/authorize',
    'OAUTH_TOKEN' => 'https://api.imgur.com/oauth2/token',
};

sub new {
    my $self = shift;
    my $args = shift // {};
    my $vars = {
        'auth' => 1,
        'access_token' => $args->{'access_token'},
        'oauth_cb_state' => $args->{'oauth_cb_state'},
        'client_id' => $args->{'client_id'},
        'client_secret' => $args->{'client_secret'},
        'format_type' => $args->{'format_type'} || 'json',
        'lwp' => LWP::UserAgent->new,
        'rapidapi_key' => $args->{'rapidapi_key'},
        'refresh_token' => $args->{'refresh_token'},
        'response' => undef,
        'ratelimit_hdrs' => {},
        'user_agent' => $args->{'user_agent'} || "ImgurAPI::Client/$VERSION",
    };

    return bless $vars, $self;
}

sub _lwp { shift->{'lwp'} }

sub request {
    my ($self, $uri, $http_method, $data, $hdr) = @_;

    $http_method = uc($http_method // 'GET');

    my $endpoint = $self->{'rapidapi_key'} ? ENDPOINTS->{'RAPIDAPI'} . $uri : ($uri =~ /^\// ? ENDPOINTS->{'IMGUR'} . $uri : $uri);

    $endpoint .= ($endpoint =~ /\?/ ? '&' : '?') . '_format=' . $self->{'format_type'} . "&_method=$http_method";

    $self->_lwp->default_header('User-Agent' => "ImgurAPI::Client/$VERSION");

    if ($self->{'auth'}) {
        my $access_token = $self->{'access_token'} // die "Missing required access_token";
        $self->_lwp->default_header('Authorization' => "Bearer $access_token");
    } elsif ($self->{'client_id'}) {
        $self->_lwp->default_header('Authorization' => "Client-ID " . $self->{'client_id'});
    }

    if ($http_method =~ /^GET|DELETE$/ && $data && ref($data) eq 'HASH') {
        $endpoint .= "&$_=$data->{$_}" foreach keys %$data;
    }

    my $request;
    if ($http_method eq 'POST') {
        $request = HTTP::Request::Common::POST($endpoint, %{$hdr//{}}, Content => $data);
    } elsif ($http_method eq 'PUT') {
        $request = HTTP::Request::Common::PUT($endpoint, %{$hdr//{}}, Content => $data);
    } else {
        $request = HTTP::Request->new($http_method, $endpoint);
    }

    print Dumper $request if $ENV{'DEBUG'};

    my $response = $self->_lwp->request($request);

    my @ratelimit_headers = qw(userlimit userremaining userreset clientlimit clientremaining);
    foreach my $header (@ratelimit_headers) {
        my $val = $response->header("x-ratelimit-$header");
        $self->{'ratelimit_headers'}->{$header} = $val && $val =~ /^\d+$/ ? int $val : $val;
    }

    $self->{'response'} = $response;
    $self->{'response_content'} = $response->decoded_content;

    print Dumper $response if $ENV{'DEBUG'};

    if ($self->format_type eq 'xml') {
        return XML::LibXML->new->load_xml(string => $response->decoded_content);
    } else {
        my $decoded = eval { decode_json $response->decoded_content };
        if (my $err = $@) {
            die "An error occurred while trying to json decode imgur response: $err\n" . $response->decoded_content;
        }
        return $decoded;
    }
}

sub refresh_access_token {
    my $self = shift;
    my $opts = shift // {};

    my $refresh_token = $opts->{'refresh_token'} || $self->{'refresh_token'} or die "missing required refresh_token";
    my $client_id = $opts->{'client_id'} || $self->{'client_id'} or die "missing required client_id";
    my $client_secret = $opts->{'client_secret'} || $self->{'client_secret'} or die "missing required client_secret";

    my $resp = $self->request(ENDPOINTS->{'OAUTH_TOKEN'}, 'POST', {
        'refresh_token' => $refresh_token,
        'client_id' => $client_id,
        'client_secret' => $client_secret,
        'grant_type' => 'refresh_token',
    });

    $self->{'access_token'} = $resp->{'access_token'};
    $self->{'refresh_token'} = $resp->{'refresh_token'};

    return {
        access_token => $resp->{'access_token'},
        refresh_token => $resp->{'refresh_token'}
    }
}

# Setters
sub set_access_token {
    my ($self, $access_token) = @_;
    $self->{'access_token'} = $access_token;
}

sub set_client_id {
    my ($self, $client_id) = @_;
    $self->{'client_id'} = $client_id;
}

sub set_client_secret {
    my ($self, $client_secret) = @_;
    $self->{'client_secret'} = $client_secret;
}

sub set_format_type {
    my ($self, $format_type) = @_;
    $self->{'format_type'} = $format_type;
}

sub set_oauth_cb_state {
    my ($self, $oauth_cb_state) = @_;
    $self->{'oauth_cb_state'} = $oauth_cb_state;
}

sub set_rapidapi_key {
    my ($self, $rapidapi_key) = @_;
    $self->{'rapidapi_key'} = $rapidapi_key;
}

sub set_refresh_token {
    my ($self, $refresh_token) = @_;
    $self->{'refresh_token'} = $refresh_token;
}

sub set_user_agent {
    my ($self, $user_agent) = @_;
    $self->{'user_agent'} = $user_agent;
}

# Getters
sub oauth2_authorize_url {
    my $self = shift;
    my $client_id = $self->{'client_id'} or die "missing required client_id";
    my $state = $self->{'oauth_cb_state'} // '';
    return (ENDPOINTS->{'OAUTH_AUTHORIZE'} . "?client_id=$client_id&response_type=token&state=$state");
}

sub access_token {
    return shift->{'access_token'}
}

sub client_id {
    return shift->{'client_id'};
}

sub client_secret {
    return shift->{'client_secret'}
}

sub format_type {
    return shift->{'format_type'}
}

sub oauth_cb_state {
    return shift->{'oauth_cb_state'}
}

sub rapidapi_key {
    return shift->{'rapidapi_key'}
}

sub response {
    return shift->{'response'}
}

sub response_content {
    return shift->{'response_content'}
}

sub ratelimit_headers {
    return shift->{'ratelimit_headers'}
}

sub user_agent {
    return shift->{'user_agent'}
}

# Account
sub account {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/$user");
}

sub account_album {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $id = shift or die "missing required album id";
    return $self->request("/account/$user/album/$id");
}

sub account_album_count {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/$user/albums/count");
}

sub account_album_delete {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $id = shift or die "missing required album id";
    return $self->request("/account/$user/album/$id", 'DELETE');
}

sub account_album_ids {
    my $self = shift;
    my $user = shift or die "missing requied username";
    my $opts = shift // {};
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/albums/ids/$page");
}

sub account_albums {
    my $self = shift;
    my $user = shift or die "missing requied username";
    my $opts = shift // {};
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/albums/$page");
}

sub account_block_status {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("https://api.imgur.com/account/v1/$user/block");
}

sub account_block_create {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $resp = eval { $self->request("https://api.imgur.com/account/v1/$user/block", 'POST') };

    if (my $err = $@) {
        # we have to check if the response was successful when it throws because the imgur api
        # states it will return the same object we return just below upon blocking a user.. but they dont.
        # so we end up trying to json decode an empty response which throws an error. if they just returned
        # the object they said they would in their api doc, we wouldnt get a json decode error.
        # 201 and 'Created' msg indicates success.
        if ($self->{'response'}->code != 201 ||
            $self->{'response'}->{'_msg'} ne 'Created') {
            die $err;
        }
        $resp = {
            'success' => 1,
            'status' => 201,
            'data' => {
                'blocked' => 1,
            }
        };
    }
    return $resp;
}

sub account_block_delete {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $resp = eval { $self->request("https://api.imgur.com/account/v1/$user/block", 'DELETE') };

    if (my $err = $@) {
        # we have to check if the response was successful when it throws because the imgur api
        # states it will return the same object we return just below upon unblocking a user.. but they dont.
        # so we end up trying to json decode an empty response which throws an error. if they just returned
        # the object they said they would in their api doc, we wouldnt get a json decode error.
        # 204 rc indicates success.
        if ($self->{'response'}->code == 204) {
            return {
                'success' => 1,
                'status' => 204,
                'data' => {
                    'blocked' => 0,
                }
            }
        }
        die $err;
    }

    return $resp;
}

sub account_blocks {
    my $self = shift;
    return $self->request("/account/me/block");
}

sub account_comment {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $id = shift or die "missing required comment id";
    return $self->request("/account/$user/comment/$id");
}

sub account_comment_count {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/$user/comments/count");
}

sub account_comment_delete {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $id = shift or die "missing required comment id";
    return $self->request("/account/$user/comment/$id", 'DELETE');
}

sub account_comment_ids {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $sort = $opts->{'sort'} // 'newest';
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/comments/ids/$sort/$page");
}

sub account_comments {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $sort = $opts->{'sort'} // 'newest';
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/comments/$sort/$page");
}

sub account_delete {
    my $self = shift;
    my $client_id = shift or die "missing required client id";
    my $body = shift or die "missing required post body";
    return $self->request("/account/me/delete?client_id=$client_id", 'POST', $body);
}

sub account_favorites {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $sort = $opts->{'sort'} // 'newest';
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/favorites/$page/$sort");
}

sub account_gallery_favorites {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $sort = $opts->{'sort'} // 'newest';
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/gallery_favorites/$page/$sort");
}

sub account_image {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $id = shift or die "missing required image id";
    return $self->request("/account/$user/image/$id");
}

sub account_image_count {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/$user/images/count");
}

sub account_image_delete {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $id = shift or die "missing required image id";
    return $self->request("/account/$user/image/$id", 'DELETE');
}

sub account_image_ids {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/images/ids/$page");
}

sub account_images {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/images/$page");
}

sub account_reply_notifications {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $new = $opts->{'new'} // 1;
    return $self->request("/account/$user/notifications/replies?new=$new");
}

sub account_settings {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/$user/settings");
}

sub account_settings_update {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $settings = shift // {};
    my @valid_settings = (qw(bio public_images messaging_enabled accepted_gallery_terms username show_mature newsletter_subscribed));
    my %valid_settings_map = map { $_ => 1 } @valid_settings;
    my $data = {};

    foreach my $key (keys %{$settings}) {
        $data->{$key} = $settings->{$key} if exists $valid_settings_map{$key};
    }

    return $self->request("/account/$user/settings", 'PUT', $data);
}

sub account_submissions {
    my $self = shift;
    my $user = shift or die "missing required username";
    my $opts = shift // {};
    my $page = $opts->{'page'} // 0;
    return $self->request("/account/$user/submissions/$page");
}

sub account_tag_follow {
    my $self = shift;
    my $tag = shift or die "missing required tag";
    return $self->request("/account/me/follow/tag/$tag", 'POST');
}

sub account_tag_unfollow {
    my $self = shift;
    my $tag = shift or die "missing required tag";
    return $self->request("/account/me/follow/tag/$tag", 'DELETE');
}

sub account_verify_email_send {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/$user/verifyemail", 'POST');
}

sub account_verify_email_status {
    my $self = shift;
    my $user = shift or die "missing required username";
    return $self->request("/account/$user/verifyemail");
}

# Album
sub album {
    my $self = shift;
    my $id = shift or die "missing required album id";
    return $self->request("/album/$id");
}

sub album_create {
    my $self = shift;
    my $opts = shift // {};
    my @opt_keys = (qw(ids deletehashes title description cover));
    my %valid_opts = map { $_ => 1 } @opt_keys;
    my $data = {};

    foreach my $opt (keys %{$opts}) {
        if (exists $valid_opts{$opt}) {
            my $key = $opt eq 'ids' || $opt eq 'deletehashes' ? $opt.'[]' : $opt;
            $data->{$key} = $opts->{$opt};
        }
    }

    return $self->request("/album", 'POST', $data);
}

sub album_delete {
    my $self = shift;
    my $id = shift or die "missing required album id";
    return $self->request("/album/$id", 'DELETE');
}

sub album_favorite {
    my $self = shift;
    my $id = shift or die "missing required album id";
    return $self->request("/album/$id/favorite", 'POST');
}

sub album_image {
    my $self = shift;
    my $album_id = shift or die "missing required album id";
    my $image_id = shift or die "missing required image id";
    return $self->request("/album/$album_id/image/$image_id");
}

sub album_images {
    my $self = shift;
    my $album_id = shift or die "missing required album id";
    return $self->request("/album/$album_id/images");
}

sub album_images_add {
    my $self = shift;
    my $album_id = shift or die "missing required album_id";
    my $image_ids = shift or die "missing required image_ids";
    return $self->request("/album/$album_id/add", 'POST', {'ids[]' => $image_ids});
}

sub album_images_delete {
    my $self = shift;
    my $album_id = shift or die "missing required album_id";
    my $image_ids = shift or die "missing required image_ids";
    return $self->request("/album/$album_id/remove_images", 'DELETE', {'ids' => join(',', @$image_ids)});
}

sub album_images_set {
    my $self = shift;
    my $album_id = shift or die "missing required album_id";
    my $image_ids = shift or die "missing required image_ids";
    return $self->request("/album/$album_id", 'POST', {'ids[]' => $image_ids});
}

sub album_update {
    my $self = shift;
    my $album_id = shift or die "missing required album_id";
    my $opts = shift // {};
    my %valid_opts = map { $_ => 1 } (qw(ids deletehashes title description cover));
    my $data = {};

    foreach my $opt (keys %{$opts}) {
        if (exists $valid_opts{$opt}) {
            my $key = $opt eq 'ids' || $opt eq 'deletehashes' ? $opt.'[]' : $opt;
            $data->{$key} = $opts->{$opt};
        }
    }

    return $self->request("/album/$album_id", 'PUT', $data);
}

# Comment
sub comment {
    my ($self, $id) = @_;
    return $self->request("/comment/$id");
}

sub comment_create {
    my $self = shift;
    my $image_id = shift or die "missing required image id";
    my $comment = shift or die "missing required comment";
    my $parent_id = shift;

    return $self->request("/comment", 'POST', {
        'image_id' => $image_id,
        'comment'  => $comment,
        ($parent_id ? ('parent_id'  => $parent_id) : ()),
    });
}

sub comment_delete {
    my $self = shift;
    my $comment_id = shift or die "missing required comment id";
    return $self->request("/comment/$comment_id", 'DELETE');
}

sub comment_replies {
    my $self = shift;
    my $comment_id = shift or die "missing required comment_id";
    return $self->request("/comment/$comment_id/replies");
}

sub comment_reply {
    my $self = shift;
    my $image_id = shift or die "missing required image_id";
    my $comment_id = shift or die "missing required comment_id";
    my $comment = shift or die "missing required comment";

    return $self->comment_create($image_id, $comment, $comment_id);
}

sub comment_report {
    my $self = shift;
    my $comment_id = shift or die "missing required comment_id";
    my $reason = shift;
    my $data = {};

    $data->{'reason'} = $reason if $reason;

    return $self->request("/comment/$comment_id/report", 'POST', $data);
}

sub comment_vote {
    my $self = shift;
    my $comment_id = shift or die "missing required comment_id";
    my $vote = shift or die "missing required vote";

    return $self->request("/comment/$comment_id/vote/$vote", 'POST');
}

# Credits
sub credits {
    my $self = shift;
    return $self->request("/credits");
}

# Gallery
sub gallery {
    my $self = shift;
    my $opts = shift // {};

    die "optional data must be a hashref" if ref $opts ne 'HASH';

    my $section = $opts->{'section'} // 'hot';
    my $sort = $opts->{'sort'} // 'viral';
    my $page = $opts->{'page'} // 0;
    my $window = $opts->{'window'} // 'day';
    my $show_viral = $opts->{'show_viral'} // 1;
    my $album_prev = $opts->{'album_previews'} // 1;

    return $self->request(("/gallery/$section/$sort/$window/$page?showViral=$show_viral&album_previews=" . ($album_prev ? 'true' : 'false')));
}

sub gallery_album {
    my $self = shift;
    my $album_id = shift or die "missing required album id";
    return $self->request("/gallery/album/$album_id");
}

sub gallery_image {
    my $self = shift;
    my $image_id = shift or die "missing required image id";
    return $self->request("/gallery/image/$image_id");
}

sub gallery_item {
    my ($self, $id) = @_;
    return $self->request("/gallery/$id");
}

sub gallery_item_comment {
    my $self = shift;
    my $id = shift or die "missing required album/image id";
    my $comment = shift or die "missing required comment";
    return $self->request("/gallery/$id/comment", 'POST', {comment => $comment});
}

sub gallery_item_comment_info {
    my $self = shift;
    my $id = shift or die "missing required album/image id";
    my $comment_id = shift or die "missing required comment id";
    return $self->request("/gallery/$id/comment/$comment_id");
}

sub gallery_item_comments {
    my $self = shift;
    my $id = shift or die "missing required image/album id";
    my $opts = shift // {};
    my $sort = $opts->{'sort'} // 'best';
    return $self->request("/gallery/$id/comments/$sort");
}

sub gallery_item_report {
    my $self = shift;
    my $id = shift or die "missing required image/album id";
    my $opts = shift // {};
    my $reason = $opts->{'reason'};
    my %data = ($reason ? (reason => $reason) : ());

    $data{'reason'} = $reason if $reason;

    return $self->request("/gallery/image/$id/report", 'POST', \%data);
}

sub gallery_item_tags {
    my $self = shift;
    my $id = shift or die "missing required image/album id";
    return $self->request("/gallery/$id/tags");
}

sub gallery_item_tags_update {
    my $self = shift;
    my $id = shift or die "missing required image/album id";
    my $tags = shift or die "missing required tags";
    return $self->request("/gallery/$id/tags", 'POST', {'tags' => $tags});
}

sub gallery_item_vote {
    my $self = shift;
    my $id = shift or die "missing required image/album id";
    my $vote = shift or die "missing required vote";
    return $self->request("/gallery/$id/vote/$vote", 'POST');
}

sub gallery_item_votes {
    my $self = shift;
    my $id = shift or die "missing required image/album id";
    return $self->request("/gallery/$id/votes");
}

sub gallery_image_remove {
    my $self = shift;
    my $id = shift or die "missing required image id";
    return $self->request("/gallery/$id", 'DELETE');
}

sub gallery_search {
    my $self = shift;
    my $query = shift;
    my $opts = shift // {};
    my $advanced = shift // {};
    my $sort = $opts->{'sort'} // 'time';
    my $window = $opts->{'window'} // 'all';
    my $page = $opts->{'page'} // 0;
    my $data = {};

    if ($advanced) {
        my %adv_keys = map { $_ => 1 } ('q_all', 'q_any', 'q_exactly', 'q_not', 'q_type', 'q_size_px');
        foreach my $key (keys %{$advanced}) {
            $data->{$key} = $advanced->{$key} unless ! exists($adv_keys{$key});
        }
    } elsif (!$query) {
        die "must provide a query or advanced search parameters";
    }

    return $self->request("/gallery/search/$sort/$window/$page" . ($advanced ? '' : "?q=$query"), 'GET', $data);
}

sub gallery_share_image {
    my $self = shift;
    my $image_id = shift or die "missing required image id";
    my $title = shift or die "missing required title";
    my $opts = shift // {};
    my $data = {'title' => $title};

    if ($opts) {
        my @optional_keys = ('topic', 'terms', 'mature', 'tags');
        foreach my $key (keys %{$opts}) {
            if (first { $_ eq $key } @optional_keys) {
                if ($key eq 'tags') {
                    if (ref $opts->{'tags'} eq 'ARRAY') {
                        $opts->{'tags'} = join(',', @{$opts->{'tags'}});
                    }
                }
                $data->{$key} = $opts->{$key};
            }
        }
    }

    return $self->request("/gallery/image/$image_id", "POST", $data);
}

sub gallery_share_album {
    my $self = shift;
    my $album_id = shift or die "missing required album id";
    my $title = shift or die "missing required title";
    my $opts = shift // {};
    my $data = {'title' => $title};

    if ($opts) {
        my @optional_keys = ('topic', 'terms', 'mature', 'tags');
        foreach my $key (keys %{$opts}) {
            if (first { $_ eq $key } @optional_keys) {
                if ($key eq 'tags') {
                    if (ref $opts->{'tags'} eq 'ARRAY') {
                        $opts->{'tags'} = join(',', @{$opts->{'tags'}});
                    }
                }
                $data->{$key} = $opts->{$key};
            }
        }
    }

    return $self->request("/gallery/album/$album_id", "POST", $data);
}

sub gallery_subreddit {
    my $self = shift;
    my $subreddit = shift or die "missing required subreddit";
    my $opts = shift // {};

    die "optional data must be a hashref" if ref $opts ne 'HASH';

    my $sort = $opts->{'sort'} // 'time';
    my $window = $opts->{'window'} // 'week';
    my $page = $opts->{'page'} // 0;

    return $self->request(("/gallery/r/$subreddit/$sort" . ($sort eq 'top' ? "/$window" : "") . "/$page"));
}

sub gallery_subreddit_image {
    my $self = shift;
    my $subreddit = shift or die "missing required subreddit";
    my $image_id = shift or die "missing required image id";

    return $self->request("/gallery/r/$subreddit/$image_id");
}

sub gallery_tag {
    my $self = shift;
    my $tag = shift or die "missing required tag";
    my $opts = shift // {};
    my $sort = $opts->{'sort'} // 'viral';
    my $page = $opts->{'page'} // 0;
    my $window = $opts->{'window'} // 'week';

    return $self->request(("/gallery/t/$tag/$sort" . ($sort eq 'top' ? "/$window" : "") . "/$page"));
}

sub gallery_tag_info {
    my $self = shift;
    my $tag  = shift or die "missing required tag";
    return $self->request("/gallery/tag_info/$tag");
}

sub gallery_tags {
    my $self = shift;
    return $self->request("/tags");
}

# Image
sub image {
    my $self = shift;
    my $id = shift or die "missing required image id";
    return $self->request("/image/$id");
}

sub image_upload {
    my $self = shift;
    my $src  = shift or die "missing required image/video src";
    my $type = shift or die "missing required image/video type";
    my $opts = shift // {};
    my $data = {'image' => $src, 'type' => $type};
    my %hdr = ();

    $data->{'title'} = $opts->{'title'} if $opts->{'title'};
    $data->{'description'} = $opts->{'description'} if $opts->{'description'};

    if ($type eq 'file') {
        die "file doesnt exist at path: $src" unless -e $src;
        die "provided src file path is not a file" unless -f $src;
        $data->{'image'} = [$src];
        %hdr = (Content_Type => 'form-data');
    }

    return $self->request("/image", 'POST', $data, \%hdr);
}

sub image_delete {
    my $self = shift;
    my $id = shift or die "missing required image id";
    return $self->request("/image/$id", 'DELETE');
}

sub image_favorite {
    my $self = shift;
    my $id = shift or die "missing required image id";
    return $self->request("/image/$id/favorite", 'POST');
}

sub image_update {
    my $self = shift;
    my $id = shift or die "missing required image id";
    my $opts = shift // {};
    return $self->request("/image/$id", 'POST', $opts);
}

# Feed
sub feed {
    my $self = shift;
    return $self->request("/feed");
}

=head1 NAME

ImgurAPI::Client - Imgur API client

=head1 DESCRIPTION

This is a client module for interfacing with the Imgur API.

=head1 SYNOPSIS

=head2 Instantiation

    use ImgurAPI::Client;

    my $client = ImgurAPI::Client->new({
        'client_id' => 'your_client_id',
        'access_token' => 'your_access_token'
    });

    my $upload = $client->image_upload("helloimgur.png", 'file', {title => 'title', description => 'desc'});
    my $image_info = $client->image($upload->{'data'}->{'id'};

=head2 Authorization

Imgur uses OAuth 2.0 for authentication. OAuth 2.0 has four steps: registration, authorization, making authenticated requests and getting new access tokens after the initial one expires using a refresh token and client secret.

After registering a client application with Imgur L<here|https://api.imgur.com/oauth2/addclient>, the user will need to manually authorize it. Generate a authorization url using the C<oauth2_authorize_url> method and redirect the user to the generated url. The user will be prompted to authorize the application and upon authorization, the user will be redirected to the callback endpoint URL that was specified during application registration. The callback endpoint should collect the access token and refresh token and store them somewhere your code on the backend can pull the access token from and then pass it to the client. You can also visit the authorization url in the browser and manually pull the access token, refresh token and other parameters out of the redirect url and store them somewhere your code can pull them without having a collector endpoint setup. View the official imgur documentation for authorization L<here|https://apidocs.imgur.com/#authorization-and-oauth>.

=head2 Authentication

The client can be authenticated by setting the access token and client id. Those can be set a couple of ways. The first way is to do it is by passing them to the constructor:

    my $client = ImgurAPI::Client->new({
        'client_id' => 'your_client_id',
        'client_secret' => 'your_client_secret'
        'access_token' => 'your_access_token'
    });

The second way is to use the setter methods:

    $client->set_access_token('your_access_token');
    $client->set_client_id('your_client_id');

=head2 Refreshing Access Tokens

Access tokens expire after a period of time. To get a new access token, you can use the C<refresh_access_token> method. This method requires the refresh token, client id and client secret. You can pass these values to the method or set them using the setter methods. If you don't pass them and they're not set, the method will die. If the function is successful it will update the internal access_token and refresh_token to use for subsequent requests and then return them in a hashref.

    my %args = (
        'refresh_token' => 'your_refresh_token',
        'client_id' => 'your_client_id',
        'client_secret' => 'your_client_secret'
    );
    my $refresh_token = get_refresh_token_from_datastore();

    my $resp = $client->refresh_access_token(\%args);
    my $new_refresh_token = $resp->{'refresh_token'};

    # Store the new refresh token somewhere persistent so it can be used later when the new access token expires.


=head2 METHODS

=head3 new

    $client = ImgurAPI::Client->new(\%args);

Valid constructor arguments are:

=over 4

=item *

C<access_key> - Access token used to authenticate requests.

=item *

C<client_id> - Client identifier used for authorization, refresh token requests and unauthenticated requests.

=item *

C<client_secret> - Client secret used for acquiring a refresh token.

=item *

C<format_type> - Api endpoint response format type. Options are C<json> (default) and C<xml>.

=item *

C<oauth_cb_state> - A parameter that's appended to the OAuth2 authorization callback URL. May be useful if you want to pass along a tracking value to the callback endpoint / collector.

=item *

C<rapidapi_key> - Commercial use api key provided by RapidAPI.

=item *

C<user_agent> - User agent string to use for requests (default: 'ImgurAPI::Client/X.X.X')

=back

A getter and setter method is provided for each constructor arg.

=head3 SETTER METHODS


=head4 set_access_token

    $client->set_access_token('your_access_token');

=head4 set_client_id

    $client->set_client_id('your_client_id');

=head4 set_client_secret

    $client->set_client_secret('your_client_secret');

=head4 set_format_type

    $client->set_format_type('xml');

=head4 set_oauth_cb_state

    $client->set_oauth_cb_state('your_oauth_cb_state');

=head4 set_rapidapi_key

    $client->set_rapidapi_key('rapidapi_key');

=head4 set_user_agent

    $client->set_user_agent('your_user_agent');

=head3 GETTER METHODS

=head4 access_token

    $access_tok = $client->access_token;

=head4 client_id

    $client_id = $client->client_id;

=head4 client_secret

    $client_secret = $client->client_secret;

=head4 format_type

    $format_type = $client->format_type;

=head4 oauth_cb_state

    $oauth_cb_state = $client->oauth_cb_state;

=head4 rapidapi_key

    $rapidapi_key = $client->rapidapi_key;

=head4 response

    $response = $client->response;

This method will return the last response object from the last request.

=head4 response_content

    $response_content = $client->response_content;

This method will return the last response content from the last request.

=head4 ratelimit_headers

    $ratelimit_headers = $client->ratelimit_headers;

This method will return a hashref containing the rate limit headers from the last request. The keys returned are:

=head4 user_agent

    $user_agent = $client->user_agent;

Returns the current user agent string.

=over 4

=item *

C<userlimit> - The total credits that can be allocated.

=item *

C<userremaining> - The total credits remaining.

=item *

C<userreset> - Timestamp (unix epoch) for when the credits will be reset.

=item *

C<clientlimit> - Total credits that can be allocated for the application in a day.

=item *

C<clientremaining> - Total credits remaining for the application in a day.

=back

You can also get rate limit information by calling the C<credits> method.


=head3 API REQUEST METHODS


=head4 ACCOUNT

=head5 account

    $resp = $client->account($username);

Get account information for a given username. Pass C<me> as the username to get the account information for the authenticated user.

=head5 account_album

    $resp = $client->account_album($username, $album_id);

Get information about a specific account album. Pass C<me> as the username to get the account information for the authenticated user.

=head5 account_album_count

    $resp = $client->account_album_count($username);

Get the total number of albums associated with an account. Pass C<me> as the username to get the account information for the authenticated user.

=head5 account_album_delete

    $resp = $client->account_album_delete($username, $album_id);

Delete a specific album. Pass C<me> as the username to get the account information for the authenticated user.

=head5 account_album_ids

    $resp = $client->account_album_ids($username, \%opts);

Get all the album ids associated with the account. Pass C<me> as the username to get the account information for the authenticated user.

Valid C<\%opts> keys are:

=over 4

=item *

C<page> - Page number

=back

=head5 account_albums

    $resp = $client->account_albums($username, \%opts);

Valid C<\%opts> keys are:

=over 4

=item *

C<page> - Page number

=back

=head5 account_block_status

    $resp = $client->account_block_status($username);

Get the current block status for a user.

=head5 account_block_create

    $resp = $client->account_block_create($username);

Block a user.

=head5 account_block_delete

    $resp = $client->account_block_delete($username);

Unblock a user.

=head5 account_blocks

    $resp = $client->account_blocks;

Get the list of usernames that have been blocked.

=head5 account_comment

    $resp = $client->account_comment($username, $comment_id);

Get information about a specific account comment.

=head5 account_comment_count

    $resp = $client->account_comment_count($username);

Get the total number of comments associated with the account username.

=head5 account_comment_delete

    $resp = $client->account_comment_delete($username, $comment_id);

Delete a specific account comment.

=head5 account_comment_ids

    $resp = $client->account_comment_ids($username, \%opts);

Valid C<\%opts> keys are:

=over 4

=item *

C<page> - Page number

=item *

C<sort> - Sort order. Options are C<best>, C<worst> and C<newest> (default)

=back

=head5 account_comments

    $resp = $client->account_comments($username, \%opts);

Valid C<\%opts> keys are:

=over 4

=item *

C<page> - Page number

=item *

C<sort> - Sort order. Options are C<best>, C<worst> and C<newest> (default)

=back

=head5 account_delete

    $resp = $client->account_delete($password, \%opts);

Valid C<\%opts> keys are:

=over 4

=item *

C<reasons> - Array reference of reasons for deleting the account

=item *

C<feedback> - Feedback in the form of a string for Imgur.

=back

=head5 account_favorites

    $resp = $client->account_favorites($username, \%opts);

Valid C<\%opts> keys are:

=over 4

=item *

C<page> - Page number

=item *

C<sort> - Sort order. Options are C<oldest> or C<newest> (default)

=back

=head5 account_gallery_favorites

    $resp = $client->account_gallery_favorites($username, \%opts);

Valid C<\%opts> keys are:

=over 4

=item *

C<page> - Page number

=item *

C<sort> - Sort order. Options are C<oldest> or C<newest> (default)

=back

=head5 account_image

    $resp = $client->account_image($username, $image_id);

Get information about a specific image in the account.

=head5 account_image_count

    $resp = $client->account_image_count($username);

Get the total number of images associated with the account.

=head5 account_image_delete

    $resp = $client->account_image_delete($username, $image_id);

Delete a specific image.

=head5 account_image_ids

    $resp = $client->account_image_ids($username, \%opts);

Valid C<\%opts> keys are:

=over 4

=item *

C<page> - Page number

=back

=head5 account_images

    $resp = $client->account_images($username, \%opts);

Valid C<\%opts> keys are:

=over 4

=item *

C<page> - Page number

=back

=head5 account_reply_notifications

    $resp = $client->account_reply_notifications($username, \%opts);

Valid C<\%opts> keys are:

=over 4

=item *

C<new> - Boolean value. True for unviewed notifications and false for viewed notifications.

=back

=head5 account_settings

    $resp = $client->account_settings($username);

Get account settings for a given username.

=head5 account_settings_update

    $resp = $client->account_settings_update($username, \%opts);

Update an account's settings.

Valid C<\%opts> keys are:

=over 4

=item *

C<bio> - A string for the bio.

=item *

C<public_images> - A boolean value to set images to public or not by default.

=item *

C<messaging_enabled> - A boolean value to allow messaging or not.

=item *

C<accepted_gallery_terms> - A boolean value to accept the gallery terms.

=item *

C<username> - A valid username between 4 and 63 alphanumeric characters.

=item *

C<show_mature> - A boolean value to show mature images in gallery list endpoints.

=item *

C<newsletter_subscribed> - A boolean value, true to subscribe to the newsletter, false to unsubscribe from the newsletter.

=back

=head5 account_submissions

    $resp = $client->account_submissions($username, \%opts);

Valid C<\%opts> keys are:

=over 4

=item *

C<page> - Page number

=back

=head5 account_tag_follow

    $resp = $client->account_tag_follow($tag);

Follow a tag.

=head5 account_tag_unfollow

    $resp = $client->account_tag_unfollow($tag);

Unfollow a tag.

=head5 account_verify_email_send

    $resp = $client->account_verify_email_send($username);

Send a verification email.

=head5 account_verify_email_status

    $resp = $client->account_verify_email_status($username);

Get the status of the verification email.

=head4 ALBUM

=head5 album

    $resp = $client->album($album_id);

Get information about a specific album.

=head5 album_create

    $resp = $client->album_create(\%opts);

=over 4

=item *

C<ids> - Array reference of image ids.

=item *

C<title> - Title of the album.

=item *

C<description> - Description of the album.

=item *

C<cover> - Image id of the cover image.

=back

=head5 album_delete

    $resp = $client->album_delete($album_id);

Delete an album.

=head5 album_favorite

    $resp = $client->album_favorite($album_id);

Favorite an album.

=head5 album_image

    $resp = $client->album_image($album_id, $image_id);

Get information about a specific image in an album.

=head5 album_images

    $resp = $client->album_images($album_id);

Get all the images in an album.

=head5 album_images_add

    $resp = $client->album_images_add($album_id, \@image_ids);

Add images to an album.

=head5 album_images_delete

    $resp = $client->album_images_delete($album_id, \@image_ids);

Delete images from an album.

=head5 album_images_set

    $resp = $client->album_images_set($album_id, \@image_ids);

Set the images for an album.

=head5 album_update

    $resp = $client->album_update($album_id, \%opts);

Update an album. Valid C<\%opts> keys are:

=over 4

=item *

C<ids> - Array reference of image ids.

=item *

C<title> - Title of the album.

=item *

C<description> - Description of the album.

=item *

C<cover> - Image id of the cover image.

=back

=head4 COMMENT

=head5 comment

    $resp = $client->comment($comment_id);

Get information about a specific comment.

=head5 comment_create

    $resp = $client->comment_create($image_id, $comment);

Create a new comment on an image.

=head5 comment_delete

    $resp = $client->comment_delete($comment_id);

Delete a comment.

=head5 comment_replies

    $resp = $client->comment_replies($comment_id);

Get the replies for a specific comment.

=head5 comment_reply

    $resp = $client->comment_reply($image_id, $comment_id, $comment);

Create a new reply to a comment.

=head5 comment_report

    $resp = $client->comment_report($comment_id, $reason);

Report a comment with a reason. Valid reasons are:

=over 4

=item *

C<1> - Doesn't belong on Imgur

=item *

C<2> - Spam

=item *

C<3> - Abusive

=item *

C<4> - Mature content not marked as mature

=item *

C<5> - Pornography

=back

=head5 comment_vote

    $resp = $client->comment_vote($comment_id, $vote);

Cast a vote on a comment. Valid vote values are C<up>, C<down> and C<veto>.

=head4 GALLERY

=head5 gallery

    $resp = $client->gallery(\%opts);

Get gallery images.

Validation options are:

=over 4

=item *

C<section> - Section. Options are C<hot> (default), C<top> and C<user>.

=item *

C<sort> - Sort order. Options are C<viral> (default), C<top>, C<time>, C<rising>.

=item *

C<page> - Page number.

=item *

C<window> - Time window. Options are C<day>, C<week>, C<month>, C<year>, C<all>.

=item *

C<show_viral> - Show or hide viral images in the gallery. Default is C<1>.

=item *

C<album_previews> - Show or hide album previews in the gallery. Default is C<1>.

=back

=head5 gallery_album

    $resp = $client->gallery_album($album_id);

Get additional information about an album in the gallery.


Get information about a specific gallery album.

=head5 gallery_image

    $resp = $client->gallery_image($image_id);

Get additional information about an image in the gallery.

=head5 gallery_item

    $resp = $client->gallery_item($item_id);

Get information about a specific gallery item.

=head5 gallery_item_comment

    $resp = $client->gallery_item_comment($item_id, $comment);

Create a new comment on a gallery item.

=head5 gallery_item_comment_info

    $resp = $client->gallery_item_comment_info($item_id, $comment_id);

Get information about a specific comment on a gallery item.

=head5 gallery_item_comments

    $resp = $client->gallery_item_comments($item_id);

Get all the comments on a gallery item.

=head5 gallery_item_report

    $resp = $client->gallery_item_report($item_id, \%opts);

Report an Image in the gallery


Report a gallery item. Valid C<\%opts> keys are:

=over 4

=item *

C<reason> - Reason for reporting the item. Options are C<1> (doesn't belong on Imgur), C<2> (spam), C<3> (abusive), C<4> (mature content not marked as mature), C<5> (pornography).

=back

=head5 gallery_item_tags

    $resp = $client->gallery_item_tags($item_id);

Get the tags for a gallery item.

=head5 gallery_item_tags_update

    $resp = $client->gallery_item_tags_update($item_id, \@tags);

Update the tags for a gallery item.

=head5 gallery_item_vote

    $resp = $client->gallery_item_vote($item_id, $vote);

Cast a vote on a gallery item. Valid vote values are C<up>, C<down> and C<veto>.

=head5 gallery_item_votes

    $resp = $client->gallery_item_votes($item_id);

Get the votes for a gallery item.

=head5 gallery_image_remove

    $resp = $client->gallery_image_remove($image_id);

Remove an image from the gallery.

=head5 gallery_search

    $resp = $client->gallery_search($query, \%opts, \%advanced);

Search the gallery. Valid C<\%opts> keys are:

=over 4

=item *

C<sort> - Sort order. Options are C<time> (default),  C<viral>, C<top>, C<rising>.

=item *

C<window> - Time window. Options are C<all> (default), C<day>, C<week>, C<month>, C<year>.

=item *

C<page> - Page number.

=back

Valid C<\%advanced> keys are:

=over 4

=item *

C<q_all> - Search for all of these words.

=item *

C<q_any> - Search for any of these words.

=item *

C<q_exactly> - Search for exactly this word or phrase.

=item *

C<q_not> - Exclude results matching this.

=item *

C<q_type> - Show results for any file type, or specific file types. C<jpg>, C<png>, C<gif>, C<anigif> (animated gif), C<album>.

=item *

C<q_size_px> - Return images that are greater or equal to the width/height you specify. C<300x300>.

=back

=head5 gallery_share_image

    $resp = $client->gallery_share_image($image_id, $title, \%opts);

Share an image. Valid C<\%opts> keys are:

=over 4

=item *

C<topic> - Topic of the shared image.

=item *

C<terms> - Terms of the shared image.

=item *

C<mature> - Boolean value to mark the shared image as mature.

=item *

C<tags> - Array reference of tags for the shared image.

=back

=head5 gallery_share_album

    $resp = $client->gallery_share_album($album_id, $title, \%opts);

Share an album. Valid C<\%opts> keys are:

=over 4

=item *

C<topic> - Topic of the shared image.

=item *

C<terms> - Terms of the shared image.

=item *

C<mature> - Boolean value to mark the shared image as mature.

=item *

C<tags> - Array reference of tags for the shared image.

=back

=head5 gallery_subreddit

    $resp = $client->gallery_subreddit($subreddit, \%opts);

Get images from a subreddit.

C<$subreddit> is the name of the subreddit to get images from.

Valid C<\%opts> keys are:

=over 4

=item *

C<sort> - Sort order. Options are C<viral> (default), C<time>, C<top> and C<rising>.

=item *

C<page> - Page number (default is 0)

=item *

C<window> - Window of time. Options are C<day>, C<week> (default), C<month>, C<year>, C<all>.
I can't wait until NY AG starts seizing trumps assets starting monday

=back

=head5 gallery_subreddit_image

    $resp = $client->gallery_subreddit_image('subreddit', $image_id);

=head5 gallery_tag

    $resp = $client->gallery_tag($tag, \%opts);

Returns tag metadata, and posts tagged with the C<$tag> provided

=over 4

=item *

C<sort> - Sort order. Options are C<viral> (default), C<time>, C<top> and C<rising>.

=item *

C<page> - Page number (default is 0)

=item *

C<window> - Window of time. Options are C<day>, C<week> (default), C<month>, C<year>, C<all>.
I can't wait until NY AG starts seizing trumps assets starting monday

=back

=head5 gallery_tag_info

    $resp = $client->gallery_tag_info($tag);

Get gallery tag information.

=head5 gallery_tags

    $resp = $client->gallery_tags;

Gets a list of default tags

=head4 IMAGE

=head5 image

    $resp = $client->image($image_id);

Get information about a specific image.

=head5 image_upload

    $resp = $client->image_upload($src, $type, \%opts);

Upload an image or video to imgur.

C<$src> Path, URL or Base64 encoding of the image or video file.
C<$type> Content type can be either C<file>,  C<url> or C<base64>.

Valid C<\%opts> keys are:

=over 4

=item *

C<title> - Title of the image.

=item *

C<description> - Description of the image.

=back

=head5 image_delete

    $resp = $client->image_delete($image_id);

Delete an image.

=head5 image_favorite

    $resp = $client->image_favorite($image_id);

Favorite an image.

=head5 image_update

    $resp = $client->image_update($image_id, \%opts);

Update an image.

Valid C<\%opts> keys are:

=over 4

=item *

C<title> - Title of the image.

=item *

C<description> - Description of the image.

=back

=head4 FEED

=head5 feed

    $resp = $client->feed;

Get the authenticated user's feed.

=head1 AUTHOR

Dillan Hildebrand

=head1 LICENSE

MIT

=cut

1;
