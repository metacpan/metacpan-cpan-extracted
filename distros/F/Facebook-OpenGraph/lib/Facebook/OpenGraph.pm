package Facebook::OpenGraph;
use strict;
use warnings;
use 5.008001;

use Facebook::OpenGraph::Response;
use HTTP::Request::Common;
use URI;
use Furl::HTTP;
use Data::Recursive::Encode;
use JSON 2 ();
use Carp qw(croak);
use Digest::SHA qw(hmac_sha256 hmac_sha256_hex);
use MIME::Base64::URLSafe qw(urlsafe_b64decode);
use Scalar::Util qw(blessed);

our $VERSION = '1.25';

sub new {
    my $class = shift;
    my $args  = shift || +{};

    return bless +{
        app_id              => $args->{app_id},
        secret              => $args->{secret},
        namespace           => $args->{namespace},
        access_token        => $args->{access_token},
        redirect_uri        => $args->{redirect_uri},
        batch_limit         => $args->{batch_limit} || 50,
        is_beta             => $args->{is_beta} || 0,
        json                => $args->{json} || JSON->new->utf8,
        use_appsecret_proof => $args->{use_appsecret_proof} || 0,
        use_post_method     => $args->{use_post_method} || 0,
        version             => $args->{version} || undef,
        ua                  => $args->{ua} || Furl::HTTP->new(
            capture_request     => 1,
            agent               => __PACKAGE__ . '/' . $VERSION,
        ),
    }, $class;
}

# accessors
sub app_id              { shift->{app_id}              }
sub secret              { shift->{secret}              }
sub ua                  { shift->{ua}                  }
sub namespace           { shift->{namespace}           }
sub access_token        { shift->{access_token}        }
sub redirect_uri        { shift->{redirect_uri}        }
sub batch_limit         { shift->{batch_limit}         }
sub is_beta             { shift->{is_beta}             }
sub json                { shift->{json}                }
sub use_appsecret_proof { shift->{use_appsecret_proof} }
sub use_post_method     { shift->{use_post_method}     }
sub version             { shift->{version}             }

sub uri {
    my $self = shift;

    my $base = $self->is_beta ? 'https://graph.beta.facebook.com/'
             :                  'https://graph.facebook.com/'
             ;

    return $self->_uri($base, @_);
}

sub video_uri {
    my $self = shift;

    my $base = $self->is_beta ? 'https://graph-video.beta.facebook.com/'
             :                  'https://graph-video.facebook.com/'
             ;

    return $self->_uri($base, @_);
}

sub site_uri {
    my $self = shift;

    my $base = $self->is_beta ? 'https://www.beta.facebook.com/'
             :                  'https://www.facebook.com/'
             ;

    return $self->_uri($base, @_);
}

sub _uri {
    my ($self, $base, $path, $param_ref) = @_;
    my $uri = URI->new_abs($path || '/', $base);
    $uri->query_form(+{
        $uri->query_form,       # when given $path is like /foo?bar=bazz
        %{ $param_ref || +{} }, # additional query parameter
    });

    return $uri;
}

# Login for Games on Facebook > Checking Login Status > Parsing the Signed Request
# https://developers.facebook.com/docs/facebook-login/using-login-with-games
sub parse_signed_request {
    my ($self, $signed_request) = @_;
    croak 'signed_request is not given' unless $signed_request;
    croak 'secret key must be set'      unless $self->secret;

    # "1. Split the signed request into two parts delineated by a '.' character
    # (eg. 238fsdfsd.oijdoifjsidf899)"
    my ($enc_sig, $payload) = split(m{ \. }xms, $signed_request);

    # "2. Decode the first part - the encoded signature - from base64url"
    my $sig = urlsafe_b64decode($enc_sig);

    # "3. Decode the second part - the 'payload' - from base64url and then
    # decode the resultant JSON object"
    my $val = $self->json->decode(urlsafe_b64decode($payload));

    # "It specifically uses HMAC-SHA256 encoding, which you can again use with
    # most programming languages."
    croak 'algorithm must be HMAC-SHA256'
        unless uc( $val->{algorithm} ) eq 'HMAC-SHA256';

    # "You can compare this encoded signature with an expected signature using
    # the payload you received as well as the app secret which is known only to
    # your and ensure that they match."
    my $expected_sig = hmac_sha256($payload, $self->secret);
    croak 'Signature does not match' unless $sig eq $expected_sig;

    return $val;
}

# Detailed flow is described here.
# Manually Build a Login Flow > Logging people in > Invoking the login dialog
# https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow/
#
# Parameters for login dialog are shown here.
# Login Dialog > Parameters
# https://developers.facebook.com/docs/reference/dialogs/oauth/
sub auth_uri {
    my ($self, $param_ref) = @_;
    $param_ref ||= +{};
    croak 'redirect_uri and app_id must be set'
        unless $self->redirect_uri && $self->app_id;

    # "A comma separated list of permission names which you would like people
    # to grant your app."
    if (my $scope_ref = ref $param_ref->{scope}) {
        croak 'scope must be string or array ref' unless $scope_ref eq 'ARRAY';
        $param_ref->{scope} = join q{,}, @{ $param_ref->{scope} };
    }

    # "The URL to redirect to after a button is clicked or tapped in the
    # dialog."
    $param_ref->{redirect_uri} = $self->redirect_uri;

    # "Your App ID. This is called client_id instead of app_id for this
    # particular method in order to be compliant with the OAuth 2.0
    # specification."
    $param_ref->{client_id} = $self->app_id;

    # "If you are using the URL redirect dialog implementation, then this will
    # be a full page display, shown within Facebook.com. This display type is
    # called page."
    $param_ref->{display} ||= 'page';

    # "Response data is included as URL parameters and contains code parameter
    # (an encrypted string unique to each login request). This is the default
    # behaviour if this parameter is not specified."
    $param_ref->{response_type} ||= 'code';

    my $uri = $self->site_uri('/dialog/oauth', $param_ref);

    # Platform Versioning > Making Versioned Requests > Dialogs.
    # https://developers.facebook.com/docs/apps/versions#dialogs
    $uri->path( $self->gen_versioned_path($uri->path) );

    return $uri->as_string;
}

