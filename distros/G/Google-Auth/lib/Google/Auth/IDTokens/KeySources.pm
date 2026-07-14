# frozen_string_literal: true
# Copyright 2020,2021,2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Google::Auth::IDTokens::KeySources;

use strict;
use warnings;

use URI;
use JSON::MaybeXS;
use HTTP::Tiny;
use Google::Auth;
use MIME::Base64 qw(decode_base64);


our $VERSION = 0.02;

1;

##
# A public key used for verifying ID tokens.
#
# This includes the public key data, ID, and the algorithm used for
# signature verification. RSA and Elliptical Curve (EC) keys are
# supported.
#

package Google::Auth::IDTokens::KeyInfo;

use Carp;

my $coder = JSON::MaybeXS->new->ascii->pretty->allow_nonref;

##
# Create a public key info structure.
#
# @param id [String] The key ID.
# @param key [Crypt::PK::RSA,Crypt::PK::ECC] The key itself.
# @param algorithm [String] The algorithm (normally `RS256` or `ES256`)
#
sub new
{
    my ( $class, $params ) = @_;
    $params //= {};
    $class = ref $class if ref $class;
    my $self = bless {
        id        => $params->{id}        // undef,
        key       => $params->{key}       // undef,
        algorithm => $params->{algorithm} // undef,
    }, $class;
    return $self;
}

##
# The key ID.
# @return [String]
#
sub id { return $_[0]->{id} }

##
# The key itself.
# @return [OpenSSL::PKey::RSA,OpenSSL::PKey::EC]
#
sub key { return $_[0]->{key} }

##
# The signature algorithm. (normally `RS256` or `ES256`)
# @return [String]
#
sub algorithm { return $_[0]->{algorithm} }

##
# Create a KeyInfo from a single JWK, which may be given as either a
# hash or an unparsed JSON string.
#
# @param jwk [Hash,String] The JWK specification.
# @return [KeyInfo]
# @raise [KeySourceError] If the key could not be extracted from the
#     JWK.
#
sub from_jwk
{
    my ( $self, $jwk ) = @_;
    $jwk = $self->ensure_json_parsed($jwk);

    my $instance = ref $self ? $self : $self->new();

    if ( $jwk->{kty} eq 'RSA' )
    {
        $instance->{key} = $instance->extract_rsa_key($jwk);
    }
    elsif ( $jwk->{kty} eq 'EC' )
    {
        $instance->{key} = $instance->extract_ec_key($jwk);
    }
    elsif ( !defined $jwk->{kty} )
    {
        die 'Key type not found';
    }
    else
    {
        die 'Cannot use key type ' . $jwk->{kty};
    }
    $instance->{id}        = $jwk->{kid};
    $instance->{algorithm} = $jwk->{alg};

    return $instance;
}
##
# Create an array of KeyInfo from a JWK Set, which may be given as
# either a hash or an unparsed JSON string.
#
# @param jwk [Hash,String] The JWK Set specification.
# @return [Array<KeyInfo>]
# @raise [KeySourceError] If a key could not be extracted from the
#     JWK Set.
#
sub from_jwk_set
{
    my ( $self, $jwk_set ) = @_;
    confess 'jwk_set is a required argument' unless $jwk_set;
    $jwk_set = $self->ensure_json_parsed($jwk_set);
    confess "No keys found in jwk set"
        unless ( exists $jwk_set->{keys}
        && ref $jwk_set->{keys} eq 'ARRAY' );
    my $jwks = [ map { $self->from_jwk($_) } @{ $jwk_set->{keys} } ];

    return $jwks;
}

sub ensure_json_parsed
{
    my ( $self, $input ) = @_;
    confess 'input is a required argument' unless $input;
    return $input if ref $input;
    my $decoded = eval { $coder->decode($input) };

    confess( "Unable to parse JSON: $@$/" . "input: $input" ) if $@;
    return $decoded;
}

sub symbolize_keys
{
    my ( $self, $hash ) = @_;
    my $result = {};
    while ( my ( $key, $val ) = each %$hash )
    {
        $result->{$key} = $val;
    }
    return $result;
}

sub _decode_base64url
{
    my ($s) = @_;
    $s =~ tr{-_}{+/};
    my $padding = length($s) % 4;
    if ($padding)
    {
        $s .= '=' x ( 4 - $padding );
    }
    return MIME::Base64::decode_base64($s);
}

sub extract_rsa_key
{
    my ( $self, $jwk ) = @_;
    my $n = _decode_base64url( $jwk->{n} );
    my $e = _decode_base64url( $jwk->{e} );
    my $pubkey = Google::Auth::load_rsa_pubkey( $n, $e );
    die 'Failed to load RSA public key' unless defined $pubkey;
    return $pubkey;
}

