#!/usr/bin/env perl
# ABSTRACT: The stored binding of a provider alias: what is pinned and when a manifest still matches (k133)
use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS ();
use Path::Tiny;
use Langertha::Manifest;
use Langertha::Raider::Config;
use Langertha::Raider::Provider::Binding;

my $class  = 'Langertha::Raider::Provider::Binding';
my $ORIGIN = 'https://provider.example';

sub manifest {
  my ( $edit ) = @_;
  my $data = {
    schema_version => 1,
    kind           => 'langertha-provider',
    provider_id    => 'example-provider',
    issuer         => $ORIGIN,
    endpoints      => [
      { id => 'chat',  dialect => 'openai-chat', base_url => $ORIGIN.'/v1', auth_ref => 'api' },
      { id => 'spare', dialect => 'ollama',      base_url => $ORIGIN.'/ollama' },
    ],
    auth   => [ { id => 'api', type => 'api_key' } ],
    models => [ { id => 'a', endpoint_ref => 'chat', capabilities => { tools_native => JSON::MaybeXS::true() } } ],
  };
  $edit->($data) if $edit;
  return Langertha::Manifest->from_hash($data);
}

my $accepted = manifest();
my $entry = $class->entry( $accepted, $ORIGIN.'/.well-known/langertha.json',
  credential_env => 'EXAMPLE_API_KEY', allow_internal => 0, now => 0 );

is( $entry, {
  origin         => $ORIGIN.':443',
  issuer         => $ORIGIN,
  auth           => ['api_key'],
  credential_env => 'EXAMPLE_API_KEY',
  allow_internal => 0,
  pinned_at      => '1970-01-01T00:00:00Z',
  fingerprint    => match(qr/\A[0-9a-f]{64}\z/),
}, 'origin (of the manifest URL), issuer, sorted auth types, credential variable name, allow_internal, time' );
is( $class->problem($entry), undef, 'a fresh entry is well-formed' );
is( $class->verify( $entry, $accepted, $ORIGIN ), undef, 'it matches the manifest it came from' );

subtest 'no consent needed: the binding still matches' => sub {
  for my $case (
    [ 'models changed' => sub { push @{ $_[0]{models} }, { id => 'b', endpoint_ref => 'chat' } } ],
    [ 'capabilities changed' => sub { $_[0]{models}[0]{capabilities}{streaming} = JSON::MaybeXS::true() } ],
    [ 'a path in the same origin' => sub { $_[0]{endpoints}[0]{base_url} = $ORIGIN.'/v2' } ],
    [ 'an unused auth entry' => sub { push @{ $_[0]{auth} }, { id => 'spare', type => 'bearer' } } ],
  ) {
    my ( $what, $edit ) = @$case;
    is( $class->verify( $entry, manifest($edit), $ORIGIN ), undef, $what );
  }
};

subtest 'consent needed: it does not match, and says what differs' => sub {
  for my $case (
    [ 'issuer' => sub { $_[0]{issuer} = 'https://evil.example' }, qr/issuer \Q$ORIGIN\E -> https:\/\/evil\.example/ ],
    [ 'auth type' => sub { $_[0]{auth}[0]{type} = 'bearer' }, qr/auth \[api_key\] -> \[bearer\]/ ],
    [ 'endpoint origin' => sub { $_[0]{endpoints}[0]{base_url} = 'https://other.example/v1' },
      qr/differ from what was accepted/ ],
    [ 'endpoint dialect' => sub { $_[0]{endpoints}[0]{dialect} = 'anthropic' }, qr/differ from what was accepted/ ],
    [ 'endpoint added' => sub { push @{ $_[0]{endpoints} }, { id => 'x', dialect => 'ollama', base_url => $ORIGIN.'/x' } },
      qr/differ from what was accepted/ ],
    [ 'provider id' => sub { $_[0]{provider_id} = 'someone-else' }, qr/differ from what was accepted/ ],
  ) {
    my ( $what, $edit, $why ) = @$case;
    like( $class->verify( $entry, manifest($edit), $ORIGIN ), $why, $what );
  }
  like( $class->verify( $entry, $accepted, 'https://provider.example:8443' ), qr/origin \Q$ORIGIN\E:443 -> https:\/\/provider\.example:8443/,
    'the origin it was fetched from' );
};

subtest 'allow_internal is part of the pin class' => sub {
  my $tampered = { %$entry, allow_internal => 1 };
  like( $class->verify( $tampered, $accepted, $ORIGIN ), qr/differ from what was accepted/, 'switched on by hand' );
  my $internal = $class->entry( $accepted, $ORIGIN, credential_env => 'EXAMPLE_API_KEY', allow_internal => 1 );
  isnt( $internal->{fingerprint}, $entry->{fingerprint}, 'it is covered by the fingerprint' );
  is( $class->verify( $internal, $accepted, $ORIGIN ), undef, 'and matches itself' );
  like( $class->verify( { %$internal, allow_internal => 0 }, $accepted, $ORIGIN ), qr/differ/, 'switched off by hand' );
};