sub set_access_token {
    my ($self, $token) = @_;
    $self->{access_token} = $token;
}

# Access Tokens > App Tokens
# https://developers.facebook.com/docs/facebook-login/access-tokens/#apptokens
sub get_app_token {
    my $self = shift;

    # Document does not mention what grant_type is all about or what values can
    # be set, but RFC 6749 covers the basic idea of grant types and its Section
    # 4.4 describes Client Credentials Grant.
    # http://tools.ietf.org/html/rfc6749#section-4.4
    return $self->_get_token(+{grant_type => 'client_credentials'});
}

# Manually Build a Login Flow > Confirming identity > Exchanging code for an access token
# https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow
sub get_user_token_by_code {
    my ($self, $code) = @_;

    croak 'code is not given'        unless $code;
    croak 'redirect_uri must be set' unless $self->redirect_uri;

    my $query_ref = +{
        redirect_uri => $self->redirect_uri,
        code         => $code,
    };
    return $self->_get_token($query_ref);
}

sub get_user_token_by_cookie {
    my ($self, $cookie_value) = @_;

    croak 'cookie value is not given' unless $cookie_value;

    my $parsed_signed_request = $self->parse_signed_request($cookie_value);

    # https://github.com/oklahomer/p5-Facebook-OpenGraph/issues/1#issuecomment-41065480
    # parsed content should be something like below.
    # {
    #     algorithm => "HMAC-SHA256",
    #     issued_at => 1398180151,
    #     code      => "SOME_OPAQUE_STRING",
    #     user_id   => 44007581,
    # };
    croak q{"code" is not contained in cookie value: } . $cookie_value
        unless $parsed_signed_request->{code};

    # Redirect_uri MUST be empty string in this case.
    # That's why I didn't use get_user_token_by_code().
    my $query_ref = +{
        code         => $parsed_signed_request->{code},
        redirect_uri => '',
    };
    return $self->_get_token($query_ref);
}

# Access Tokens > Expiration and Extending Tokens
# https://developers.facebook.com/docs/facebook-login/access-tokens/
sub exchange_token {
    my ($self, $short_term_token) = @_;

    croak 'short term token is not given' unless $short_term_token;

    my $query_ref = +{
        grant_type        => 'fb_exchange_token',
        fb_exchange_token => $short_term_token,
    };
    return $self->_get_token($query_ref);
}

sub _get_token {
    my ($self, $param_ref) = @_;

    croak 'app_id and secret must be set' unless $self->app_id && $self->secret;

    $param_ref = +{
        %$param_ref,
        client_id     => $self->app_id,
        client_secret => $self->secret,
    };

    my $response = $self->request('GET', '/oauth/access_token', $param_ref);
    # Document describes as follows:
    # "The response you will receive from this endpoint, if successful, is
    # access_token={access-token}&expires={seconds-til-expiration}
    # If it is not successful, you'll receive an explanatory error message."
    #
    # It, however, returnes no "expires" parameter on some edge cases.
    # e.g. Your app requests manage_pages permission.
    # https://developers.facebook.com/bugs/597779113651383/
    if ($response->is_api_version_eq_or_later_than('v2.3')) {
        # As of v2.3, to be compliant with RFC 6749, response is JSON formatted
        # as described below.
        # {"access_token": <TOKEN>, "token_type":<TYPE>, "expires_in":<TIME>}
        # https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow/v2.3#confirm
        return $response->as_hashref;
    }

    my $res_content = $response->content;
    my $token_ref = +{ URI->new("?$res_content")->query_form };
    croak "can't get access_token properly: $res_content"
        unless $token_ref->{access_token};

    return $token_ref;
}

sub get {
    return shift->request('GET', @_)->as_hashref;
}

sub post {
    return shift->request('POST', @_)->as_hashref;
}

# Deleting > Objects
# https://developers.facebook.com/docs/reference/api/deleting/
sub delete {
    return shift->request('DELETE', @_)->as_hashref;
}

# For those who got used to Facebook::Graph
*fetch   = \&get;
*publish = \&post;

# Using ETags
# https://developers.facebook.com/docs/reference/ads-api/etags-reference/
sub fetch_with_etag {
    my ($self, $uri, $param_ref, $etag) = @_;

    # Attach ETag value to header
    # Returns status 304 without contnet, or status 200 with modified content
    my $header   = ['IF-None-Match' => $etag];
    my $response = $self->request('GET', $uri, $param_ref, $header);

    return $response->is_modified ? $response->as_hashref : undef;
}

sub bulk_fetch {
    my ($self, $paths_ref) = @_;

    my @queries = map {
        +{
            method       => 'GET',
            relative_url => $_,
        }
    } @$paths_ref;

    return $self->batch(\@queries);
}

# Making Multiple API Requests > Making a simple batched request
# https://developers.facebook.com/docs/graph-api/making-multiple-requests
sub batch {
    my $self  = shift;

    my $responses_ref = $self->batch_fast(@_);

    # Devide response content and create response objects that correspond to
    # each request
    my @data = ();
    for my $r (@$responses_ref) {
        for my $res_ref (@$r) {
            my $response = $self->create_response(
                $res_ref->{code},
                $res_ref->{message},
                [ map { $_->{name} => $_->{value} } @{ $res_ref->{headers} } ],
                $res_ref->{body},
            );
            croak $response->error_string unless $response->is_success;

            push @data, $response->as_hashref;
        }
    }

    return \@data;
}

