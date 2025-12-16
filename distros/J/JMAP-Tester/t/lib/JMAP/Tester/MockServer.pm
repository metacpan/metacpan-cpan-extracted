package JMAP::Tester::MockServer;

use v5.20.0;
use warnings;

use experimental 'signatures';

use JSON::Typist 0.005; # $typist->number
use JSON::XS;

use LWP::Protocol::PSGI;
use Plack::Request;

my $SESSION = {
  apiUrl         => "http://localhost:5627/jmap/api/",
  downloadUrl    => "http://localhost:5627/jmap/download/{accountId}/{blobId}/{name}?type={type}",
  eventSourceUrl => "http://localhost:5627/jmap/event/",
  uploadUrl      => "http://localhost:5627/jmap/upload/{accountId}/",

  accounts => {
    ac1234 => {
      accountCapabilities => {
        "urn:ietf:params:jmap:calendars" => {},
        "urn:ietf:params:jmap:contacts" => {},
        "urn:ietf:params:jmap:core" => {},
        "urn:ietf:params:jmap:mail" => {
          emailQuerySortOptions => [
            qw( receivedAt from to subject size header.x-spam-score )
          ],
          maxMailboxDepth => undef,
          maxMailboxesPerEmail => 1000,
          maxSizeAttachmentsPerEmail => 50000000,
          maxSizeMailboxName => 490,
          mayCreateTopLevelMailbox => undef,
        },
        "urn:ietf:params:jmap:submission" => {
          maxDelayedSend => 44236800,
          submissionExtensions => {}
        },
        "urn:ietf:params:jmap:vacationresponse" => {}
      },
      isPersonal => \1,
      isReadOnly => \0,
      name => 'tester@example.com',
    },
  },
  capabilities => {
    "urn:ietf:params:jmap:calendars" => {},
    "urn:ietf:params:jmap:contacts" => {},
    "urn:ietf:params:jmap:core" => {
      collationAlgorithms   => [ "i;ascii-numeric", "i;ascii-casemap", "i;octet" ],
      maxCallsInRequest     => 50,
      maxConcurrentRequests => 10,
      maxConcurrentUpload   => 10,
      maxObjectsInGet       => 4096,
      maxObjectsInSet       => 4096,
      maxSizeRequest        => 10000000,
      maxSizeUpload         => 250000000
    },
    "urn:ietf:params:jmap:mail" => {},
    "urn:ietf:params:jmap:submission" => {},
    "urn:ietf:params:jmap:vacationresponse" => {}
  },
  primaryAccounts => {
    "urn:ietf:params:jmap:calendars"        => "ac1234",
    "urn:ietf:params:jmap:contacts"         => "ac1234",
    "urn:ietf:params:jmap:core"             => "ac1234",
    "urn:ietf:params:jmap:mail"             => "ac1234",
    "urn:ietf:params:jmap:submission"       => "ac1234",
    "urn:ietf:params:jmap:vacationresponse" => "ac1234"
  },
  state => "Pennsylvania",
  username => 'tester@example.com'
};

sub authentication_uri { "http://localhost:5627/jmap/session/" }

sub _error ($code, $data={}) {
  return [
    $code,
    [ 'Content-Type' => 'application/json' ],
    [ JSON::XS->new->encode($data) ],
  ];
}

sub _psgi_app ($env) {
  my $req   = Plack::Request->new($env);

  my $path  = $req->path_info;

  return  index($path, '/jmap/session/')  == 0 ? _handle_session_req($req)
        : index($path, '/jmap/api/')      == 0 ? _handle_api_req($req)
        : index($path, '/jmap/download/') == 0 ? _handle_download_req($req)
        : index($path, '/jmap/upload/')   == 0 ? _handle_upload_req($req)
        :                                        _error(404);
}

sub _handle_download_req ($req) {
  my (undef, undef, undef, $accountid, $blob_id, $name) = split m{/}, $req->path_info;
  return [
    200,
    [
      'Content-Type' => $req->parameters->{type},
      'Content-Disposition' => qq{attachment; filename="$name"},
    ],
    [ "The blob you requested was $blob_id for $accountid." ],
  ];
}

sub _handle_upload_req ($req) {
  my (undef, undef, undef, $account_id) = split m{/}, $req->path_info;

  my $content = $req->raw_body;
  my $length  = length $content;
  my $blob_id = substr($content, 0, 1) . q{-} . $length; # Whatever.

  my $result = {
    accountId => $account_id,
    blobId    => $blob_id,
    type      => scalar $req->header('Content-Type'),
    size      => $length,
  };

  return [
    200,
    [ 'Content-Type' => 'application/json' ],
    [ JSON::XS->new->encode($result) ]
  ];
}

sub _handle_session_req ($req) {
  return _error(400) unless $req->method eq 'GET';

  return [
    200,
    [ 'Content-Type' => 'application/json' ],
    [ JSON::XS->new->encode($SESSION) ]
  ];
}

sub _handle_api_req ($req) {
  return _error(400) unless $req->method eq 'POST';

  my $body  = $req->raw_body;
  my $data  = JSON::XS->new->decode($body);

  return [
    200,
    [
      'Content-Type' => 'application/json; charset=utf-8',
      'Mock-Server'  => 'gorp/1.23',
    ],
    [
      JSON::XS->new->encode({
        methodResponses => [
          [ 'Fake/one', { f => 1 }, 'a' ],
          [ 'Fake/echo', { echo => $data }, 'c' ],
        ],
      }),
    ]
  ];
}

sub register_handler {
  LWP::Protocol::PSGI->register(\&_psgi_app, host => 'localhost:5627');
}

1;
