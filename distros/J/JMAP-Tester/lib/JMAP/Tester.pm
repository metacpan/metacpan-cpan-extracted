use v5.14.0;
use warnings;

package JMAP::Tester 0.104;
# ABSTRACT: a JMAP client made for testing JMAP servers

use Moo;

use Crypt::Misc qw(decode_b64u encode_b64u);
use Crypt::Mac::HMAC qw(hmac_b64u);
use Encode qw(encode_utf8);
use Future;
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
use Safe::Isa;
use URI;
use URI::QueryParam;
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

#pod =attr should_return_futures
#pod
#pod If true, this indicates that the various network-accessing methods should
#pod return L<Future> objects rather than immediate results.
#pod
#pod =cut

has should_return_futures => (
  is  => 'ro',
  default => 0,
);

# When something doesn't work — not an individual method call, but the whole
# HTTP call, somehow — then the future will fail, and the failure might be a
# JMAP tester failure object, meaning we semi-expected it, or it might be some
# other crazy failure, meaning we had no way of seeing it coming.
#
# We use Future->fail because that way we can use ->else in chains to only act
# on successful HTTP calls. At the end, it's fine if you're expecting a future
# and can know that a failed future is a fail and a done future is okay. In the
# old calling convention, though, you expect to get a success/fail object as
# long as you got an HTTP response.  Otherwise, you'd get an exception.
#
# $Failsafe emulates that. Just before we return from a future-returning
# method, and if the client is not set to return futures, we do this:
#
# * successful futures return their payload, the Result object
# * failed futures that contain a JMAP tester Failure return the failure
# * other failed futures die, like they would if you called $failed_future->get
my $Failsafe = sub {
  $_[0]->else_with_f(sub {
    my ($f, $fail) = @_;
    return $fail->$_isa('JMAP::Tester::Result::Failure') ? Future->done($fail)
                                                         : $f;
  });
};

has json_codec => (
  is => 'bare',
  handles => {
    json_encode => 'encode',
    json_decode => 'decode',
  },
  default => sub {
    require JSON;
    return JSON->new->utf8->convert_blessed;
  },
);

#pod =attr use_json_typists
#pod
#pod This attribute governs the conversion of JSON data into typed objects, using
#pod L<JSON::Typist>.  This attribute is true by default.
#pod
#pod =cut

has use_json_typist => (
  is => 'ro',
  default => 1,
);

has _json_typist => (
  is => 'ro',
  handles => {
    strip_json_types => 'strip_types',
  },
  default => sub {
    require JSON::Typist;
    return JSON::Typist->new;
  },
);

sub apply_json_types {
  my ($self, $data) = @_;

  return $data unless $self->use_json_typist;
  return $self->_json_typist->apply_types($data);
}

for my $type (qw(api authentication download upload)) {
  has "$type\_uri" => (
    is => 'rw',
    predicate => "has_$type\_uri",
    clearer   => "clear_$type\_uri",
  );
}

has ua => (
  is => 'ro',
  default => sub {
    require JMAP::Tester::UA::LWP;
    JMAP::Tester::UA::LWP->new;
  },
);

#pod =attr default_using
#pod
#pod This is an arrayref of strings that specify which capabilities the client
#pod wishes to use. (See L<https://jmap.io/spec-core.html#the-request-object>
#pod for more info). By default, JMAP::Tester will not send a 'using' parameter.
#pod
#pod =cut

has default_using => (
  is => 'rw',
  predicate => '_has_default_using',
);

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

#pod =attr accounts
#pod
#pod This method will return a list of pairs mapping accountIds to accounts
#pod as provided by the client session object if any have been configured.
#pod
#pod =cut

has _accounts => (
  is        => 'rw',
  init_arg  => undef,
  predicate => '_has_accounts',
);

sub accounts {
  return unless $_[0]->_has_accounts;
  return %{ $_[0]->_accounts }
}

#pod =method primary_account_for
#pod
#pod   my $account_id = $tester->primary_account_for($using);
#pod
#pod This returns the primary accountId to be used for the given capability, or
#pod undef if none is available.  This is only useful if the tester has been
#pod configured from a client session.
#pod
#pod =cut

has _primary_accounts => (
  is        => 'rw',
  init_arg  => undef,
  predicate => '_has_primary_accounts',
);