# doesn't create F::OG::Response object for each response
sub batch_fast {
    my $self  = shift;
    my $batch = shift;

    # Other than HTTP header, you need to set access_token as top level
    # parameter. You can specify individual token for each request so you can
    # act as several other users and pages.
    croak 'Top level access_token must be set' unless $self->access_token;

    # "We currently limit the number of requests which can be in a batch to 50"
    my @responses = ();
    while(my @queries = splice @$batch, 0, $self->batch_limit) {

        for my $q (@queries) {
            if ($q->{method} eq 'POST' && $q->{body}) {
                my $body_ref = $self->prep_param($q->{body});
                my $uri = URI->new;
                $uri->query_form(%$body_ref);
                $q->{body} = $uri->query;
            }
        }

        my @req = (
            '/',
            +{
                access_token => $self->access_token,
                batch        => $self->json->encode(\@queries),
            },
            @_,
        );

        push @responses, $self->post(@req);
    }

    return \@responses;
}

# Facebook Query Language (FQL) Overview
# https://developers.facebook.com/docs/technical-guides/fql/
sub fql {
    my $self  = shift;
    my $query = shift;
    return $self->get('/fql', +{q => $query}, @_);
}

# Facebook Query Language (FQL) Overview: Multi-query
# https://developers.facebook.com/docs/technical-guides/fql/#multi
sub bulk_fql {
    my $self  = shift;
    my $batch = shift;
    return $self->fql($self->json->encode($batch), @_);
}

sub request {
    my ($self, $method, $uri, $param_ref, $headers) = @_;

    $method = uc $method;
    $uri    = $self->uri($uri) unless blessed($uri) && $uri->isa('URI');
    $uri->path( $self->gen_versioned_path($uri->path) );
    $param_ref = $self->prep_param(+{
        $uri->query_form(+{}),
        %{$param_ref || +{}},
    });

    # Securing Graph API Requests > Verifying Graph API Calls with appsecret_proof
    # https://developers.facebook.com/docs/graph-api/securing-requests/
    if ($self->use_appsecret_proof) {
        $param_ref->{appsecret_proof} = $self->gen_appsecret_proof;
    }

    # Use POST as default HTTP method and add method=(POST|GET|DELETE) to query
    # parameter. Document only says we can send HTTP DELETE method or, instead,
    # HTTP POST method with ?method=delete to delete object. It does not say
    # POST with method=(get|post) parameter works, but PHP SDK always sends POST
    # with method parameter so... I just give you this option.
    # Check PHP SDK's base_facebook.php for detail.
    if ($self->{use_post_method}) {
        $param_ref->{method} = $method;
        $method              = 'POST';
    }

    $headers ||= [];

    # Document says we can pass access_token as a part of query parameter,
    # but it actually supports Authorization header to be compliant with the
    # OAuth 2.0 spec.
    # http://tools.ietf.org/html/rfc6749#section-7
    if ($self->access_token) {
        push @$headers, (
                            'Authorization',
                            sprintf('OAuth %s', $self->access_token),
                        );
    }

    my $content = q{};
    if ($method eq 'POST') {
        if ($param_ref->{source} || $param_ref->{file}) {
            # post image or video file

            # https://developers.facebook.com/docs/reference/api/video/
            # When posting a video, use graph-video.facebook.com .
            # base_facebook.php has an equivalent part in isVideoPost().
            # ($method == 'POST' && preg_match("/^(\/)(.+)(\/)(videos)$/", $path))
            # For other actions, use graph.facebook.com/VIDEO_ID/CONNECTION_TYPE
            if ($uri->path =~ m{\A /.+/videos \z}xms) {
                $uri->host($self->video_uri->host);
            }

            # Content-Type should be multipart/form-data
            # https://developers.facebook.com/docs/reference/api/publishing/
            push @$headers, (Content_Type => 'form-data');

            # Furl::HTTP document says we can use multipart/form-data with
            # HTTP::Request::Common.
            my $req = POST $uri, @$headers, Content => [%$param_ref];
            $content = $req->content;
            my $req_header = $req->headers;
            $headers = +[
                map {
                    my $k = $_;
                    map { ( $k => $_ ) } $req_header->header($k);
                } $req_header->header_field_names
            ];
        }
        else {
            # Post simple parameters such as message, link, description, etc...
            # Content-Type: application/x-www-form-urlencoded will be set in
            # Furl::HTTP, and $content will be treated properly.
            $content = $param_ref;
        }
    }
    else {
        $uri->query_form($param_ref);
    }

    my ($res_minor_version, @res_elms) = $self->ua->request(
        method  => $method,
        url     => $uri,
        headers => $headers,
        content => $content,
    );

    my $res = $self->create_response(@res_elms);

    # return F::OG::Response object on success
    return $res if $res->is_success;

    # Use later version of Furl::HTTP to utilize req_headers and req_content.
    # This Should be helpful when debugging.
    my $msg = $res->error_string;
    if ($res->req_headers) {
        $msg .= "\n" . $res->req_headers . $res->req_content;
    }
    croak $msg;
}

# Securing Graph API Requests > Verifying Graph API Calls with appsecret_proof > Generating the proof
# https://developers.facebook.com/docs/graph-api/securing-requests/
sub gen_appsecret_proof {
    my $self = shift;
    croak 'app secret must be set'   unless $self->secret;
    croak 'access_token must be set' unless $self->access_token;
    return hmac_sha256_hex($self->access_token, $self->secret);
}

