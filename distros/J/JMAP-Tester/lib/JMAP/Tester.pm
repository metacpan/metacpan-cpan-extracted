use v5.10.0;
use warnings;

package JMAP::Tester;
# ABSTRACT: a JMAP client made for testing JMAP servers
$JMAP::Tester::VERSION = '0.017';
use Moo;

use Crypt::Misc qw(decode_b64u encode_b64u);
use Crypt::Mac::HMAC qw(hmac_b64u);
use Encode qw(encode_utf8);
use HTTP::Request;
use JMAP::Tester::Abort 'abort';
use JMAP::Tester::Logger::Null;
use JMAP::Tester::Response;
use JMAP::Tester::Result::Auth;
use JMAP::Tester::Result::Download;
use JMAP::Tester::Result::Failure;
use JMAP::Tester::Result::Logout;
use JMAP::Tester::Result::Upload;
use Module::Runtime ();
use Params::Util qw(_HASH0 _ARRAY0);
use URI;
use URI::QueryParam;
use Scalar::Util qw(weaken);
use URI::Escape qw(uri_escape);

use namespace::clean;

#pod =head1 OVERVIEW
#pod
#pod B<Achtung!>  This library is in its really early days, so use it with that in
#pod mind.
#pod
#pod JMAP::Tester is for testing JMAP servers.  Okay?  Okay!
#pod
#pod JMAP::Tester calls the whole thing you get back from a JMAP server a "response"
#pod if it's an HTTP 200.  Every JSON Array (of three entries -- go read the spec if
#pod you need to!) is called a L<Sentence|JMAP::Tester::Response::Sentence>.  Runs
#pod of Sentences with the same client id are called
#pod L<Paragraphs|JMAP::Tester::Response::Paragraph>.
#pod
#pod You use the test client like this:
#pod
#pod   my $jtest = JMAP::Tester->new({
#pod     api_uri => 'https://jmap.local/account/123',
#pod   });
#pod
#pod   my $response = $jtest->request([
#pod     [ getMailboxes => {} ],
#pod     [ getMessageUpdates => { sinceState => "123" } ],
#pod   ]);
#pod
#pod   # This returns two Paragraph objects if there are exactly two paragraphs.
#pod   # Otherwise, it throws an exception.
#pod   my ($mbx_p, $msg_p) = $response->assert_n_paragraphs(2);
#pod
#pod   # These get the single Sentence of each paragraph, asserting that there is
#pod   # exactly one Sentence in each Paragraph, and that it's of the given type.
#pod   my $mbx = $mbx_p->single('mailboxes');
#pod   my $msg = $msg_p->single('messageUpdates');
#pod
#pod   is( @{ $mbx->arguments->{list} }, 10, "we expect 10 mailboxes");
#pod   ok( ! $msg->arguments->{hasMoreUpdates}, "we got all the msg updates needed");
#pod
#pod By default, all the structures returned have been passed through
#pod L<JSON::Typist>, so you may want to strip their type data before using normal
#pod Perl code on them.  You can do that with:
#pod
#pod   my $struct = $response->as_triples;  # gets the complete JSON data
#pod   $jtest->strip_json_types( $struct ); # strips all the JSON::Typist types
#pod
#pod Or more simply:
#pod
#pod   my $struct = $response->as_stripped_triples;
#pod
#pod There is also L<JMAP::Tester::Response/"as_stripped_pairs">.
#pod
#pod =cut

has json_codec => (
  is => 'bare',
  handles => {
    json_encode => 'encode',
    json_decode => 'decode',
  },
  default => sub {
    require JSON;
    return JSON->new->utf8->allow_blessed->convert_blessed;
  },
);

has _json_typist => (
  is => 'ro',
  handles => {
    apply_json_types => 'apply_types',
    strip_json_types => 'strip_types',
  },
  default => sub {
    require JSON::Typist;
    return JSON::Typist->new;
  },
);

for my $type (qw(api authentication download upload)) {
  has "$type\_uri" => (
    is => 'rw',
    predicate => "has_$type\_uri",
    clearer   => "clear_$type\_uri",
  );
}

has ua => (
  is   => 'ro',
  lazy => 1,
  default => sub {
    my ($self) = @_;

    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    $ua->cookie_jar({});

    if ($ENV{IGNORE_INVALID_CERT}) {
      $ua->ssl_opts(SSL_verify_mode => 0, verify_hostname => 0);
    }

    return $ua;
  },
);