sub primary_account_for {
  my ($self, $using) = @_;
  return unless $self->_has_primary_accounts;
  return $self->_primary_accounts->{ $using };
}

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
#pod Before the JMAP request is made, each triple is passed to a method called
#pod C<munge_method_triple>, which can tweak the method however it likes.
#pod
#pod This method respects the C<should_return_futures> attributes of the
#pod JMAP::Tester object, and in futures mode will return a future that will resolve
#pod to the Result.
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

    # Originally, I had a second argument, \%stash, which was the same for the
    # whole ->request, so you could store data between munges.  Removed, for
    # now, as YAGNI. -- rjbs, 2019-03-04
    $self->munge_method_triple($copy);

    push @suffixed, $copy;
  }

  $request->{methodCalls} = \@suffixed;

  $request = $request->{methodCalls}
    if $ENV{JMAP_TESTER_NO_WRAPPER} && _ARRAY0($input_request);

  if ($self->_has_default_using && ! exists $request->{using}) {
    $request->{using} = $self->default_using;
  }

  my $json = $self->json_encode($request);

  my $post = HTTP::Request->new(
    POST => $self->api_uri,
    [
      'Content-Type' => 'application/json',
      $self->_maybe_auth_header,
    ],
    $json,
  );

  my $res_f = $self->ua->request($self, $post, jmap => {
    jmap_array   => \@suffixed,
    json         => $json,
  });

  my $future = $res_f->then(sub {
    my ($res) = @_;

    unless ($res->is_success) {
      $self->_logger->log_jmap_response({ http_response => $res });
      return Future->fail(
        JMAP::Tester::Result::Failure->new({ http_response => $res })
      );
    }

    return Future->done($self->_jresponse_from_hresponse($res));
  });

  return $self->should_return_futures ? $future : $future->$Failsafe->get;
}

sub munge_method_triple {}