# Platform Versioning > Making Versioned Requests
# https://developers.facebook.com/docs/apps/versions
sub gen_versioned_path {
    my ($self, $path) = @_;

    $path = '/' unless $path;

    if ($self->version && $path !~ m{\A /v(?:\d+)\.(?:\d+)/ }x) {
        # If default platform version is set on initialisation
        # and given path doesn't contain version,
        # then prepend the default version.
        $path = sprintf('/%s%s', $self->version, $path);
    }

    return $path;
}

sub js_cookie_name {
    my $self = shift;
    croak 'app_id must be set' unless $self->app_id;

    # Cookie is set by JS SDK with a name of fbsr_{app_id}. Official document
    # is not provided for more than 3 yaers so I quote from PHP SDK's code.
    # "Constructs and returns the name of the cookie that potentially houses
    # the signed request for the app user. The cookie is not set by the
    # BaseFacebook class, but it may be set by the JavaScript SDK."
    # The cookie value can be parsed as signed request and it contains 'code'
    # to exchange for access toekn.
    return sprintf('fbsr_%d', $self->app_id);
}

sub create_response {
    my $self = shift;
    return Facebook::OpenGraph::Response->new(+{
        json => $self->json,
        map {
            $_ => shift
        } qw/code message headers content req_headers req_content/,
    });
}

sub prep_param {
    my ($self, $param_ref) = @_;

    $param_ref = Data::Recursive::Encode->encode_utf8($param_ref || +{});

    # /?ids=4,http://facebook-docs.oklahome.net
    if (my $ids = $param_ref->{ids}) {
        $param_ref->{ids} = ref $ids ? join q{,}, @$ids : $ids;
    }

    # mostly for /APP_ID/accounts/test-users
    if (my $perms = $param_ref->{permissions}) {
        $param_ref->{permissions} = ref $perms ? join q{,}, @$perms : $perms;
    }

    # Source and file parameter contains file path.
    # It must be an array ref to work with HTTP::Request::Common.
    if (my $path = $param_ref->{source}) {
        $param_ref->{source} = ref $path ? $path : [$path];
    }
    if (my $path = $param_ref->{file}) {
        $param_ref->{file} = ref $path ? $path : [$path];
    }

    # use Field Expansion
    if (my $field_ref = $param_ref->{fields}) {
        $param_ref->{fields} = $self->prep_fields_recursive($field_ref);
    }

    # Using Objects: Using the Object API
    # https://developers.facebook.com/docs/opengraph/using-objects/#objectapi
    my $object = $param_ref->{object};
    if ($object && ref $object eq 'HASH') {
        $param_ref->{object} = $self->json->encode($object);
    }

    return $param_ref;
}

# Using the Graph API: Reading > Choosing Fields > Making Nested Requests
# https://developers.facebook.com/docs/graph-api/using-graph-api/
sub prep_fields_recursive {
    my ($self, $val) = @_;

    my $ref = ref $val;
    if (!$ref) {
        return $val;
    }
    elsif ($ref eq 'ARRAY') {
        return join q{,}, map { $self->prep_fields_recursive($_) } @$val;
    }
    elsif ($ref eq 'HASH') {
        my @strs = ();
        while (my ($k, $v) = each %$val) {
            my $r = ref $v;
            my $pattern = $r && $r eq 'HASH' ? '%s.%s' : '%s(%s)';
            push @strs, sprintf($pattern, $k, $self->prep_fields_recursive($v));
        }
        return join q{.}, @strs;
    }
}

# Using Actions > Publishing Actions
# https://developers.facebook.com/docs/opengraph/using-actions/#publish
sub publish_action {
    my $self   = shift;
    my $action = shift;
    croak 'namespace is not set' unless $self->namespace;
    return $self->post(sprintf('/me/%s:%s', $self->namespace, $action), @_);
}

# Using Objects > Using the Object API > Images with the Object API
# https://developers.facebook.com/docs/opengraph/using-objects/
sub publish_staging_resource {
    my $self = shift;
    my $file = shift;
    return $self->post('/me/staging_resources', +{file => $file}, @_);
}

# Test Users: Creating
# https://developers.facebook.com/docs/test_users/
sub create_test_users {
    my $self         = shift;
    my $settings_ref = shift;

    if (ref $settings_ref ne 'ARRAY') {
        $settings_ref = [$settings_ref];
    }

    my @settings = ();
    my $relative_url = sprintf('/%s/accounts/test-users', $self->app_id);
    for my $setting (@$settings_ref) {
        push @settings, +{
                            method       => 'POST',
                            relative_url => $relative_url,
                            body         => $setting,
                        };
    }

    return $self->batch(\@settings);
}

# Using Objects > Using Self-Hosted Objects > Updating Objects
# https://developers.facebook.com/docs/opengraph/using-objects/
sub check_object {
    my ($self, $target) = @_;
    my $param_ref = +{
        id     => $target, # $target is object url or open graph object id
        scrape => 'true',
    };
    return $self->post(q{}, $param_ref);
}

1;
__END__

=head1 NAME

Facebook::OpenGraph - Simple way to handle Facebook's Graph API.

=head1 VERSION

This is Facebook::OpenGraph version 1.25

