use strict;
use warnings;
use Test2::V0;

# k14: the provider manifest needs Langertha::Manifest::Builder, which the
# released core may lack (the cpanfile does not require it). Knarr must keep
# working and answer /.well-known/langertha.json with a clean JSON 404 rather
# than crash or serve half a manifest. With a core that has the Builder, it is
# hidden here, so this test runs against either core.

BEGIN {
  unshift @INC, sub {
    my ( undef, $file ) = @_;
    die "Can't locate $file (hidden by t/66_manifest_absent.t)\n"
      if $file eq 'Langertha/Manifest/Builder.pm';
    return;
  };
}

use IO::Async::Loop;
use Net::Async::HTTP;
use HTTP::Request;
use JSON::MaybeXS;
use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;

my $json = JSON::MaybeXS->new( utf8 => 1 );
my $loop = IO::Async::Loop->new;

my $knarr = Langertha::Knarr->new(
  handler => Langertha::Knarr::Handler::Code->new( code => sub { 'still-chatting' } ),
  loop    => $loop,
  port    => 0,
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $http = Net::Async::HTTP->new;
$loop->add($http);

{
  my $resp = $http->do_request( request =>
    HTTP::Request->new( GET => "http://127.0.0.1:$port/.well-known/langertha.json" ) )->get;
  is $resp->code, 404, 'native: 404 without the core Builder';
  like scalar $resp->header('Content-Type'), qr{application/json}, 'native: JSON';
  like $json->decode( $resp->decoded_content )->{error}{message}, qr/Langertha::Manifest::Builder/,
    'native: the error says what is missing';
}

{
  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions" );
  $req->header( 'Content-Type' => 'application/json' );
  $req->content( $json->encode({ model => 'm', messages => [ { role => 'user', content => 'hi' } ] }) );
  my $resp = $http->do_request( request => $req )->get;
  is $json->decode( $resp->decoded_content )->{choices}[0]{message}{content}, 'still-chatting',
    'chat is unaffected';
}

SKIP: {
  skip 'Plack::Test not installed', 3
    unless eval { require Plack::Test; require HTTP::Request::Common; 1 };
  require Langertha::Knarr::PSGI;
  my $test = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );
  my $resp = $test->request( HTTP::Request::Common::GET('/.well-known/langertha.json') );
  is $resp->code, 404, 'PSGI: 404 without the core Builder';
  like scalar $resp->header('Content-Type'), qr{application/json}, 'PSGI: JSON';
  like $json->decode( $resp->decoded_content )->{error}{message}, qr/Langertha::Manifest::Builder/,
    'PSGI: the error says what is missing';
}

done_testing;