sub response_class { 'JMAP::Tester::Response' }

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

  return $self->response_class->new({
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
#pod   my $result = $tester->upload(\%arg);
#pod
#pod Required arguments are:
#pod
#pod   accountId - the account for which we're uploading (no default)
#pod   type      - the content-type we want to provide to the server
#pod   blob      - the data to upload. Must be a reference to a string
#pod
#pod This uploads the given blob.
#pod
#pod The return value will either be a L<failure
#pod object|JMAP::Tester::Result::Failure> or an L<upload
#pod result|JMAP::Tester::Result::Upload>.
#pod
#pod This method respects the C<should_return_futures> attributes of the
#pod JMAP::Tester object, and in futures mode will return a future that will resolve
#pod to the Result.
#pod
#pod =cut

sub upload {
  my ($self, $arg) = @_;
  # TODO: support blob as handle or sub -- rjbs, 2016-11-17

  my $uri = $self->upload_uri;

  Carp::confess("can't upload without upload_uri")
    unless $uri;

  for my $param (qw(accountId type blob)) {
    my $value = $arg->{ $param };

    Carp::confess("missing required parameter $param")
      unless defined $value;

    if ($param eq 'accountId') {
      $uri =~ s/\{$param\}/$value/g;
    }
  }

  my $post = HTTP::Request->new(
    POST => $uri,
    [
      'Content-Type' => $arg->{type},
      $self->_maybe_auth_header,
    ],
    ${ $arg->{blob} },
  );

  my $res_f = $self->ua->request($self, $post, 'upload');

  my $future = $res_f->then(sub {
    my ($res) = @_;

    unless ($res->is_success) {
      $self->_logger->log_upload_response({ http_response => $res });
      return Future->fail(
        JMAP::Tester::Result::Failure->new({ http_response => $res })
      );
    }

    my $json = $res->decoded_content;
    my $blob = $self->apply_json_types( $self->json_decode( $json ) );

    $self->_logger->log_upload_response({
      json          => $json,
      blob_struct   => $blob,
      http_response => $res,
    });

    return Future->done(
      JMAP::Tester::Result::Upload->new({
        http_response => $res,
        payload       => $blob,
      })
    );
  });

  return $self->should_return_futures ? $future : $future->$Failsafe->get;
}

#pod =method download
#pod
#pod   my $result = $tester->download(\%arg);
#pod
#pod Valid arguments are:
#pod
#pod   blobId    - the blob to download (no default)
#pod   accountId - the account for which we're downloading (no default)
#pod   type      - the content-type we want the server to provide back (no default)
#pod   name      - the name we want the server to provide back (default: "download")
#pod
#pod If the download URI template has a C<blobId>, C<accountId>, or C<type>
#pod placeholder but no argument for that is given to C<download>, an exception
#pod will be thrown.
#pod
#pod The return value will either be a L<failure
#pod object|JMAP::Tester::Result::Failure> or an L<upload
#pod result|JMAP::Tester::Result::Download>.
#pod
#pod This method respects the C<should_return_futures> attributes of the
#pod JMAP::Tester object, and in futures mode will return a future that will resolve
#pod to the Result.
#pod
#pod =cut

my %DL_DEFAULT = (name => 'download');

sub _jwt_sub_param_from_uri {
  my ($self, $to_sign) = @_;
  "$to_sign";
}

sub download_uri_for {
  my ($self, $arg) = @_;

  Carp::confess("can't compute download URI without configured download_uri")
    unless my $uri = $self->download_uri;

  for my $param (qw(blobId accountId name type)) {
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

    my $iat = time;
    $iat = $iat - ($iat % 3600);

    my $payload = encode_b64u( $self->json_encode({
      iss => $jwtc->{signingId},
      iat => $iat,
      sub => $self->_jwt_sub_param_from_uri($to_sign),
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
    [
      $self->_maybe_auth_header,
    ],
  );

  my $res_f = $self->ua->request($self, $get, 'download');

  my $future = $res_f->then(sub {
    my ($res) = @_;

    $self->_logger->log_download_response({
      http_response => $res,
    });

    unless ($res->is_success) {
      return Future->fail(
        JMAP::Tester::Result::Failure->new({ http_response => $res })
      );
    }

    return Future->done(
      JMAP::Tester::Result::Download->new({ http_response => $res })
    );
  });

  return $self->should_return_futures ? $future : $future->$Failsafe->get;
}

#pod =method simple_auth
#pod
#pod   my $auth_struct = $tester->simple_auth($username, $password);
#pod
#pod This method respects the C<should_return_futures> attributes of the
#pod JMAP::Tester object, and in futures mode will return a future that will resolve
#pod to the Result.
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

  my $start_req = HTTP::Request->new(
    POST => $self->authentication_uri,
    [
      'Content-Type' => 'application/json; charset=utf-8',
      'Accept'       => 'application/json',
    ],
    $start_json,
  );

  my $start_res_f = $self->ua->request($self, $start_req, 'auth');

  my $future = $start_res_f->then(sub {
    my ($res) = @_;

    unless ($res->code == 200) {
      return Future->fail(
        JMAP::Tester::Result::Failure->new({
          ident         => 'failure in auth phase 1',
          http_response => $res,
        })
      );
    }

    my $start_reply = $self->json_decode( $res->decoded_content );

    unless (grep {; $_->{type} eq 'password' } @{ $start_reply->{methods} }) {
      return Future->fail(
        JMAP::Tester::Result::Failure->new({
          ident         => "password is not an authentication method",
          http_response => $res,
        })
      );
    }

    my $next_json = $self->json_encode({
      loginId => $start_reply->{loginId},
      type    => 'password',
      value   => $password,
    });

    my $next_req = HTTP::Request->new(
      POST => $self->authentication_uri,
      [
        'Content-Type' => 'application/json; charset=utf-8',
        'Accept'       => 'application/json',
      ],
      $next_json,
    );

    return $self->ua->request($self, $next_req, 'auth');
  })->then(sub {
    my ($res) = @_;
    unless ($res->code == 201) {
      return Future->fail(
        JMAP::Tester::Result::Failure->new({
          ident         => 'failure in auth phase 2',
          http_response => $res,
        })
      );
    }

    my $client_session = $self->json_decode( $res->decoded_content );

    my $auth = JMAP::Tester::Result::Auth->new({
      http_response   => $res,
      client_session  => $client_session,
    });

    $self->configure_from_client_session($client_session);

    return Future->done($auth);
  });

  return $self->should_return_futures ? $future : $future->$Failsafe->get;
}

#pod =method update_client_session
#pod
#pod   $tester->update_client_session;
#pod   $tester->update_client_session($auth_uri);
#pod
#pod This method fetches the content at the authentication endpoint and uses it to
#pod configure the tester's target URIs and signing keys.
#pod
#pod This method respects the C<should_return_futures> attributes of the
#pod JMAP::Tester object, and in futures mode will return a future that will resolve
#pod to the Result.
#pod
#pod =cut

sub update_client_session {
  my ($self, $auth_uri) = @_;
  $auth_uri //= $self->authentication_uri;

  my $auth_req = HTTP::Request->new(
    GET => $auth_uri,
    [
      $self->_maybe_auth_header,
      'Accept' => 'application/json',
    ],
  );

  my $future = $self->ua->request($self, $auth_req, 'auth')->then(sub {
    my ($res) = @_;

    unless ($res->code == 200) {
      return Future->fail(
        JMAP::Tester::Result::Failure->new({
          ident         => 'failure to get updated authentication data',
          http_response => $res,
        })
      );
    }

    my $client_session = $self->json_decode( $res->decoded_content );

    my $auth = JMAP::Tester::Result::Auth->new({
      http_response   => $res,
      client_session  => $client_session,
    });

    $self->configure_from_client_session($client_session);

    return Future->done($auth);
  });

  return $self->should_return_futures ? $future : $future->$Failsafe->get;
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

  for my $type (qw(api download upload)) {
    if (defined (my $uri = $client_session->{"${type}Url"})) {
      my $setter = "$type\_uri";
      $self->$setter($uri);
    } else {
      my $clearer = "clear_$type\_uri";
      $self->$clearer;
    }
  }

  $self->_primary_accounts($client_session->{primaryAccounts});
  $self->_accounts($client_session->{accounts});

  return;
}

#pod =method logout
#pod
#pod   $tester->logout;
#pod
#pod This method attempts to log out from the server by sending a C<DELETE> request
#pod to the authentication URI.
#pod
#pod This method respects the C<should_return_futures> attributes of the
#pod JMAP::Tester object, and in futures mode will return a future that will resolve
#pod to the Result.
#pod
#pod =cut

sub logout {
  my ($self) = @_;

  # This is fatal, not a failure return, because it reflects the user screwing
  # up, not a possible JMAP-related condition. -- rjbs, 2017-02-10
  Carp::confess("can't logout: no authentication_uri configured")
    unless $self->has_authentication_uri;

  my $req = HTTP::Request->new(
    DELETE => $self->authentication_uri,
    [
      'Content-Type' => 'application/json; charset=utf-8',
      'Accept'       => 'application/json',
    ],
  );

  my $future = $self->ua->request($self, $req, 'auth')->then(sub {
    my ($res) = @_;

    if ($res->code == 204) {
      $self->_access_token(undef);

      return Future->done(
        JMAP::Tester::Result::Logout->new({
          http_response => $res,
        })
      );
    }

    return Future->fail(
      JMAP::Tester::Result::Failure->new({
        ident => "failed to log out",
        http_response => $res,
      })
    );
  });

  return $self->should_return_futures ? $future : $future->$Failsafe->get;
}

#pod =method http_request
#pod
#pod   my $response = $jtest->http_request($http_request);
#pod
#pod Sometimes, you may need to make an HTTP request with your existing web
#pod connection.  This might be to interact with a custom authentication mechanism,
#pod to access custom endpoints, or just to make very, very specifically crafted
#pod requests.  For this reasons, C<http_request> exists.
#pod
#pod Pass this method an L<HTTP::Request> and it will use the tester's UA object to
#pod make the request.
#pod
#pod This method respects the C<should_return_futures> attributes of the
#pod JMAP::Tester object, and in futures mode will return a future that will resolve
#pod to the L<HTTP::Response>.
#pod
#pod =cut

sub http_request {
  my ($self, $http_request) = @_;

  my $future = $self->ua->request($self, $http_request, 'misc');
  return $self->should_return_futures ? $future : $future->$Failsafe->get;
}

#pod =method http_get
#pod
#pod   my $response = $jtest->http_get($url, $headers);
#pod
#pod This method is just sugar for calling C<http_request> to make a GET request for
#pod the given URL.  C<$headers> is an optional arrayref of headers.
#pod
#pod =cut

sub http_get {
  my ($self, $url, $headers) = @_;

  my $req = HTTP::Request->new(
    GET => $url,
    (defined $headers ? $headers : ()),
  );
  return $self->http_request($req);
}

#pod =method http_post
#pod
#pod   my $response = $jtest->http_post($url, $body, $headers);
#pod
#pod This method is just sugar for calling C<http_request> to make a POST request
#pod for the given URL.  C<$headers> is an arrayref of headers and C<$body> is the
#pod byte string to be passed as the body.
#pod
#pod =cut

sub http_post {
  my ($self, $url, $body, $headers) = @_;

  my $req = HTTP::Request->new(
    POST => $url,
    $headers // [],
    $body,
  );

  return $self->http_request($req);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester - a JMAP client made for testing JMAP servers

=head1 VERSION

version 0.104

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

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 ATTRIBUTES

=head2 should_return_futures

If true, this indicates that the various network-accessing methods should
return L<Future> objects rather than immediate results.

=head2 use_json_typists

This attribute governs the conversion of JSON data into typed objects, using
L<JSON::Typist>.  This attribute is true by default.

=head2 default_using

This is an arrayref of strings that specify which capabilities the client
wishes to use. (See L<https://jmap.io/spec-core.html#the-request-object>
for more info). By default, JMAP::Tester will not send a 'using' parameter.

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

=head2 accounts

This method will return a list of pairs mapping accountIds to accounts
as provided by the client session object if any have been configured.

=head1 METHODS

=head2 primary_account_for

  my $account_id = $tester->primary_account_for($using);

This returns the primary accountId to be used for the given capability, or
undef if none is available.  This is only useful if the tester has been
configured from a client session.

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

Before the JMAP request is made, each triple is passed to a method called
C<munge_method_triple>, which can tweak the method however it likes.

This method respects the C<should_return_futures> attributes of the
JMAP::Tester object, and in futures mode will return a future that will resolve
to the Result.

=head2 upload

  my $result = $tester->upload(\%arg);

Required arguments are:

  accountId - the account for which we're uploading (no default)
  type      - the content-type we want to provide to the server
  blob      - the data to upload. Must be a reference to a string

This uploads the given blob.

The return value will either be a L<failure
object|JMAP::Tester::Result::Failure> or an L<upload
result|JMAP::Tester::Result::Upload>.

This method respects the C<should_return_futures> attributes of the
JMAP::Tester object, and in futures mode will return a future that will resolve
to the Result.

=head2 download

  my $result = $tester->download(\%arg);

Valid arguments are:

  blobId    - the blob to download (no default)
  accountId - the account for which we're downloading (no default)
  type      - the content-type we want the server to provide back (no default)
  name      - the name we want the server to provide back (default: "download")

If the download URI template has a C<blobId>, C<accountId>, or C<type>
placeholder but no argument for that is given to C<download>, an exception
will be thrown.

The return value will either be a L<failure
object|JMAP::Tester::Result::Failure> or an L<upload
result|JMAP::Tester::Result::Download>.

This method respects the C<should_return_futures> attributes of the
JMAP::Tester object, and in futures mode will return a future that will resolve
to the Result.

=head2 simple_auth

  my $auth_struct = $tester->simple_auth($username, $password);

This method respects the C<should_return_futures> attributes of the
JMAP::Tester object, and in futures mode will return a future that will resolve
to the Result.

=head2 update_client_session

  $tester->update_client_session;
  $tester->update_client_session($auth_uri);

This method fetches the content at the authentication endpoint and uses it to
configure the tester's target URIs and signing keys.

This method respects the C<should_return_futures> attributes of the
JMAP::Tester object, and in futures mode will return a future that will resolve
to the Result.

=head2 configure_from_client_session

  $tester->configure_from_client_session($client_session);

Given a client session object (like those stored in an Auth result), this
reconfigures the testers access token, signing keys, URIs, and so forth.  This
method is used internally when logging in.

=head2 logout

  $tester->logout;

This method attempts to log out from the server by sending a C<DELETE> request
to the authentication URI.

This method respects the C<should_return_futures> attributes of the
JMAP::Tester object, and in futures mode will return a future that will resolve
to the Result.

=head2 http_request

  my $response = $jtest->http_request($http_request);

Sometimes, you may need to make an HTTP request with your existing web
connection.  This might be to interact with a custom authentication mechanism,
to access custom endpoints, or just to make very, very specifically crafted
requests.  For this reasons, C<http_request> exists.

Pass this method an L<HTTP::Request> and it will use the tester's UA object to
make the request.

This method respects the C<should_return_futures> attributes of the
JMAP::Tester object, and in futures mode will return a future that will resolve
to the L<HTTP::Response>.

=head2 http_get

  my $response = $jtest->http_get($url, $headers);

This method is just sugar for calling C<http_request> to make a GET request for
the given URL.  C<$headers> is an optional arrayref of headers.

=head2 http_post

  my $response = $jtest->http_post($url, $body, $headers);

This method is just sugar for calling C<http_request> to make a POST request
for the given URL.  C<$headers> is an arrayref of headers and C<$body> is the
byte string to be passed as the body.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Alfie John Matthew Horsfall Michael McClimon Ricardo Signes

=over 4

=item *

Alfie John <alfiej@fastmail.fm>

=item *

Matthew Horsfall <wolfsage@gmail.com>

=item *

Michael McClimon <michael@mcclimon.org>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