=head1 SYNOPSIS

  use Facebook::OpenGraph;

  # fetching public information about given objects
  my $fb = Facebook::OpenGraph->new;
  my $user = $fb->fetch('zuck');
  my $page = $fb->fetch('oklahomer.docs');
  my $objs = $fb->bulk_fetch([qw/zuck oklahomer.docs/]);

  # get access_token for application
  my $token_ref = Facebook::OpenGraph->new(+{
      app_id => 12345,
      secret => 'FooBarBuzz',
  })->get_app_token;

  # user authorization
  my $fb = Facebook::OpenGraph->new(+{
      app_id       => 12345,
      secret       => 'FooBarBuzz',
      namespace    => 'my_app_namespace',
      redirect_uri => 'https://sample.com/auth_callback',
  });
  my $auth_url = $fb->auth_uri(+{
      scope => [qw/email publish_actions/],
  });
  $c->redirect($auth_url);

  my $req = Plack::Request->new($env);
  my $token_ref = $fb->get_user_token_by_code($req->query_param('code'));
  $fb->set_access_token($token_ref->{access_token});

  # publish photo
  $fb->publish('/me/photos', +{
      source  => '/path/to/pic.png',
      message => 'Hello world!',
  });

  # publish Open Graph Action
  $fb->publish_action($action_type, +{$object_type => $object_url});

=head1 DESCRIPTION

Facebook::OpenGraph is a Perl interface to handle Facebook's Graph API.
This module is inspired by L<Facebook::Graph>, but mainly focuses on simplicity
and customizability because we must be able to keep up with frequently changing
API specification.

This module does B<NOT> provide ways to set and validate parameters for each
API endpoint like Facebook::Graph does with Any::Moose. Instead it provides
some basic methods for HTTP request. It also provides some handy methods that
wrap C<request()> for you to easily utilize most of Graph API's functionalities
including:

=over 4

=item * API versioning that was introduced at f8, 2014.

=item * Acquiring user, app and/or page token and refreshing user token for
long lived one.

=item * Batch Request

=item * FQL

=item * FQL with Multi-Query

=item * Field Expansion

=item * Etag

=item * Wall Posting with Photo or Video

=item * Creating Test Users

=item * Checking and Updating Open Graph Object or Web Page with OGP

=item * Publishing Open Graph Action

=item * Deleting Open Graph Object

=item * Posting Staging Resource for Open Graph Object

=back

In most cases you can specify endpoints and request parameters by yourself and
pass them to request() so it should be easier to test latest API specs. Other
requesting methods merely wrap request() method for convinience.

=head1 METHODS

=head2 Class Methods

=head3 C<< Facebook::OpenGraph->new(\%args) >>

Creates and returns a new Facebook::OpenGraph object.

I<%args> can contain...

=over 4

=item * app_id

Facebook application ID. app_id and secret are required to get application
access token. Your app_id should be obtained from
L<https://developers.facebook.com/apps/>.

=item * secret

Facebook application secret. It should be obtained from
L<https://developers.facebook.com/apps/>.

=item * version

This declares Facebook Platform version. From 2014-04-30 they support versioning
and migrations. Default value is undef because unversioned API access is also
allowed. This value is prepended to the end point on C<request()> unless
you specify one in requesting path.

  my $fb = Facebook::OpenGraph->new(+{version => 'v2.0'});
  $fb->get('/zuck');      # Use version 2.0 by accessing /v2.0/zuck
  $fb->get('/v1.0/zuck'); # Ignore the default version and use version 1.0

  my $fb = Facebook::OpenGraph->new();
  $fb->get('/zuck'); # Unversioned API access since version is not specified
                     # on initialisation or reqeust.

As of 2015-03-29, the latest version is v2.3. Detailed information should be
found at L<https://developers.facebook.com/docs/apps/versions> and
L<https://developers.facebook.com/docs/apps/migrations>.

=item * ua

This should be L<Furl::HTTP> object or similar object that provides same
interface. Default is equivalent to Furl::HTTP->new(capture_request => 1).
You B<SHOULD> install 2.10 or later version of Furl to enable capture_request
option. Or you can specify keep_request option for same purpose if you have Furl
2.09. Setting capture_request option is B<strongly> recommended since it gives
you the request headers and content when C<request()> fails.

  my $fb = Facebook::OpenGraph->new;
  $fb->post('/me/feed', +{message => 'Hello, world!'});
  #2500:- OAuthException:An active access token must be used to query information about the current user.
  #POST /me/feed HTTP/1.1
  #Connection: keep-alive
  #User-Agent: Furl::HTTP/2.15
  #Content-Type: application/x-www-form-urlencoded
  #Content-Length: 27
  #Host: graph.facebook.com
  #
  #message=Hello%2C%20world%21

=item * namespace

Facebook application namespace. This is used when you publish Open Graph Action
via C<publish_action()>.

=item * access_token

Access token for user, application or Facebook Page.

=item * redirect_uri

The URL to be used for authorization. User will be redirected to this URL after
login dialog. Detail should be found at
L<https://developers.facebook.com/docs/reference/dialogs/oauth/>.

You must keep in mind that "The URL you specify must be a URL with the same
base domain specified in your app's settings, a Canvas URL of the form
https://apps.facebook.com/YOUR_APP_NAMESPACE or a Page Tab URL of the form
https://www.facebook.com/PAGE_USERNAME/app_YOUR_APP_ID"

=item * batch_limit

The maximum number of queries that can be set within a single batch request.
If the number of given queries exceeds this, then queries are divided into
multiple batch requests, and responses are combined so it seems just like a
single request.

Default value is 50 as API documentation says. Official documentation is
located at L<https://developers.facebook.com/docs/graph-api/making-multiple-requests/>

You must be aware that "each call within the batch is counted separately for
the purposes of calculating API call limits and resource limits."
See L<https://developers.facebook.com/docs/reference/ads-api/api-rate-limiting/>.

=item * is_beta

Weather to use beta tier. See the official documentation for details.
L<https://developers.facebook.com/support/beta-tier/>.

=item * json

JSON object that handles request parameters and API response. Default is
equivalent to JSON->new->utf8.