# @private
my $CURVE_NAME_MAP = {
    'P-256'     => 'prime256v1',
    'P-384'     => 'secp384r1',
    'P-521'     => 'secp521r1',
    'secp256k1' => 'secp256k1'
};

sub extract_ec_key
{
    my ( $self, $jwk ) = @_;
    my $curve = $jwk->{crv};
    die 'Unsupported EC curve ' . $curve
        unless exists $CURVE_NAME_MAP->{$curve};

    my $x = _decode_base64url( $jwk->{x} );
    my $y = _decode_base64url( $jwk->{y} );

    my $openssl_curve = $CURVE_NAME_MAP->{$curve};
    my $pubkey = Google::Auth::load_ec_pubkey( $openssl_curve, $x, $y );
    die 'Failed to load EC public key' unless defined $pubkey;
    return $pubkey;
}

1;

package Google::Auth::IDTokens::StaticKeySource;
##
# A key source that contains a static set of keys.
#
##
# Create a static key source with the given keys.
#
# @param keys [Array<KeyInfo>] The keys
#
sub new
{
    my ( $class, $params ) = @_;
    $class = ref $class if ref $class;
    my $self = bless { current_keys => [ @{ $params->{keys} } ] }, $class;
    return $self;
}

##
# Return the current keys. Does not perform any refresh.
#
# @return [Array<KeyInfo>]
#
sub current_keys { return $_[0]->{current_keys} }
*refresh_keys = \&current_keys;

##
# Create a static key source containing a single key parsed from a
# single JWK, which may be given as either a hash or an unparsed
# JSON string.
#
# @param jwk [Hash,String] The JWK specification.
# @return [StaticKeySource]
#
sub from_jwk
{
    my ( $self, $jwk ) = @_;
    return Google::Auth::IDTokens::KeyInfo->new()->from_jwk($jwk);
}

##
# Create a static key source containing multiple keys parsed from a
# JWK Set, which may be given as either a hash or an unparsed JSON
# string.
#
# @param jwk_set [Hash,String] The JWK Set specification.
# @return [StaticKeySource]
#
sub from_jwk_set
{
    my ( $self, $jwk_set ) = @_;
    return Google::Auth::IDTokens::KeyInfo->new()->from_jwk_set($jwk_set);
}

1;

package Google::Auth::IDTokens::HttpKeySource;
##
# A base key source that downloads keys from a URI. Subclasses should
# override {HttpKeySource#interpret_json} to parse the response.
#
##
# The default interval between retries in seconds (3600s = 1hr).
#
# @return [Integer]
#
our $DEFAULT_RETRY_INTERVAL = 3600;

##
# Create an HTTP key source.
#
# @param uri [String,URI] The URI from which to download keys.
# @param retry_interval [Integer,nil] Override the retry interval in
#     seconds. This is the minimum time between retries of failed key
#     downloads.
#
sub new
{
    my ( $class, $params ) = @_;
    $class = ref $class if ref $class;
    die "uri is a required parameter$/" . Data::Dumper::Dumper($params)
        unless ( exists $params->{uri} && $params->{uri} );

    my $self = bless {
        retry_interval => $params->{retry_interval} || $DEFAULT_RETRY_INTERVAL,
        allow_refresh_at => time(),
        current_keys     => [],
        uri              => URI->new( $params->{uri} ),
    }, $class;

    if ( exists $ENV{TESTING} && $ENV{TESTING} )
    {
        $self->{ua} = $KeySourcesTest::useragent;
    }
    else
    {
        $self->{ua} = HTTP::Tiny->new( timeout => 10 );
    }

    return $self;
}

##
# The URI from which to download keys.
# @return [Array<KeyInfo>]
#
sub uri { return $_[0]->{uri} }

##
# Return the current keys, without attempting to re-download.
#
# @return [Array<KeyInfo>]
#
sub current_keys { return $_[0]->{current_keys} }

##
# Attempt to re-download keys (if the retry interval has expired) and
# return the new keys.
#
# @return [Array<KeyInfo>]
# @raise [KeySourceError] if key retrieval failed.
#
sub refresh_keys
{
    my ($self) = @_;
    $self->{allow_refresh_at} = time()
      unless( exists $self->{allow_refresh_at} );

    if ( time() < $self->{allow_refresh_at} )
    {
        print STDERR 'cache hit', $/ if $ENV{TESTING} && $ENV{VERBOSE};
        return $self->{current_keys};
    }
    print STDERR 'cache miss', $/ if $ENV{TESTING} && $ENV{VERBOSE};

    my $response = $self->{ua}->get( $self->{uri} );

    my ( $success, $status, $reason, $content );
    if ( ref($response) eq 'HASH' )
    {
        $success = $response->{success};
        $status  = $response->{status};
        $reason  = $response->{reason};
        $content = $response->{content};
    }
    else
    {
        $success = $response->is_success;
        $status  = $response->code;
        $reason  = $response->message;
        $content = $response->decoded_content;
    }

    die( "KeySourceError: Unable to retrieve data from $self->{uri}: $status $reason" )
        unless $success;

    $self->{last_response} = $response;
    my $data = eval { $coder->decode($content) };
    die("KeySourceError: Unable to parse JSON: $@") if $@;

    $self->{current_keys} = [ $self->interpret_json($data) ];

    $self->{allow_refresh_at} = time() + $self->{retry_interval};

    return $self->{current_keys};
}

