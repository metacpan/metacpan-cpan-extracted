#!/usr/bin/env perl
# ABSTRACT: Provider manifest changes are classified as needing renewed consent or not (k131)
use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS ();
use Langertha::Manifest;
use Langertha::Raider::Provider::Change;

# Handoff 11.2: a model list may change without renegotiating anything; a
# change of origin, issuer, provider identity, endpoint origin, dialect or
# auth mechanism needs renewed consent. Pure logic over fixture pairs: an
# accepted manifest and a newly fetched one, each with its origin. Offline.

my $class  = 'Langertha::Raider::Provider::Change';
my $ORIGIN = 'https://provider.example';

sub base_data {
  return {
    schema_version => 1,
    kind           => 'langertha-provider',
    provider_id    => 'example-provider',
    issuer         => 'https://provider.example',
    endpoints      => [
      { id => 'chat',     dialect => 'openai-chat', base_url => 'https://provider.example/v1',        auth_ref => 'api' },
      { id => 'messages', dialect => 'anthropic',   base_url => 'https://provider.example/anthropic', auth_ref => 'api' },
      { id => 'spare',    dialect => 'ollama',      base_url => 'https://provider.example/ollama' },
    ],
    auth   => [ { id => 'api', type => 'api_key' } ],
    models => [
      { id => 'model-a', endpoint_ref => 'chat', capabilities => { tools_native => JSON::MaybeXS::true(), streaming => JSON::MaybeXS::true() } },
      { id => 'model-b', endpoint_ref => 'chat' },
      { id => 'model-c', endpoint_ref => 'messages', capabilities => { tools_native => JSON::MaybeXS::true() } },
    ],
    extensions => { 'x-example' => { note => 'inert' } },
  };
}

sub manifest {
  my ( $edit ) = @_;
  my $data = base_data();
  $edit->($data) if $edit;
  return Langertha::Manifest->from_hash($data);
}

sub endpoint_of { my ( $data, $id ) = @_; ( grep { $_->{id} eq $id } @{ $data->{endpoints} } )[0] }

my $accepted = manifest();

sub against {
  my ( $new, %opt ) = @_;
  return $class->classify(
    old => $opt{old} // $accepted, old_origin => $opt{old_origin} // $ORIGIN,
    new => $new,                   new_origin => $opt{new_origin} // $ORIGIN,
  );
}

# Every pair classified in this test, for the invariant at the end.
my @seen;