=item * use_appsecret_proof

Whether to use appsecret_proof parameter or not. Default is 0.
Long-desired official document is now provided at
L<https://developers.facebook.com/docs/graph-api/securing-requests/>

You must specify access_token and application secret to utilize this.

=back

  my $fb = Facebook::OpenGraph->new(+{
      app_id              => 123456,
      secret              => 'FooBarBuzz',
      ua                  => Furl::HTTP->new(capture_request => 1),
      namespace           => 'fb-app-namespace', # for Open Graph Action
      access_token        => '', # will be appended to request header in request()
      redirect_uri        => 'https://sample.com/auth_callback', # for OAuth
      batch_limit         => 50,
      json                => JSON->new->utf8,
      is_beta             => 0,
      use_appsecret_proof => 1,
      use_post_method     => 0,
      version             => undef,
  })

=head2 Instance Methods

=head3 C<< $fb->app_id >>

Accessor method that returns application id.

=head3 C<< $fb->secret >>

Accessor method that returns application secret.

=head3 C<< $fb->ua >>

Accessor method that returns L<Furl::HTTP> object.

=head3 C<< $fb->namespace >>

Accessor method that returns application namespace.

=head3 C<< $fb->access_token >>

Accessor method that returns access token.

=head3 C<< $fb->redirect_uri >>

Accessor method that returns URL that is used for user authorization.

=head3 C<< $fb->batch_limit >>

Accessor method that returns the maximum number of queries that can be set
within a single batch request. If the number of given queries exceeds this,
then queries are divided into multiple batch requests, and responses are
combined so it just seems like a single batch request. Default value is 50 as
API documentation says.

=head3 C<< $fb->is_beta >>

Accessor method that returns whether to use Beta tier or not.

=head3 C<< $fb->json >>

Accessor method that returns JSON object. This object will be passed to
Facebook::OpenGraph::Response via C<create_response()>.

=head3 C<< $fb->use_appsecret_proof >>

Accessor method that returns whether to send appsecret_proof parameter on API
call. Official document is not provided yet, but PHP SDK has this option and
you can activate this option from App Setting > Advanced > Security.

=head3 C<< $fb->use_post_method >>

Accessor method that returns whether to use POST method for every API call and
alternatively set method=(GET|POST|DELETE) query parameter. PHP SDK works this
way. This might work well when you use multi-query or some other functions that use GET method while query string can be very long and you have to worry about
the maximum length of it.

=head3 C<< $fb->version >>

Accessor method that returns Facebook Platform version. This can be undef
unless you explicitly on initialisation.

=head3 C<< $fb->uri($path, \%query_param) >>

Returns URI object with specified path and query parameter. If is_beta returns
true, the base url is https://graph.beta.facebook.com/ . Otherwise its base url
is https://graph.facebook.com/ . C<request()> automatically determines if it
should use C<uri()> or C<video_uri()> based on target path and parameters so
you won't use C<uri()> or C<video_uri()> directly as long as you are using
requesting methods that are provided in this module.

=head3 C<< $fb->video_uri($path, \%query_param) >>

Returns URI object with specified path and query parameter. This should only be
used when posting a video.

=head3 C<< $fb->site_uri($path, \%query_param) >>

Returns URI object with specified path and query parameter. It is mainly used to
generate URL for Auth dialog, but you can still use this when redirecting users
to your Facebook page, App's Canvas page or any location on facebook.com.

  my $fb = Facebook::OpenGraph->new(+{is_beta => 1});
  $c->redirect($fb->site_uri($path_to_canvas));
  # https://www.beta.facebook.com/$path_to_canvas

=head3 C<< $fb->parse_signed_request($signed_request_str) >>

It parses signed_request that Facebook Platform gives to you on various
situations. situations may include

=over 4

=item * Given as a URL fragment on callback endpoint after login flow is done
with Login Dialog

=item * POSTed when Page Tab App is loaded

=item * Set in a form of cookie by JS SDK

=back

Fields in returning value are introduced at
L<https://developers.facebook.com/docs/reference/login/signed-request/>.

  my $req = Plack::Request->new($env);
  my $val = $fb->parse_signed_request($req->query_param('signed_request'));

=head3 C<< $fb->auth_uri(\%args) >>

Returns URL for Facebook OAuth dialog. You can redirect your user to this
URL for authorization purpose.

If Facebook Platform version is set on initialisation, that value is
prepended to the path.
L<https://developers.facebook.com/docs/apps/versions#dialogs>.

See the detailed flow at L<https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow>.
Optional values are shown at L<https://developers.facebook.com/docs/reference/dialogs/oauth/>.

  my $auth_url = $fb->auth_uri(+{
      display       => 'page', # Dialog's display type. Default value is 'page.'
      response_type => 'code',
      scope         => [qw/email publish_actions/],
  });
  $c->redirect($auth_url);

=head3 C<< $fb->set_access_token($access_token) >>

Set $access_token as the access token to be used on C<request()>. C<access_token()>
returns this value.

=head3 C<< $fb->get_app_token >>

Obtain an access token for application. Give the returning value to
C<set_access_token()> and you can make request on behalf of your application.
This access token never expires unless you reset application secret key on App
Dashboard so you might want to store this value within your process like
below...

  package MyApp::OpenGraph;
  use parent 'Facebook::OpenGraph';

  sub get_app_token {
      my $self = shift;
      return $self->{__app_access_token__}
          ||= $self->SUPER::get_app_token->{access_token};
  }

Or you might want to use L<Cache::Memory::Simple> or something similar to
refetch token at an interval of your choice. Maybe you want to store token on
DB and override this method to return the stored value.

=head3 C<< $fb->get_user_token_by_code($given_code) >>