sub _set_cookie {
  my ($self, $name, $value, $arg) = @_;

  Carp::confess("can't _set_cookie without api_uri configured")
    unless $self->has_api_uri;

  my $uri = URI->new($self->api_uri);

  $self->ua->cookie_jar->set_cookie(
    1,
    $name,
    $value,
    '/',
    $arg->{domain} // $uri->host,
    $uri->port,
    0,
    ($uri->port == 443 ? 1 : 0),
    86400,
    0,
    $arg->{rest} || {},
  );
}

#pod =attr default_arguments
#pod
#pod This is a hashref of arguments to be put into each method call.  It's
#pod especially useful for setting a default C<accountId>.  Values given in methods
#pod passed to C<request> will override defaults.  If the value is a reference to
#pod C<undef>, then no value will be passed for that key.
#pod
#pod In other words, in this situation:
#pod
#pod   my $tester = JMAP::Tester->new({
#pod     ...,
#pod     default_arguments => { a => 1, b => 2, c => 3 },
#pod   });
#pod
#pod   $tester->request([
#pod     [ eatPies => { a => 100, b => \undef } ],
#pod   ]);
#pod
#pod The request will effectively be:
#pod
#pod   [ [ "eatPies", { "a": 100, "c": 3 }, "a" ] ]
#pod
#pod =cut

has default_arguments => (
  is  => 'rw',
  default => sub {  {}  },
);

#pod =method request
#pod
#pod   my $result = $jtest->request([
#pod     [ methodOne => { ... } ],
#pod     [ methodTwo => { ... } ],
#pod   ]);
#pod
#pod This method accepts either an arrayref of method calls or a hashref with a
#pod C<methodCalls> key.  It sends the calls to the JMAP server and returns a
#pod result.
#pod
#pod For each method call, if there's a third element (a I<client id>) then it's
#pod left as-is.  If no client id is given, one is generated.  You can mix explicit
#pod and autogenerated client ids.  They will never conflict.
#pod
#pod The arguments to methods are JSON-encoded with a L<JSON::Typist>-aware encoder,
#pod so JSON::Typist types can be used to ensure string or number types in the
#pod generated JSON.  If an argument is a reference to C<undef>, it will be removed
#pod before the method call is made.  This lets you override a default by omission.
#pod
#pod The return value is an object that does the L<JMAP::Tester::Result> role,
#pod meaning it's got an C<is_success> method that returns true or false.  For now,
#pod at least, failures are L<JMAP::Tester::Result::Failure> objects.  More refined
#pod failure objects may exist in the future.  Successful requests return
#pod L<JMAP::Tester::Response> objects.
#pod
#pod =cut

