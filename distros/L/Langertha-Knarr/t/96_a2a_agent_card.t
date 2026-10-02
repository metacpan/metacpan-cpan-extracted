use strict;
use warnings;
use Test2::V0;

# The A2A agent card at GET /.well-known/agent.json answered publicly with
# the old project name ("Langertha Steerboard Agent"), and nothing in the
# config could change it: Knarr built its protocols with a bare ->new.
# The default is now "Langertha Knarr Agent", and a2a.name /
# a2a.description (or KNARR_A2A_NAME / KNARR_A2A_DESCRIPTION) reach the
# card through Config->protocol_args -> Knarr protocol_args ->
# Protocol::A2A, on the native server and under PSGI alike. The card's
# version was a hardcoded 0.0.1; it is Knarr's own version now.

BEGIN {
  eval { require Plack::Test; 1 }
    or plan skip_all => 'Plack::Test required for this test';
}
use Plack::Test;
use HTTP::Request;
use IO::Async::Loop;
use Net::Async::HTTP;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Config;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::PSGI;
use Langertha::Knarr::Protocol::A2A;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;
my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);
my $handler = Langertha::Knarr::Handler::Code->new( code => sub { 'x' } );

sub cards {
  my (%args) = @_;
  my $knarr = Langertha::Knarr->new( handler => $handler, loop => $loop,
    listen => ['127.0.0.1:0'], %args );
  $knarr->start;
  my $port = $knarr->_server->read_handle->sockport;
  my $native = $http->do_request( request =>
    HTTP::Request->new( GET => "http://127.0.0.1:$port/.well-known/agent.json" ) )->get;
  my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app )
    ->request( HTTP::Request->new( GET => 'http://localhost/.well-known/agent.json' ) );
  my %card;
  for ( [ native => $native ], [ psgi => $psgi ] ) {
    my ($t, $res) = @$_;
    is( $res->code, 200, "$t: agent card answers 200" );
    $card{$t} = $json->decode( $res->decoded_content );
  }
  return %card;
}

{
  ok( defined $Langertha::Knarr::VERSION, 'Langertha::Knarr has a version' );
  my %card = cards();
  for my $t (qw( native psgi )) {
    is( $card{$t}{name}, 'Langertha Knarr Agent', "$t: default name" );
    is( $card{$t}{description}, 'LLM agent served through Langertha Knarr', "$t: default description" );
    unlike( $json->encode( $card{$t} ), qr/steerboard/i, "$t: no old project name in the card" );
    ok( $card{$t}{capabilities}{streaming}, "$t: still advertises streaming" );
    is( $card{$t}{version}, $Langertha::Knarr::VERSION, "$t: card carries Knarr's own version" );
    isnt( $card{$t}{version}, '0.0.1', "$t: not the old hardcoded version" );
  }
}

{
  my %card = cards( protocol_args => { A2A => {
    agent_name => 'Support Agent', agent_description => 'Answers support questions' } } );
  for my $t (qw( native psgi )) {
    is( $card{$t}{name}, 'Support Agent', "$t: configured name" );
    is( $card{$t}{description}, 'Answers support questions', "$t: configured description" );
  }
}

{
  my %card = cards( protocol_args => { A2A => { agent_name => 'Only Named' } } );
  is( $card{$_}{name}, 'Only Named', "$_: name alone" ) for qw( native psgi );
  is( $card{$_}{description}, 'LLM agent served through Langertha Knarr',
    "$_: description keeps its default" ) for qw( native psgi );
}

# A Langertha::Knarr without a $VERSION (a tree the version rewrite never
# touched) still yields a card with a version string.
{
  local $Langertha::Knarr::VERSION = undef;
  is( Langertha::Knarr::Protocol::A2A->new->agent_card->{version}, 'dev',
    'no Knarr version: card says dev' );
}

# Config: a2a.name / a2a.description, env fallback, config wins, and
# protocol_args carries only what is set.
{
  delete local $ENV{KNARR_A2A_NAME};
  delete local $ENV{KNARR_A2A_DESCRIPTION};

  my $empty = Langertha::Knarr::Config->new( data => {} );
  is( $empty->a2a_name, undef, 'no a2a.name: unset' );
  is( $empty->a2a_description, undef, 'no a2a.description: unset' );
  is( $empty->protocol_args, { A2A => {} }, 'protocol_args empty for A2A when nothing is set' );

  my $config = Langertha::Knarr::Config->new( data => {
    a2a => { name => 'Cfg Agent', description => 'From the config file' } } );
  is( $config->a2a_name, 'Cfg Agent', 'Config reads a2a.name' );
  is( $config->a2a_description, 'From the config file', 'Config reads a2a.description' );
  is( $config->protocol_args,
    { A2A => { agent_name => 'Cfg Agent', agent_description => 'From the config file' } },
    'protocol_args maps them onto Protocol::A2A' );

  my %card = cards( protocol_args => $config->protocol_args );
  is( [ @{ $card{$_} }{qw( name description )} ], [ 'Cfg Agent', 'From the config file' ],
    "$_: config reaches the card" ) for qw( native psgi );

  local $ENV{KNARR_A2A_NAME} = '"Env Agent"';
  local $ENV{KNARR_A2A_DESCRIPTION} = 'From the environment';
  my $env = Langertha::Knarr::Config->new( data => {} );
  is( $env->a2a_name, 'Env Agent', 'falls back to KNARR_A2A_NAME (quotes stripped)' );
  is( $env->a2a_description, 'From the environment', 'falls back to KNARR_A2A_DESCRIPTION' );
  is( Langertha::Knarr::Config->new( data => { a2a => { name => 'Cfg Agent' } } )->a2a_name,
    'Cfg Agent', 'the config value wins over the env' );
}

done_testing;