Obtain an access token for user based on C<$code>. C<$code> should be obtained
on your callback endpoint which is specified on C<eredirect_uri>. Give the
returning access token to C<set_access_token()> and you can act on behalf of
the user.

FYI: I<expires> or I<expires_in> is B<NOT> returned on some edge cases. The
detail and reproductive scenario should be found at
L<https://developers.facebook.com/bugs/597779113651383/>.

  # On OAuth callback page which you specified on $fb->redirect_uri.
  my $req          = Plack::Request->new($env);
  my $token_ref    = $fb->get_user_token_by_code($req->query_param('code'));
  my $access_token = $token_ref->{access_token};
  my $expires      = $token_ref->{expires}; # named expires_in as of v2.3

=head3 C<< $fb->get_user_token_by_cookie($cookie_value) >>

Obtain user access token based on the cookie value that is set by JS SDK.
Cookie name should be determined with C<js_cookie_name()>.

FYI: I<expires> or I<expires_in> is B<NOT> returned on some edge cases. The
detail and reproductive schenario should be found at
L<https://developers.facebook.com/bugs/597779113651383/>.

  if (my $cookie = $c->req->cookie( $fb->js_cookie_name )) {
    # User is not logged in yet, but cookie is set by JS SDK on previous visit.
    my $token_ref = $fb->get_user_token_by_cookie($cookie);
    # {
    #     "access_token" : "new_token_string_qwerty",
    #     "expires" : 5752 # named expires_in as of v2.3
    # };
  }
  else {
    return $c->redirect( $fb->auth_uri );
  }

=head3 C<< $fb->exchange_token($short_term_token) >>

Exchange short lived access token for long lived one. Short lived tokens are
ones that you obtain with C<get_user_token_by_code()>. Usually long lived
tokens live about 60 days while short lived ones live about 2 hours.

FYI: I<expires> or I<expires_in> is B<NOT> returned on some edge cases. The
detail and reproductive schenario should be found at
L<https://developers.facebook.com/bugs/597779113651383/>.

  my $extended_token_ref = $fb->exchange_token($token_ref->{access_token});
  my $access_token       = $extended_token_ref->{access_token};
  my $expires            = $extended_token_ref->{expires};
                           # named expires_in as of v2.3

If you loved the way old offline_access permission worked, and are looking for a
substitute you might want to try this.

=head3 C<< $fb->get($path, \%param, \@headers) >>

Alias to C<request()> that sends C<GET> request.

  my $path = 'zuck'; # should be ID or username
  my $user = $fb->get($path);
  #{
  #    name   => 'Mark Zuckerberg',
  #    id     => 4,
  #    locale => 'en_US',
  #}

=head3 C<< $fb->post($path, \%param, \@headers) >>

Alias to C<request()> that sends C<POST> request.

  my $res = $fb->publish('/me/photos', +{source => '/path/to/pic.png'});
  #{
  #    id      => 123456,
  #    post_id => '123456_987654',
  #
  #}

=head3 C<< $fb->fetch($path, \%param, \@headers) >>

Alias to C<get()> for those who got used to L<Facebook::Graph>

=head3 C<< $fb->publish($path, \%param, \@headers) >>

Alias to C<post()> for those who got used to L<Facebook::Graph>

=head3 C<< $fb->fetch_with_etag($path, \%param, $etag_value) >>

Alias to C<request()> that sends C<GET> request with given ETag value. Returns
undef if requesting data is not modified. Otherwise it returns modified data.

  my $user = $fb->fetch_with_etag('/zuck', +{fields => 'email'}, $etag);

=head3 C<< $fb->bulk_fetch(\@paths) >>

Request batch request and returns an array reference.

  my $data = $fb->bulk_fetch([qw/zuck go.hagiwara/]);
  #[
  #    {
  #        link => 'http://www.facebook.com/zuck',
  #        name => 'Mark Zuckerberg',
  #    },
  #    {
  #        link => 'http://www.facebook.com/go.hagiwara',
  #        name => 'Go Hagiwara',
  #    }
  #]


=head3 C<< $fb->batch(\@requests) >>

Request batch request and returns an array reference of response objects. It
sets C<$fb->access_token> as top level access token, but other than that you
can specify indivisual access token for each request. The document says
"The Batch API is flexible and allows individual requests to specify their own
access tokens as a query string or form post parameter. In that case the top
level access token is considered a fallback token and is used if an individual
request has not explicitly specified an access token."

  my $data = $fb->batch([
      +{method => 'GET', relative_url => 'zuck'},
      +{method => 'GET', relative_url => 'oklahomer.docs'},
  ]);

=head3 C<< $fb->batch_fast(\@requests) >>

Request batch request and returns results as array reference, but it doesn't
create L<Facebook::OpenGraph::Response> to handle each response.

  my $data = $fb->batch_fast([
      +{method => 'GET', relative_url => 'zuck'},
      +{method => 'GET', relative_url => 'oklahomer.docs'},
  ]);
  #[
  #    [
  #        {
  #            body    => {id => 4, name => 'Mark Zuckerberg', .....},
  #            headers => [ .... ],
  #            code    => 200,
  #        },
  #        {
  #            body    => {id => 204277149587596, name => 'Oklahomer', .....},
  #            headers => [ .... ],
  #            code    => 200,
  #        },
  #    ]
  #]

You can specify access token for each query within a single batch request.
See L<https://developers.facebook.com/docs/graph-api/making-multiple-requests/>
for detail.

=head3 C<< $fb->fql($fql_query) >>

Alias to C<request()> that optimizes query parameter for FQL query and sends
C<GET> request.

  my $res = $fb->fql('SELECT display_name FROM application WHERE app_id = 12345');
  #{
  #    data => [{
  #        display_name => 'app',
  #    }],
  #}