sub request {
  my ($self, $input_request) = @_;

  Carp::confess("can't perform request: no api_uri configured")
    unless $self->has_api_uri;

  state $ident = 'a';
  my %seen;
  my @suffixed;

  my %default_args = %{ $self->default_arguments };

  my $request = _ARRAY0($input_request)
              ? { methodCalls => $input_request }
              : { %$input_request };

  for my $call (@{ $request->{methodCalls} }) {
    my $copy = [ @$call ];
    if (defined $copy->[2]) {
      $seen{$call->[2]}++;
    } else {
      my $next;
      do { $next = $ident++ } until ! $seen{$ident}++;
      $copy->[2] = $next;
    }

    my %arg = (
      %default_args,
      %{ $copy->[1] // {} },
    );

    for my $key (keys %arg) {
      if ( ref $arg{$key}
        && ref $arg{$key} eq 'SCALAR'
        && ! defined ${ $arg{$key} }
      ) {
        delete $arg{$key};
      }
    }

    $copy->[1] = \%arg;

    push @suffixed, $copy;
  }

  $request->{methodCalls} = \@suffixed;

  $request = $request->{methodCalls}
    if $ENV{JMAP_TESTER_NO_WRAPPER} && _ARRAY0($input_request);

  my $json = $self->json_encode($request);

  my $post = HTTP::Request->new(
    POST => $self->api_uri,
    [
      'Content-Type' => 'application/json',
      $self->_maybe_auth_header,
    ],
    $json,
  );

  # Or our sub below leaks us
  weaken $self;

  $self->ua->set_my_handler(request_send => sub {
    my ($req) = @_;
    $self->_logger->log_jmap_request({
      jmap_array   => \@suffixed,
      json         => $json,
      http_request => $req,
    });
    return;
  });

  my $http_res = $self->ua->request($post);

  unless ($http_res->is_success) {
    $self->_logger->log_jmap_response({
      http_response => $http_res,
    });

    return JMAP::Tester::Result::Failure->new({
      http_response => $http_res,
    });
  }

  return $self->_jresponse_from_hresponse($http_res);
}

sub _jresponse_from_hresponse {
  my ($self, $http_res) = @_;

  # TODO check that it's really application/json!
  my $json = $http_res->decoded_content;

  my $data = $self->apply_json_types( $self->json_decode( $json ) );

  my ($items, $props);
  if (_HASH0($data)) {
    $props = $data;
    $items = $props->{methodResponses};
  } elsif (_ARRAY0($data)) {
    $props = {};
    $items = $data;
  } else {
    abort("illegal response to JMAP request: $data");
  }

  $self->_logger->log_jmap_response({
    jmap_array    => $items,
    json          => $json,
    http_response => $http_res,
  });

  return JMAP::Tester::Response->new({
    items => $items,
    http_response       => $http_res,
    wrapper_properties  => $props,
  });
}

has _logger => (
  is => 'ro',
  default => sub {
    if ($ENV{JMAP_TESTER_LOGGER}) {
      my ($class, $filename) = split /:/, $ENV{JMAP_TESTER_LOGGER};
      $class = "JMAP::Tester::Logger::$class";
      Module::Runtime::require_module($class);

      return $class->new({
        writer => $filename // 'jmap-tester-{T}-{PID}.log'
      });
    }

    JMAP::Tester::Logger::Null->new({ writer => \undef });
  },
);

#pod =method upload
#pod
#pod   my $result = $tester->upload($mime_type, $blob_ref, \%arg);
#pod
#pod This uploads the given blob, which should be given as a reference to a string.
#pod
#pod The return value will either be a L<failure
#pod object|JMAP::Tester::Result::Failure> or an L<upload
#pod result|JMAP::Tester::Result::Upload>.
#pod
#pod =cut

sub upload {
  my ($self, $mime_type, $blob_ref) = @_;
  # TODO: support blob as handle or sub -- rjbs, 2016-11-17

  Carp::confess("can't upload without upload_uri")
    unless $self->upload_uri;

  my $post = HTTP::Request->new(
    POST => $self->upload_uri,
    [
      'Content-Type' => $mime_type,
      $self->_maybe_auth_header,
    ],
    $$blob_ref,
  );

  $self->ua->set_my_handler(request_send => sub {
    my ($req) = @_;
    $self->_logger->log_upload_request({
      http_request => $req,
    });
    return;
  });

  my $res = $self->ua->request($post);

  unless ($res->is_success) {
    $self->_logger->log_upload_response({
      http_response => $res,
    });

    return JMAP::Tester::Result::Failure->new({
      http_response => $res,
    });
  }

  my $json = $res->decoded_content;
  my $blob = $self->apply_json_types( $self->json_decode( $json ) );

  $self->_logger->log_upload_response({
    json          => $json,
    blob_struct   => $blob,
    http_response => $res,
  });

  return JMAP::Tester::Result::Upload->new({
    http_response => $res,
    payload       => $blob,
  });
}

#pod =method download
#pod
#pod   my $result = $tester->download(\%arg);
#pod
#pod Valid arguments are:
#pod
#pod   blobId    - the blob to download (no default)
#pod   accountId - the account for which we're downloading (no default)
#pod   name      - the name we want the server to provide back (default: "download")
#pod
#pod If the download URI template has a C<blobId> or C<accountId> placeholder but no
#pod argument for that is given to C<download>, an exception will be thrown.
#pod
#pod The return value will either be a L<failure
#pod object|JMAP::Tester::Result::Failure> or an L<upload
#pod result|JMAP::Tester::Result::Download>.
#pod
#pod =cut

my %DL_DEFAULT = (name => 'download');

sub download_uri_for {
  my ($self, $arg) = @_;

  Carp::confess("can't compute download URI without configured download_uri")
    unless my $uri = $self->download_uri;

  for my $param (qw(blobId accountId name)) {
    next unless $uri =~ /\{$param\}/;
    my $value = $arg->{ $param } // $DL_DEFAULT{ $param };

    Carp::confess("missing required template parameter $param")
      unless defined $value;

    if ($param eq 'name') {
      $value = uri_escape($value);
    }

    $uri =~ s/\{$param\}/$value/g;
  }

  if (my $jwtc = $self->_get_jwt_config) {
    my $to_get  = URI->new($uri);
    my $to_sign = $to_get->clone->canonical;

    $to_sign->query(undef);

    my $header = encode_b64u( $self->json_encode({
      alg => 'HS256',
      typ => 'JWT',
    }) );

    my $payload = encode_b64u( $self->json_encode({
      iss => $jwtc->{signingId},
      iat => time,
      sub => "$to_sign",
    }) );

    my $signature = hmac_b64u(
      'SHA256',
      decode_b64u($jwtc->{signingKey}),
      "$header.$payload",
    );

    $to_get->query_param(access_token => "$header.$payload.$signature");
    $uri = "$to_get";
  }

  return $uri;
}

sub download {
  my ($self, $arg) = @_;

  my $uri = $self->download_uri_for($arg);

  my $get = HTTP::Request->new(
    GET => $uri,
    $self->_maybe_auth_header,
  );

  $self->ua->set_my_handler(request_send => sub {
    my ($req) = @_;
    $self->_logger->log_download_request({
      http_request => $req,
    });
    return;
  });

  my $res = $self->ua->request($get);

  $self->_logger->log_download_response({
    http_response => $res,
  });

  unless ($res->is_success) {
    return JMAP::Tester::Result::Failure->new({
      http_response => $res,
    });
  }

  return JMAP::Tester::Result::Download->new({
    http_response => $res,
  });
}

#pod =method simple_auth
#pod
#pod   my $auth_struct = $tester->simple_auth($username, $password);
#pod
#pod =cut

sub _maybe_auth_header {
  my ($self) = @_;
  return ($self->_access_token
          ? (Authorization => "Bearer " . $self->_access_token)
          : ());
}

has _jwt_config => (
  is => 'rw',
  init_arg => undef,
);

sub _now_timestamp {
  #   0     1     2      3      4     5
  my ($sec, $min, $hour, $mday, $mon, $year) = gmtime;
  return sprintf '%04u-%02u-%02uT%02u:%02u:%02uZ',
    $year + 1900, $mon + 1, $mday,
    $hour, $min, $sec;
}

sub _get_jwt_config {
  my ($self) = @_;
  return unless my $jwtc = $self->_jwt_config;
  return $jwtc unless $jwtc->{signingKeyValidUntil};
  return $jwtc if $jwtc->{signingKeyValidUntil} gt $self->_now_timestamp;

  $self->update_client_session;
  return unless $jwtc = $self->_jwt_config;
  return $jwtc;
}

has _access_token => (
  is  => 'rw',
  init_arg => undef,
);

sub simple_auth {
  my ($self, $username, $password) = @_;

  # This is fatal, not a failure return, because it reflects the user screwing
  # up, not a possible JMAP-related condition. -- rjbs, 2016-11-17
  Carp::confess("can't simple_auth: no authentication_uri configured")
    unless $self->has_authentication_uri;

  my $start_json = $self->json_encode({
    username      => $username,
    clientName    => (ref $self),
    clientVersion => $self->VERSION // '0',
    deviceName    => 'JMAP Testing Client',
  });

  my $start_res = $self->ua->post(
    $self->authentication_uri,
    [
      'Content-Type' => 'application/json; charset=utf-8',
      'Accept'       => 'application/json',
      'Content'      => $start_json,
    ],
  );

  unless ($start_res->code == 200) {
    return JMAP::Tester::Result::Failure->new({
      ident         => 'failure in auth phase 1',
      http_response => $start_res,
    });
  }

  my $start_reply = $self->json_decode( $start_res->decoded_content );

  unless (grep {; $_->{type} eq 'password' } @{ $start_reply->{methods} }) {
    return JMAP::Tester::Result::Failure->new({
      ident         => "password is not an authentication method",
      http_response => $start_res,
    });
  }

  my $next_json = $self->json_encode({
    loginId => $start_reply->{loginId},
    type    => 'password',
    value   => $password,
  });

  my $next_res = $self->ua->post(
    $self->authentication_uri,
    [
      'Content-Type' => 'application/json; charset=utf-8',
      'Accept'       => 'application/json',
      'Content'      => $next_json,
    ],
  );

  unless ($next_res->code == 201) {
    return JMAP::Tester::Result::Failure->new({
      ident         => 'failure in auth phase 2',
      http_response => $next_res,
    });
  }

  my $client_session = $self->json_decode( $next_res->decoded_content );

  my $auth = JMAP::Tester::Result::Auth->new({
    http_response   => $next_res,
    client_session  => $client_session,
  });

  $self->configure_from_client_session($client_session);

  return $auth;
}

#pod =method update_client_session
#pod
#pod   $tester->update_client_session;
#pod   $tester->update_client_session($auth_uri);
#pod
#pod This method fetches the content at the authentication endpoint and uses it to
#pod configure the tester's target URIs and signing keys.
#pod
#pod =cut

sub update_client_session {
  my ($self, $auth_uri) = @_;
  $auth_uri //= $self->authentication_uri;

  my $auth_res = $self->ua->get(
    $auth_uri,
    $self->_maybe_auth_header,
    'Accept' => 'application/json',
  );

  unless ($auth_res->code == 200) {
    return JMAP::Tester::Result::Failure->new({
      ident         => 'failure to get updated authentication data',
      http_response => $auth_res,
    });
  }

  my $client_session = $self->json_decode( $auth_res->decoded_content );

  my $auth = JMAP::Tester::Result::Auth->new({
    http_response   => $auth_res,
    client_session  => $client_session,
  });

  $self->configure_from_client_session($client_session);

  return $auth;
}

#pod =method configure_from_client_session
#pod
#pod   $tester->configure_from_client_session($client_session);
#pod
#pod Given a client session object (like those stored in an Auth result), this
#pod reconfigures the testers access token, signing keys, URIs, and so forth.  This
#pod method is used internally when logging in.
#pod
#pod =cut

sub configure_from_client_session {
  my ($self, $client_session) = @_;

  # It's not crazy to think that we'd also try to pull the primary accountId
  # out of the accounts in the auth struct, but I don't think there's a lot to
  # gain by doing that yet.  Maybe later we'd use it to set the default
  # X-JMAP-AccountId or other things, but I think there are too many open
  # questions.  I'm leaving it out on purpose for now. -- rjbs, 2016-11-18

  # This is no longer fatal because you might be an anonymous session that
  # needs to call this to fetch an updated signing key. -- rjbs, 2017-03-23
  # abort("no accessToken in client session object")
  #  unless $client_session->{accessToken};

  $self->_access_token($client_session->{accessToken});

  if ($client_session->{signingId} && $client_session->{signingKey}) {
    $self->_jwt_config({
      signingId   => $client_session->{signingId},
      signingKey  => $client_session->{signingKey},
      signingKeyValidUntil => $client_session->{signingKeyValidUntil},
    });
  } else {
    $self->_jwt_config(undef);
  }

  for my $type (qw(api authentication download upload)) {
    if (defined (my $uri = $client_session->{"${type}Url"})) {
      my $setter = "$type\_uri";
      $self->$setter($uri);
    } else {
      my $clearer = "clear_$type\_uri";
      $self->$clearer;
    }
  }

  return;
}

#pod =method logout
#pod
#pod   $tester->logout;
#pod
#pod This method attempts to log out from the server by sending a C<DELETE> request
#pod to the authentication URI.
#pod
#pod =cut

sub logout {
  my ($self) = @_;

  # This is fatal, not a failure return, because it reflects the user screwing
  # up, not a possible JMAP-related condition. -- rjbs, 2017-02-10
  Carp::confess("can't logout: no authentication_uri configured")
    unless $self->has_authentication_uri;

  my $logout_res = $self->ua->delete(
    $self->authentication_uri,
    [
      'Content-Type' => 'application/json; charset=utf-8',
      'Accept'       => 'application/json',
    ],
  );

  if ($logout_res->code == 204) {
    $self->_access_token(undef);

    return JMAP::Tester::Result::Logout->new({
      http_response => $logout_res,
    });
  }

  return JMAP::Tester::Result::Failure->new({
    ident => "failed to log out",
    http_response => $logout_res,
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester - a JMAP client made for testing JMAP servers

=head1 VERSION

version 0.017

=head1 OVERVIEW

B<Achtung!>  This library is in its really early days, so use it with that in
mind.

JMAP::Tester is for testing JMAP servers.  Okay?  Okay!

JMAP::Tester calls the whole thing you get back from a JMAP server a "response"
if it's an HTTP 200.  Every JSON Array (of three entries -- go read the spec if
you need to!) is called a L<Sentence|JMAP::Tester::Response::Sentence>.  Runs
of Sentences with the same client id are called
L<Paragraphs|JMAP::Tester::Response::Paragraph>.

You use the test client like this:

  my $jtest = JMAP::Tester->new({
    api_uri => 'https://jmap.local/account/123',
  });

  my $response = $jtest->request([
    [ getMailboxes => {} ],
    [ getMessageUpdates => { sinceState => "123" } ],
  ]);

  # This returns two Paragraph objects if there are exactly two paragraphs.
  # Otherwise, it throws an exception.
  my ($mbx_p, $msg_p) = $response->assert_n_paragraphs(2);

  # These get the single Sentence of each paragraph, asserting that there is
  # exactly one Sentence in each Paragraph, and that it's of the given type.
  my $mbx = $mbx_p->single('mailboxes');
  my $msg = $msg_p->single('messageUpdates');

  is( @{ $mbx->arguments->{list} }, 10, "we expect 10 mailboxes");
  ok( ! $msg->arguments->{hasMoreUpdates}, "we got all the msg updates needed");

By default, all the structures returned have been passed through
L<JSON::Typist>, so you may want to strip their type data before using normal
Perl code on them.  You can do that with:

  my $struct = $response->as_triples;  # gets the complete JSON data
  $jtest->strip_json_types( $struct ); # strips all the JSON::Typist types

Or more simply:

  my $struct = $response->as_stripped_triples;

There is also L<JMAP::Tester::Response/"as_stripped_pairs">.

=head1 ATTRIBUTES

=head2 default_arguments

This is a hashref of arguments to be put into each method call.  It's
especially useful for setting a default C<accountId>.  Values given in methods
passed to C<request> will override defaults.  If the value is a reference to
C<undef>, then no value will be passed for that key.

In other words, in this situation:

  my $tester = JMAP::Tester->new({
    ...,
    default_arguments => { a => 1, b => 2, c => 3 },
  });

  $tester->request([
    [ eatPies => { a => 100, b => \undef } ],
  ]);

The request will effectively be:

  [ [ "eatPies", { "a": 100, "c": 3 }, "a" ] ]

=head1 METHODS

=head2 request

  my $result = $jtest->request([
    [ methodOne => { ... } ],
    [ methodTwo => { ... } ],
  ]);

This method accepts either an arrayref of method calls or a hashref with a
C<methodCalls> key.  It sends the calls to the JMAP server and returns a
result.

For each method call, if there's a third element (a I<client id>) then it's
left as-is.  If no client id is given, one is generated.  You can mix explicit
and autogenerated client ids.  They will never conflict.

The arguments to methods are JSON-encoded with a L<JSON::Typist>-aware encoder,
so JSON::Typist types can be used to ensure string or number types in the
generated JSON.  If an argument is a reference to C<undef>, it will be removed
before the method call is made.  This lets you override a default by omission.

The return value is an object that does the L<JMAP::Tester::Result> role,
meaning it's got an C<is_success> method that returns true or false.  For now,
at least, failures are L<JMAP::Tester::Result::Failure> objects.  More refined
failure objects may exist in the future.  Successful requests return
L<JMAP::Tester::Response> objects.

=head2 upload

  my $result = $tester->upload($mime_type, $blob_ref, \%arg);

This uploads the given blob, which should be given as a reference to a string.

The return value will either be a L<failure
object|JMAP::Tester::Result::Failure> or an L<upload
result|JMAP::Tester::Result::Upload>.

=head2 download

  my $result = $tester->download(\%arg);

Valid arguments are:

  blobId    - the blob to download (no default)
  accountId - the account for which we're downloading (no default)
  name      - the name we want the server to provide back (default: "download")

If the download URI template has a C<blobId> or C<accountId> placeholder but no
argument for that is given to C<download>, an exception will be thrown.

The return value will either be a L<failure
object|JMAP::Tester::Result::Failure> or an L<upload
result|JMAP::Tester::Result::Download>.

=head2 simple_auth

  my $auth_struct = $tester->simple_auth($username, $password);

=head2 update_client_session

  $tester->update_client_session;
  $tester->update_client_session($auth_uri);

This method fetches the content at the authentication endpoint and uses it to
configure the tester's target URIs and signing keys.

=head2 configure_from_client_session

  $tester->configure_from_client_session($client_session);

Given a client session object (like those stored in an Auth result), this
reconfigures the testers access token, signing keys, URIs, and so forth.  This
method is used internally when logging in.

=head2 logout

  $tester->logout;

This method attempts to log out from the server by sending a C<DELETE> request
to the authentication URI.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Alfie John Matthew Horsfall

=over 4

=item *

Alfie John <alfiej@fastmail.fm>

=item *

Matthew Horsfall <wolfsage@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