sub interpret_json
{
    my ( $self, $data ) = @_;
    return ();
}

1;

package Google::Auth::IDTokens::X509CertHttpKeySource;
use base 'Google::Auth::IDTokens::HttpKeySource';
##
# A key source that downloads X509 certificates.
# Used by the legacy OAuth V1 public certs endpoint.
#

##
# Create a key source that downloads X509 certificates.
#
# @param uri [String,URI] The URI from which to download keys.
# @param algorithm [String] The algorithm to use for signature
#     verification. Defaults to "`RS256`".
# @param retry_interval [Integer,nil] Override the retry interval in
#     seconds. This is the minimum time between retries of failed key
#     downloads.
#
sub new
{
    my ( $class, $params ) = @_;
    $class = ref $class if ref $class;

    die "missing required parameters"
        unless exists $params->{uri} && $params->{uri};

    $params->{retry_interval} //= 30;

    my $self = $class->SUPER::new($params);
    $self->{algorithm} = $params->{algorithm} || 'RS256';
    return $self;
}

sub interpret_json
{
    my ( $self, $data ) = @_;
    return map {
        Google::Auth::IDTokens::KeyInfo->new(
            {
                id        => $_,
                key       => Google::Auth::load_pubkey_from_x509_cert( $data->{$_} ),
                algorithm => $self->{algorithm}
            }
        );
    } sort keys %$data;
}

package Google::Auth::IDTokens::JwkHttpKeySource;
use base 'Google::Auth::IDTokens::HttpKeySource';
use Carp;
##
# A key source that downloads a JWK set.
#
##
# Create a key source that downloads a JWT Set.
#
# @param uri [String,URI] The URI from which to download keys.
# @param retry_interval [Integer,nil] Override the retry interval in
#     seconds. This is the minimum time between retries of failed key
#     downloads.
#
sub new
{
    my ( $self, $params ) = @_;
    my $class = ref $self ? ref $self : $self;

    die "uri is a required parameter$/" . Data::Dumper::Dumper($params)
        unless exists( $params->{uri} );
    $class->SUPER::new($params);
}

sub interpret_json
{
    my ( $self, $data ) = @_;
    confess 'data is a required argument' unless $data;
    my $jwks = Google::Auth::IDTokens::KeyInfo->from_jwk_set($data);
    return @$jwks;
}

##
# The URI from which to download keys.
# @return [Array<KeyInfo>]
#
sub uri { return $_[0]->SUPER->uri }

package Google::Auth::IDTokens::AggregateKeySource;
##
# A key source that aggregates other key sources. This means it will
# aggregate the keys provided by its constituent sources. Additionally,
# when asked to refresh, it will refresh all its constituent sources.
#
##
# Create a key source that aggregates other key sources.
#
# @param sources [Array<key source>] The key sources to aggregate.
#
sub new
{
    my ( $class, $params ) = @_;
    die "sources is a required parameter$/" . Data::Dumper::Dumper($params)
        unless exists $params->{sources} && $params->{sources};

    $class = ref $class if ref $class;
    my $self = bless { sources => [ @{ $params->{sources} } ] }, $class;
    return $self;
}

##
# Return the current keys, without attempting to refresh.
#
# @return [Array<KeyInfo>]
#
sub current_keys
{
    my ($self) = @_;
    my @current_keys_set;
    foreach my $source ( @{ $self->{sources} } )
    {
        push( @current_keys_set, $source->current_keys );
    }
    return @current_keys_set;
}

##
# Attempt to refresh keys and return the new keys.
#
# @return [Array<KeyInfo>]
# @raise [KeySourceError] if key retrieval failed.
#
sub refresh_keys
{
    my ($self) = @_;
    my @current_keys_set;
    foreach my $source ( @{ $self->{sources} } )
    {
        eval { $source->refresh_keys(); };
        die "KeySourceError: $@" if $@;
        push( @current_keys_set, $source->current_keys );
    }
    return @current_keys_set;
}