=head3 C<< $fb->bulk_fql(\%fql_queries) >>

Alias to C<fql()> to request multiple FQL query at once.

  my $res = $fb->bulk_fql(+{
      'all friends' => 'SELECT uid2 FROM friend WHERE uid1 = me()',
      'my name'     => 'SELECT name FROM user WHERE uid = me()',
  });
  #{
  #    data => [
  #        {
  #            fql_result_set => [
  #                {uid2 => 12345},
  #                {uid2 => 67890},
  #            ],
  #            name => 'all friends',
  #        },
  #        {
  #            fql_result_set => [
  #                name => 'Michael Corleone'
  #            ],
  #            name => 'my name',
  #        },
  #    ],
  #}

=head3 C<< $fb->delete($path, \%param) >>

Alias to C<request()> that sends DELETE request to delete object on Facebook's
social graph. It sends POST request with method=delete query parameter when
DELETE request fails. I know it's weird, but sometimes DELETE fails and POST
with method=delete works.

  $fb->delete($object_id);

=head3 C<< $fb->request($request_method, $path, \%param, \@headers) >>

Sends request to Facebook Platform and returns L<Facebook::Graph::Response>
object.

=head3 C<< $fb->gen_appsecret_proof >>

Generates signature for appsecret_proof parameter. This method is called in
C<request()> if C<$self->use_appsecret_proof> is set. See
L<http://facebook-docs.oklahome.net/archives/52097348.html> for Japanese Info.

=head3 C<< $fb->js_cookie_name >>

Generates and returns the name of cookie that is set by JS SDK on client side
login. This value can be parsed as signed request and the parsed data structure
contains 'code' to exchange for acess token. See C<get_user_token_by_cookie()>
for detail.

=head3 C<< $fb->create_response($http_status_code, $http_status_message, \@response_headers, $response_content) >>

Creates and returns L<Facebook::OpenGraph::Response>. If you wish to use
customized response class, then override this method to return
MyApp::Better::Response.

=head3 C<< $fb->prep_param(\%param) >>

Handles sending parameters and format them in the way Graph API spec states.
This method is called in C<request()> so you don't usually use this method
directly.

=head3 C<< $fb->prep_fields_recursive(\@fields) >>

Handles fields parameter and format it in the way Graph API spec states.
The main purpose of this method is to deal with Field Expansion
(L<https://developers.facebook.com/docs/graph-api/using-graph-api/#fieldexpansion>).
This method is called in C<prep_param> which is called in C<request()> so you
don't usually use this method directly.

  # simple fields
  $fb->prep_fields_recursive([qw/name email albums/]); # name,email,albums

  # use field expansion
  $fb->prep_fields_recursive([
      'name',
      'email',
      +{
          albums => +{
              fields => [
                  'name',
                  +{
                      photos => +{
                          fields => [
                              'name',
                              'picture',
                              +{
                                  tags => +{
                                      limit => 2,
                                  },
                              }
                          ],
                          limit => 3,
                      }
                  }
              ],
              limit => 5,
          }
      }
  ]);
  # 'name,email,albums.fields(name,photos.fields(name,picture,tags.limit(2)).limit(3)).limit(5)'

=head3 C<< $fb->publish_action($action_type, \%param) >>

Alias to C<request()> that optimizes body content and endpoint to send C<POST>
request to publish Open Graph Action.

  my $res = $fb->publish_action('give', +{crap => 'https://sample.com/poop/'});
  #{id => 123456}

=head3 C<< $fb->create_test_users(\@settings) >>

  my $res = $fb->create_test_users([
      +{
          permissions => [qw/publish_actions/],
          locale      => 'en_US',
          installed   => 'true',
      },
      +{
          permissions => [qw/publish_actions email read_stream/],
          locale      => 'ja_JP',
          installed   => 'true',
      }
  ])
  #[
  #    +{
  #        id           => 123456789,
  #        access_token => '5678uiop',
  #        login_url    => 'https://www.facebook.com/........',
  #        email        => '.....@tfbnw.net',
  #        password     => '.......',
  #    },
  #    +{
  #        id           => 1234567890,
  #        access_token => '5678uiopasadfasdfa',
  #        login_url    => 'https://www.facebook.com/........',
  #        email        => '.....@tfbnw.net',
  #        password     => '.......',
  #    },
  #];

Alias to C<request()> that optimizes to create test users for your application.

=head3 C<< $fb->publish_staging_resource($file_path) >>

Alias to C<request()> that optimizes body content to send C<POST> request to upload image to Object API's staging environment.

  my $fb = Facebook::OpenGraph->new(+{
      access_token => $USER_ACCESS_TOKEN,
  });
  my $res = $fb->publish_staging_resource('/path/to/file');
  #{
  #  uri => 'fbstaging://graph.facebook.com/staging_resources/MDExMzc3MDU0MDg1ODQ3OTY2OjE5MDU4NTM1MzQ=',
  #};

=head3 C<< $fb->check_object($object_id_or_url) >>

Alias to C<request()> that sends C<POST> request to Facebook Debugger to
check/update object.

  $fb->check_object('https://sample.com/object/');
  $fb->check_object($object_id);

=head1 AUTHOR

Oklahomer E<lt>hagiwara dot go at gmail dot comE<gt>

=head1 SUPPORT

=over 4

=item * Repository

L<https://github.com/oklahomer/p5-Facebook-OpenGraph/>

=item * Bug Reports

L<https://github.com/oklahomer/p5-Facebook-OpenGraph/issues>

=back

=head1 SEE ALSO

L<Facebook::Graph>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