subtest 'credential_env is part of the pin class (k150)' => sub {
  my $moved = { %$entry, credential_env => 'OTHER_SECRET' };
  my $why = $class->verify( $moved, $accepted, $ORIGIN );
  like( $why, qr/credential_env/, 'another variable by hand: no match, and the message names credential_env' );
  my $other = $class->entry( $accepted, $ORIGIN, credential_env => 'OTHER_SECRET', allow_internal => 0 );
  isnt( $other->{fingerprint}, $entry->{fingerprint}, 'the variable is covered by the fingerprint' );
  is( $class->verify( $other, $accepted, $ORIGIN ), undef, 'accepted anew with it, it matches' );
  like( $class->verify( { %$entry, credential_env => undef }, $accepted, $ORIGIN ), qr/differ/, 'dropped by hand' );
  my $none = $class->entry( manifest( sub { delete $_[0]{endpoints}[0]{auth_ref}; $_[0]{auth} = [] } ), $ORIGIN );
  is( $class->verify( { %$none, credential_env => 'X' }, manifest( sub { delete $_[0]{endpoints}[0]{auth_ref}; $_[0]{auth} = [] } ), $ORIGIN ),
    match(qr/differ/), 'added by hand to a binding without auth' );
};

subtest 'summary: the display-safe fields' => sub {
  is( $class->summary( acme => $entry ), {
    alias => 'acme', origin => $ORIGIN.':443', issuer => $ORIGIN, auth => ['api_key'],
    credential_env => 'EXAMPLE_API_KEY', allow_internal => 0, pinned_at => '1970-01-01T00:00:00Z',
    fingerprint => $entry->{fingerprint},
  }, 'fields' );
  is( $class->summary( bad => 'x' ), { alias => 'bad', problem => 'is not a mapping' }, 'a non-mapping says why' );
  like( $class->summary( bad => { %$entry, fingerprint => undef } )->{problem}, qr/fingerprint is missing/, 'a malformed entry' );
};

subtest 'a stored entry is not trusted beyond its shape' => sub {
  my %ok = %$entry;
  for my $case (
    [ 'not a mapping', 'https://evil.example', qr/is not a mapping/ ],
    [ 'no fingerprint', { %ok, fingerprint => undef }, qr/fingerprint is missing/ ],
    [ 'no origin', { %ok, origin => '' }, qr/origin is missing/ ],
    [ 'a plain http origin', { %ok, origin => 'http://provider.example' }, qr/not an https origin/ ],
    [ 'an origin with a path', { %ok, origin => $ORIGIN.'/x' }, qr/not an https origin/ ],
    [ 'auth not a list', { %ok, auth => 'api_key' }, qr/auth is not a list/ ],
    [ 'a variable name with a shell in it', { %ok, credential_env => 'A; rm -rf /' }, qr/not an environment variable name/ ],
  ) {
    my ( $what, $bad, $why ) = @$case;
    like( $class->problem($bad), $why, $what );
  }
  ok( !$class->problem( { %ok, credential_env => undef } ), 'a binding to a provider without auth has no variable' );
  like( dies { $class->entry( $accepted, $ORIGIN, credential_env => 'not a name' ) }, qr/not an environment variable name/,
    'entry refuses a bad variable name' );
};

subtest 'names' => sub {
  ok( $class->valid_alias($_), "'$_' is an alias" ) for qw( acme a1 my-provider my_provider 0abc );
  ok( !$class->valid_alias($_), "'".( $_ // 'undef' )."' is not" )
    for ( undef, '', 'Acme', 'a.b', 'a:443', 'https://x', '-a', 'a b', 'x' x 33 );
  ok( $class->valid_credential_env($_), "'$_' is a variable name" ) for qw( FOO FOO_API_KEY _x a1 );
  ok( !$class->valid_credential_env($_), "'".( $_ // 'undef' )."' is not" ) for ( undef, '', '1A', 'A-B', 'A B', '$A' );
};

subtest 'Config providers: the home file only, a mapping' => sub {
  my $dir = Path::Tiny->tempdir;
  my $home = Path::Tiny->tempdir;
  local $ENV{HOME} = "$home";
  my $config = sub { Langertha::Raider::Config->new( root => "$dir" ) };
  is( $config->()->providers, {}, 'no home file: none' );
  $home->child('.raider')->mkpath;
  $home->child('.raider', 'config.yml')->spew_utf8("providers:\n  acme:\n    origin: https://provider.example\n");
  is( $config->()->providers, { acme => { origin => 'https://provider.example' } }, 'read from the home file' );
  $home->child('.raider', 'config.yml')->spew_utf8("providers: [a, b]\n");
  like( dies { $config->()->providers }, qr/providers: must be a mapping/, 'a list is refused' );
  $home->child('.raider', 'config.yml')->spew_utf8("providers:\n  perl:\n    origin: https://provider.example\n");
  is( [ keys %{ $config->()->providers } ], ['perl'], 'an alias named like a raider key is no clash' );
};

done_testing;
