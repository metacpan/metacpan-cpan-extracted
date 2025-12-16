use v5.20.0;
use warnings;

use experimental 'signatures';

use JMAP::Tester;
use JMAP::Tester::Sugar qw(json_literal);
use JSON::Typist 0.005; # $typist->number

use LWP::Protocol::PSGI;
use Test::Deep ':v1';
use Test::Deep::JType 0.005; # jstr() in both want and have
use Test::More;
use Test::Abortable 'subtest';

use lib 't/lib';
use JMAP::Tester::MockServer;

JMAP::Tester::MockServer->register_handler;

my $tester = JMAP::Tester->new({
  authentication_uri => JMAP::Tester::MockServer->authentication_uri,
});

subtest "getting the session" => sub {
  my $auth = $tester->update_client_session;
  isa_ok($auth, 'JMAP::Tester::Result::Auth');
  ok($auth->is_success, "successful auth is successful");

  jcmp_deeply(
    $auth->client_session,
    superhashof({
      accounts => { ac1234 => superhashof({}) },
      username => 'tester@example.com',
    }),
    "we got the session",
  );

  jcmp_deeply(
    { $tester->accounts },
    { ac1234 => superhashof({}) },
    "the tester, now configured, has accounts",
  );

  jcmp_deeply(
    $tester->primary_account_for("urn:ietf:params:jmap:mail"),
    'ac1234',
    "primary account for mail is correct",
  );

  jcmp_deeply(
    $tester->primary_account_for("urn:ietf:params:jmap:gopher"),
    undef,
    "we get under for types w/o primary accounts",
  );

  my $auth_reget = $tester->get_client_session;
  jcmp_deeply(
    $auth_reget->client_session,
    $auth->client_session,
    "regotten session is the same as the original",
  );

  my $auth_failure = $tester->get_client_session($tester->api_uri);
  ok(!$auth_failure->is_success, "failed auth get is not successful");
};

my @cases = (
  [ "from Perl struct"  => [[ 'Shine/get', { clean => 1 } ]] ],
  [ "from JSON literal" => json_literal(q!
      { "methodCalls": [["Shine/get",   {"clean":1}, "a"]   ]}
    !)
  ]
);

for my $case (@cases) {
  my ($desc, $input) = @$case;
  subtest $desc => sub {
    my $res = $tester->request($input);

    jcmp_deeply($res->sentence(0)->name, "Fake/one", "first name correct");
    jcmp_deeply($res->sentence(0)->arguments, { f => 1 }, "first args correct");

    jcmp_deeply($res->sentence(1)->name, "Fake/echo", "second name correct");
    jcmp_deeply(
      $res->sentence(1)->arguments->{echo},
      superhashof({ methodCalls => [[ 'Shine/get', { clean => 1 }, jstr() ]] }),
      "second args correct",
    );

    like(
      $res->response_payload,
      qr{^Mock-Server: gorp/1\.23$}m,
      "http req stringifies in response"
    );
  };
}

subtest "bogus use of json_literal" => sub {
  my $res = $tester->request([
    [ 'Bogus/call', { arg => json_literal("This will not appear") } ],
  ]);

  my $echoed_args = $res->sentence_named('Fake/echo')->arguments;
  like($echoed_args->{echo}{methodCalls}[0][1]{arg}, qr/ERROR/, "error report in response");
  unlike($echoed_args->{echo}{methodCalls}[0][1]{arg}, qr/not appear/, "we lost requested literal");
};

subtest "downloading blobs" => sub {
  my $download = $tester->download({
    accountId => $tester->primary_account_for("urn:ietf:params:jmap:mail"),
    blobId    => "xyzzy",
    type      => 'text/subtext',
    name      => "download.sbt",
  });

  isa_ok($download, 'JMAP::Tester::Result::Download');

  is(
    $download->bytes_ref->$*,
    "The blob you requested was xyzzy for ac1234.",
    "blob download content as expected",
  );
};

subtest "uploading blobs" => sub {
  my $upload = $tester->upload({
    accountId => $tester->primary_account_for("urn:ietf:params:jmap:mail"),
    blob      => \"This is an upload.", # 18 bytes
    type      => 'text/plane',
  });

  isa_ok($upload, 'JMAP::Tester::Result::Upload');
  ok($upload->is_success, "successful upload is successful");

  is($upload->blobId,  "T-18",        "got the blob id we expect (blobId)");
  is($upload->blob_id, "T-18",        "got the blob id we expect (blob_id)");
  is($upload->type,    "text/plane",  "got the type we expect");
  is($upload->size,    18,            "got the size we expect");
};

done_testing;
