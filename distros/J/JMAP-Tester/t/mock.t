use strict;
use warnings;

use JMAP::Tester;
use JMAP::Tester::UA::Test;
use JMAP::Tester::Sugar qw(json_literal);
use JSON::Typist 0.005; # $typist->number

use HTTP::Response;
use Test::Deep ':v1';
use Test::Deep::JType 0.005; # jstr() in both want and have
use Test::More;
use Test::Abortable 'subtest';

my $tester = JMAP::Tester->new({
  api_uri => 'http://localhost/jmap',
  ua => JMAP::Tester::UA::Test->new({
    request_handler => sub {
      my ($self, $tester, $req, $log_type, $log_extra) = @_;

      unless ($log_type eq 'jmap') {
        Carp::confess('tester only handle "jmap"-type requests');
      }

      my $data = $tester->json_decode(
        $req->decoded_content(charset => undef),
      );

      HTTP::Response->new(
        200,
        "OK",
        [ 'Content-Type' => 'application/json; charset=utf-8' ],
        $tester->json_encode({
          methodResponses => [
            [ 'Fake/one', { f => 1 }, 'a' ],
            [ 'Fake/echo', { echo => $data }, 'c' ],
          ],
        }),
      );
    }
  }),
});

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

done_testing;