sub pair_ok {
  my ( $name, $new, $expect, %opt ) = @_;
  my $got = against($new, %opt);
  push @seen, [ $name, $got ];
  subtest $name => sub {
    is [ map { [ $_->{kind}, $_->{consent} ] } @{ $got->{changes} } ], $expect->{changes}, 'kinds and consent flags';
    is $got->{needs_consent}, $expect->{needs_consent}, 'needs_consent';
    if ( $expect->{needs_consent} ) {
      isnt $got->{new_fingerprint}, $got->{old_fingerprint}, 'fingerprint changes';
    }
    else {
      is $got->{new_fingerprint}, $got->{old_fingerprint}, 'fingerprint stays';
    }
    for my $i ( 0 .. $#{ $expect->{like} // [] } ) {
      like $got->{changes}[$i]{description}, $expect->{like}[$i], 'description '.$i;
    }
    is $got->{changes}[0]{ $_ }, $expect->{about}{$_}, 'change names its '.$_
      for sort keys %{ $expect->{about} // {} };
  };
  return $got;
}

subtest 'the consent view' => sub {
  is $class->consent_view($accepted, $ORIGIN.'/.well-known/langertha.json'), {
    view        => 'raider-provider-consent-1',
    origin      => 'https://provider.example:443',
    issuer      => 'https://provider.example',
    provider_id => 'example-provider',
    endpoints   => {
      chat     => { origin => 'https://provider.example:443', dialect => 'openai-chat', auth => 'api_key' },
      messages => { origin => 'https://provider.example:443', dialect => 'anthropic',   auth => 'api_key' },
      spare    => { origin => 'https://provider.example:443', dialect => 'ollama',      auth => undef },
    },
  }, 'origins, issuer, provider id, and per endpoint origin, dialect and auth type -- no models, no extensions';
  like $class->fingerprint($accepted, $ORIGIN), qr/\A[0-9a-f]{64}\z/, 'fingerprint is a sha256 hex digest';
};

pair_ok 'the same manifest' => manifest(), { changes => [], needs_consent => 0 };

subtest 'fingerprint is stable under document key order, array order and origin spelling' => sub {
  my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
  my $text = $json->encode(base_data());
  # The same document, keys in another order and arrays reversed.
  my $data = base_data();
  $data->{$_} = [ reverse @{ $data->{$_} } ] for qw( endpoints models );
  my $other = '{'.join(',', map { $json->encode($_).':'.$json->encode($data->{$_}) } reverse sort keys %$data).'}';
  isnt $other, $text, 'the two documents differ as text';
  my ( $one, $two ) = map { Langertha::Manifest->from_json($_) } $text, $other;
  is $class->fingerprint($two, $ORIGIN), $class->fingerprint($one, $ORIGIN), 'same fingerprint';
  is $class->fingerprint($one, 'HTTPS://Provider.Example:443/.well-known/langertha.json'),
    $class->fingerprint($one, $ORIGIN), 'origin given as a URL, upper case, explicit default port';
  is against($two)->{changes}, [], 'no change reported';
};

#### Changes that need consent

pair_ok 'manifest origin' => manifest(), {
  changes => [ [ origin => 1 ] ], needs_consent => 1,
  like => [ qr{https://provider\.example:443 -> https://mirror\.example:443} ],
}, new_origin => 'https://mirror.example';

pair_ok 'manifest origin port' => manifest(), {
  changes => [ [ origin => 1 ] ], needs_consent => 1,
}, new_origin => 'https://provider.example:8443';

pair_ok 'issuer' => manifest(sub { $_[0]{issuer} = 'https://other.example' }), {
  changes => [ [ issuer => 1 ] ], needs_consent => 1,
  like => [ qr{https://provider\.example -> https://other\.example} ],
};

pair_ok 'issuer, trailing slash only (compared as the exact string)' => manifest(sub { $_[0]{issuer} = 'https://provider.example/' }), {
  changes => [ [ issuer => 1 ] ], needs_consent => 1,
};

pair_ok 'provider_id' => manifest(sub { $_[0]{provider_id} = 'renamed-provider' }), {
  changes => [ [ provider_id => 1 ] ], needs_consent => 1,
  like => [ qr/example-provider -> renamed-provider/ ],
};

pair_ok 'endpoint base_url to another host' => manifest(sub { endpoint_of($_[0], 'chat')->{base_url} = 'https://api.elsewhere.example/v1' }), {
  changes => [ [ endpoint_origin => 1 ] ], needs_consent => 1,
  like => [ qr{endpoint 'chat': origin https://provider\.example:443 -> https://api\.elsewhere\.example:443} ],
  about => { endpoint => 'chat' },
};

pair_ok 'endpoint base_url to another port' => manifest(sub { endpoint_of($_[0], 'chat')->{base_url} = 'https://provider.example:8443/v1' }), {
  changes => [ [ endpoint_origin => 1 ] ], needs_consent => 1,
};

pair_ok 'endpoint base_url from https to http' => manifest(sub { endpoint_of($_[0], 'chat')->{base_url} = 'http://provider.example/v1' }), {
  changes => [ [ endpoint_origin => 1 ] ], needs_consent => 1,
};

pair_ok 'endpoint dialect' => manifest(sub { endpoint_of($_[0], 'chat')->{dialect} = 'responses' }), {
  changes => [ [ endpoint_dialect => 1 ] ], needs_consent => 1,
  like => [ qr/'chat': dialect openai-chat -> responses/ ],
  about => { endpoint => 'chat' },
};

pair_ok 'dialect of an endpoint no model uses yet' => manifest(sub { endpoint_of($_[0], 'spare')->{dialect} = 'openai-chat' }), {
  changes => [ [ endpoint_dialect => 1 ] ], needs_consent => 1,
};

pair_ok 'auth type of an auth entry endpoints use' => manifest(sub { $_[0]{auth}[0]{type} = 'oauth2' }), {
  changes => [ [ endpoint_auth => 1 ], [ endpoint_auth => 1 ] ], needs_consent => 1,
  like => [ qr/'chat': auth type api_key -> type oauth2/, qr/'messages': auth type api_key -> type oauth2/ ],
};

pair_ok 'endpoint switches to an auth entry of another type' => manifest(sub {
  push @{ $_[0]{auth} }, { id => 'token', type => 'bearer' };
  endpoint_of($_[0], 'messages')->{auth_ref} = 'token';
}), {
  changes => [ [ endpoint_auth => 1 ] ], needs_consent => 1,
  about => { endpoint => 'messages' },
};

pair_ok 'endpoint drops its auth' => manifest(sub { delete endpoint_of($_[0], 'chat')->{auth_ref} }), {
  changes => [ [ endpoint_auth => 1 ] ], needs_consent => 1,
  like => [ qr/'chat': auth type api_key -> none/ ],
};

pair_ok 'endpoint gains an auth' => manifest(sub { endpoint_of($_[0], 'spare')->{auth_ref} = 'api' }), {
  changes => [ [ endpoint_auth => 1 ] ], needs_consent => 1,
  like => [ qr/'spare': auth none -> type api_key/ ],
};

pair_ok 'endpoint added' => manifest(sub {
  push @{ $_[0]{endpoints} }, { id => 'gem', dialect => 'gemini', base_url => 'https://provider.example/gemini', auth_ref => 'api' };
}), {
  changes => [ [ endpoint_added => 1 ] ], needs_consent => 1,
  like => [ qr/'gem' added: dialect gemini at https:\/\/provider\.example:443, auth type api_key/ ],
  about => { endpoint => 'gem' },
};

pair_ok 'endpoint removed' => manifest(sub { $_[0]{endpoints} = [ grep { $_->{id} ne 'spare' } @{ $_[0]{endpoints} } ] }), {
  changes => [ [ endpoint_removed => 1 ] ], needs_consent => 1,
  like => [ qr/'spare' removed \(was dialect ollama/ ],
};

#### Changes that need no consent

pair_ok 'model added' => manifest(sub { push @{ $_[0]{models} }, { id => 'model-d', endpoint_ref => 'messages' } }), {
  changes => [ [ model_added => 0 ] ], needs_consent => 0,
  like => [ qr/model 'model-d' on endpoint 'messages' added/ ],
  about => { model => 'model-d', endpoint => 'messages' },
};

pair_ok 'model removed' => manifest(sub { $_[0]{models} = [ grep { $_->{id} ne 'model-b' } @{ $_[0]{models} } ] }), {
  changes => [ [ model_removed => 0 ] ], needs_consent => 0,
};

pair_ok 'model moves to another endpoint' => manifest(sub { $_[0]{models}[1]{endpoint_ref} = 'spare' }), {
  changes => [ [ model_removed => 0 ], [ model_added => 0 ] ], needs_consent => 0,
  like => [ qr/'model-b' on endpoint 'chat' removed/, qr/'model-b' on endpoint 'spare' added/ ],
};

pair_ok 'all models replaced' => manifest(sub { $_[0]{models} = [ { id => 'fresh', endpoint_ref => 'chat' } ] }), {
  changes => [ [ model_added => 0 ], [ model_removed => 0 ], [ model_removed => 0 ], [ model_removed => 0 ] ], needs_consent => 0,
};

pair_ok 'capability withdrawn' => manifest(sub { $_[0]{models}[0]{capabilities}{tools_native} = JSON::MaybeXS::false() }), {
  changes => [ [ model_capabilities => 0 ] ], needs_consent => 0,
  like => [ qr/'model-a' on endpoint 'chat': capabilities \{streaming=true, tools_native=true\} -> \{streaming=true, tools_native=false\}/ ],
};

pair_ok 'capability declared' => manifest(sub { $_[0]{models}[1]{capabilities} = { tools_native => JSON::MaybeXS::true(), server_tools => JSON::MaybeXS::true() } }), {
  changes => [ [ model_capabilities => 0 ] ], needs_consent => 0,
  like => [ qr/'model-b' .*: capabilities \(none\) -> \{server_tools=true, tools_native=true\}/ ],
};

pair_ok 'extensions' => manifest(sub { $_[0]{extensions} = { 'x-mcp' => { servers => [ 'https://mcp.example' ] } } }), {
  changes => [ [ extensions => 0 ] ], needs_consent => 0,
};

pair_ok 'endpoint path within the origin' => manifest(sub { endpoint_of($_[0], 'chat')->{base_url} = 'https://provider.example/api/v2' }), {
  changes => [ [ endpoint_path => 0 ] ], needs_consent => 0,
  like => [ qr{https://provider\.example/v1 -> https://provider\.example/api/v2 \(same origin\)} ],
};

pair_ok 'endpoint host case and explicit default port' => manifest(sub { endpoint_of($_[0], 'chat')->{base_url} = 'https://Provider.Example:443/v1' }), {
  changes => [ [ endpoint_path => 0 ] ], needs_consent => 0,
};

pair_ok 'auth entry renamed, same type' => manifest(sub {
  $_[0]{auth} = [ { id => 'key', type => 'api_key' } ];
  $_->{auth_ref} = 'key' for grep { $_->{auth_ref} } @{ $_[0]{endpoints} };
}), {
  changes => [ [ endpoint_auth_ref => 0 ], [ endpoint_auth_ref => 0 ], [ auth_removed => 0 ] ], needs_consent => 0,
  like => [ qr/'chat': auth_ref 'api' -> 'key' \(same type api_key\)/ ],
};

pair_ok 'auth entry no endpoint uses: added' => manifest(sub { push @{ $_[0]{auth} }, { id => 'spare-auth', type => 'oauth2' } }), {
  changes => [ [ auth_added => 0 ] ], needs_consent => 0,
  about => { auth => 'spare-auth' },
};

my $with_spare_auth = manifest(sub { push @{ $_[0]{auth} }, { id => 'spare-auth', type => 'oauth2' } });

pair_ok 'auth entry no endpoint uses: type changed' => manifest(sub { push @{ $_[0]{auth} }, { id => 'spare-auth', type => 'bearer' } }), {
  changes => [ [ auth_type => 0 ] ], needs_consent => 0,
}, old => $with_spare_auth;

pair_ok 'auth entry no endpoint uses: removed' => manifest(), {
  changes => [ [ auth_removed => 0 ] ], needs_consent => 0,
}, old => $with_spare_auth;

#### Mixed

pair_ok 'benign and consent changes together, in a stable order' => manifest(sub {
  $_[0]{issuer} = 'https://other.example';
  push @{ $_[0]{models} }, { id => 'model-d', endpoint_ref => 'chat' };
  endpoint_of($_[0], 'messages')->{dialect} = 'anthropic-compat';
  $_[0]{extensions} = {};
}), {
  changes => [ [ issuer => 1 ], [ endpoint_dialect => 1 ], [ model_added => 0 ], [ extensions => 0 ] ],
  needs_consent => 1,
}, new_origin => 'https://provider.example/.well-known/langertha.json';

pair_ok 'the accepted manifest is compared, not the latest seen' => manifest(sub { $_[0]{provider_id} = 'renamed-provider' }), {
  changes => [ [ issuer => 1 ] ], needs_consent => 1,
}, old => manifest(sub { $_[0]{provider_id} = 'renamed-provider'; $_[0]{issuer} = 'https://old.example' });

subtest 'needs_consent is exactly "the fingerprint changed"' => sub {
  for my $case (@seen) {
    my ( $name, $got ) = @$case;
    is $got->{needs_consent}, ( $got->{old_fingerprint} ne $got->{new_fingerprint} ? 1 : 0 ), $name;
    is $got->{new_fingerprint}, $class->fingerprint(manifest(), $ORIGIN), $name.': benign changes keep the accepted fingerprint'
      if !$got->{needs_consent} && $got->{old_fingerprint} eq $class->fingerprint($accepted, $ORIGIN);
  }
};

subtest 'bad arguments croak' => sub {
  like dies { $class->classify( old => $accepted, old_origin => $ORIGIN, new => $accepted ) },
    qr/classify needs new_origin/, 'missing origin';
  like dies { $class->classify( old => base_data(), old_origin => $ORIGIN, new => $accepted, new_origin => $ORIGIN ) },
    qr/needs a Langertha::Manifest, got HASH/, 'a plain hash is not a manifest';
  like dies { $class->fingerprint($accepted, 'provider.example') },
    qr/origin names no origin: provider\.example/, 'a bare host is no origin';
  like dies { $class->fingerprint($accepted, undef) }, qr/names no origin: undef/, 'undef origin';
};

done_testing;
