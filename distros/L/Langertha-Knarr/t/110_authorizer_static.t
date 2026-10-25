use strict;
use warnings;
use Test2::V0;

# k82: the fixed comparison of Knarr::_check_auth became one implementation
# of an authorizer interface, Langertha::Knarr::Authorizer::StaticKey, with
# the behaviour of auth_token unchanged (the end-to-end tests t/76_*,
# t/100-108, t/91_* run it unedited). This test pins the class itself and how
# Knarr builds it: the default authorizer is a StaticKey over auth_token,
# built anew when the auth_token changes (an admin push, k75), while an
# authorizer given to the constructor stays.

use HTTP::Headers;
use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Authorizer::StaticKey;

{
  package FakeHttp;
  sub new { my ( $class, @h ) = @_; bless { h => HTTP::Headers->new(@h) }, $class }
  sub header { my ( $self, $n ) = @_; scalar $self->{h}->header($n) }
}

my $key = 'sk-static-key';
my $static = Langertha::Knarr::Authorizer::StaticKey->new( key => $key );

ok( $static->DOES('Langertha::Knarr::Authorizer'), 'StaticKey does the Authorizer role' );

my %cases = (
  'Bearer'                      => [ [ Authorization => "Bearer $key" ], 1 ],
  'lower-case bearer'           => [ [ Authorization => "bearer $key" ], 1 ],
  'x-api-key'                   => [ [ 'x-api-key' => $key ], 1 ],
  'second element (k53)'        => [ [ Authorization => "Bearer sk-provider, Bearer $key" ], 1 ],
  'x-api-key element (k53)'     => [ [ 'x-api-key' => "sk-provider, $key" ], 1 ],
  'bare key in Authorization'   => [ [ Authorization => $key ], 0 ],
  'wrong Bearer'                => [ [ Authorization => 'Bearer wrong' ], 0 ],
  'wrong x-api-key'             => [ [ 'x-api-key' => 'wrong' ], 0 ],
  'prefix of the key'           => [ [ 'x-api-key' => 'sk-static' ], 0 ],
  'nothing'                     => [ [], 0 ],
);
for my $name ( sort keys %cases ) {
  my ( $headers, $ok ) = @{ $cases{$name} };
  my $result = $static->identify( FakeHttp->new(@$headers), 'chat' );
  is( $result, $ok ? { identity => {} } : { status => 401, message => 'unauthorized' }, "identify: $name" );
  is( $static->identify_f( FakeHttp->new(@$headers), 'chat' )->get, $result, "identify_f agrees: $name" );
}

is( $static->identify( FakeHttp->new, 'a2a_card' ), { identity => {} }, 'the A2A agent card stays anonymous' );
for my $open ( undef, '' ) {
  is( Langertha::Knarr::Authorizer::StaticKey->new( key => $open )->identify( FakeHttp->new, 'chat' ),
    { identity => {} }, 'no key: every request is let in (' . ( defined $open ? 'empty' : 'undef' ) . ')' );
}

is( [ $static->authorize( {}, 'chat', 'any-model' ) ], [], 'authorize allows every model' );
is( [ $static->authorize( {}, 'manifest', undef ) ], [], 'authorize allows the manifest' );
my $list = [ { id => 'a' }, { id => 'b' } ];
is( $static->visible_models( {}, $list ), $list, 'visible_models shows every listed model' );
ok( $static->forwards_client_key, 'the client key may reach a passthrough upstream' );
ok( $static->_same_key( $key, $key ) && !$static->_same_key( $key, "${key}x" ), 'constant-time compare' );

# --- How Knarr builds it.
my $handler = Langertha::Knarr::Handler::Code->new( code => sub { 'ok' } );

my $knarr = Langertha::Knarr->new( handler => $handler, auth_token => 'first-key' );
isa_ok( $knarr->authorizer, ['Langertha::Knarr::Authorizer::StaticKey'], 'default authorizer' );
is( $knarr->authorizer->key, 'first-key', 'built over auth_token' );
$knarr->_set_auth_token('second-key');
is( $knarr->authorizer->key, 'second-key', 'a new auth_token (admin push) gets a new StaticKey' );
$knarr->_set_auth_token(undef);
is( $knarr->authorizer->identify( FakeHttp->new, 'chat' ), { identity => {} }, 'no auth_token: open' );

my $given = Langertha::Knarr::Authorizer::StaticKey->new( key => 'given-key' );
my $with = Langertha::Knarr->new( handler => $handler, authorizer => $given, auth_token => 'other' );
ref_is( $with->authorizer, $given, 'a given authorizer is used' );
$with->_set_auth_token('pushed');
ref_is( $with->authorizer, $given, 'and kept when the auth_token changes' );

ok( Langertha::Knarr::_same_key( 'a', 'a' ) && !Langertha::Knarr::_same_key( 'a', 'b' ),
  'Knarr::_same_key still answers (t/104)' );

done_testing;
