package Google::Auth::IDTokens::Verifier;

use strict;
use warnings;

use Moo;
use JSON::MaybeXS;
use MIME::Base64 qw(decode_base64);
use Scalar::Util qw(looks_like_number);

my %ALLOWED_JWT_ALGS = (
  RS256 => 1,
  ES256 => 1,
);

my %ALG_TO_KTY = (
  RS256 => 'RSA',
  ES256 => 'EC',
);

sub _is_finite_number {
  my ($val) = @_;
  return 0 if !defined $val || ref($val);
  return $val =~ /\A-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\z/ ? 1 : 0;
}
use Google::Auth;
use Google::Auth::IDTokens::KeySources;

has key_source => (
  is       => 'ro',
  required => 0,
);

has aud => (
  is       => 'ro',
  required => 0,
);

has azp => (
  is       => 'ro',
  required => 0,
);

has iss => (
  is       => 'ro',
  required => 0,
);

sub _decode_base64url {
  my ($s) = @_;
  $s =~ tr{-_}{+/};
  my $padding = length($s) % 4;
  if ($padding) {
    $s .= '=' x (4 - $padding);
  }
  return MIME::Base64::decode_base64($s);
}

sub verify {
  my ($self, $token, %options) = @_;

  $self = ref $self ? $self : $self->new();

  my $key_source = $options{key_source} // $self->key_source;
  my $aud        = $options{aud}        // $self->aud;
  my $azp        = $options{azp}        // $self->azp;
  my $iss        = $options{iss}        // $self->iss;
  my $clock_skew = $options{clock_skew} // 300;

  die 'KeySourceError: No key source provided' unless defined $key_source;

  my @parts = split /\./, $token;
  if (@parts != 3) {
    die 'VerificationError: Invalid JWT format';
  }
  my ($header_b64, $payload_b64, $signature_b64) = @parts;

  my $coder  = JSON::MaybeXS->new->utf8->allow_nonref;
  my $header = eval { $coder->decode(_decode_base64url($header_b64)) };
  if ($@) {
    die 'VerificationError: Failed to parse JWT header: ' . $@;
  }
  my $payload = eval { $coder->decode(_decode_base64url($payload_b64)) };
  if ($@) {
    die 'VerificationError: Failed to parse JWT payload: ' . $@;
  }

  my $alg = $header->{alg};
  if (!defined $alg || !$ALLOWED_JWT_ALGS{$alg}) {
    die 'VerificationError: Unsupported or missing alg claim in JWT header';
  }

  my $kid = $header->{kid};
  die 'VerificationError: Missing kid claim in JWT header' unless defined $kid;

  my $signature = _decode_base64url($signature_b64);
  my $message   = $header_b64 . '.' . $payload_b64;

  my $payload_verified;

  my $verify_with_keys = sub {
    my ($keys_ref) = @_;
    foreach my $key (@$keys_ref) {
      if ($key->id eq $kid) {
        if ( defined $key->algorithm
          && length $key->algorithm
          && $key->algorithm ne $alg)
        {
          next;
        }
        if ( $key->can('key_type')
          && defined $key->key_type
          && length $key->key_type)
        {
          my $expected_kty = $ALG_TO_KTY{$alg};
          if (defined $expected_kty && $key->key_type ne $expected_kty) {
            next;
          }
        }
        if (Google::Auth::verify_signature($key->key, $message, $signature)) {
          return 1;
        }
      }
    }
    return 0;
  };

  my $keys_ref = $key_source->current_keys;
  if ($verify_with_keys->($keys_ref)) {
    $payload_verified = 1;
  } else {
    my $refreshed_keys_ref = $key_source->refresh_keys;
    if ($verify_with_keys->($refreshed_keys_ref)) {
      $payload_verified = 1;
    }
  }

  unless ($payload_verified) {
    die 'SignatureError: Token signature verification failed';
  }

  my $now = $options{time_now} // time();
  if (!_is_finite_number($payload->{exp})) {
    die 'VerificationError: Missing or invalid exp claim';
  }
  if ($payload->{exp} < $now - $clock_skew) {
    die 'ExpiredTokenError: Token signature is expired';
  }
  if (exists $payload->{nbf}) {
    if (!_is_finite_number($payload->{nbf})
      || $payload->{nbf} > $now + $clock_skew)
    {
      die 'VerificationError: Token not yet valid';
    }
  }
  if (exists $payload->{iat}) {
    if (!_is_finite_number($payload->{iat})
      || $payload->{iat} > $now + $clock_skew)
    {
      die 'VerificationError: Token issued in the future';
    }
  }

  $payload->{azp} ||= $payload->{cid} if exists $payload->{cid};

  if (defined $aud) {
    my @expected_auds = ref $aud eq 'ARRAY' ? @$aud : ($aud);
    my $token_aud     = $payload->{aud};
    my @token_auds    = ref $token_aud eq 'ARRAY' ? @$token_aud : ($token_aud);

    my %expected_map = map { $_ => 1 } @expected_auds;
    my $aud_match    = 0;
    foreach my $t_aud (@token_auds) {
      if (exists $expected_map{$t_aud}) {
        $aud_match = 1;
        last;
      }
    }
    unless ($aud_match) {
      die 'AudienceMismatchError: Token aud mismatch: ' .
        join(', ', @token_auds);
    }
  }

  if (defined $azp) {
    my @expected_azps = ref $azp eq 'ARRAY' ? @$azp : ($azp);
    my $token_azp     = $payload->{azp};
    my @token_azps    = ref $token_azp eq 'ARRAY' ? @$token_azp : ($token_azp);

    my %expected_map = map { $_ => 1 } @expected_azps;
    my $azp_match    = 0;
    foreach my $t_azp (@token_azps) {
      if (exists $expected_map{$t_azp}) {
        $azp_match = 1;
        last;
      }
    }
    unless ($azp_match) {
      die 'AuthorizedPartyMismatchError: Token azp mismatch: ' .
        ($token_azp // '');
    }
  }

  if (defined $iss) {
    my @expected_isss = ref $iss eq 'ARRAY' ? @$iss : ($iss);
    my $token_iss     = $payload->{iss};

    my %expected_map = map { $_ => 1 } @expected_isss;
    unless (exists $expected_map{$token_iss}) {
      die 'IssuerMismatchError: Token iss mismatch: ' . ($token_iss // '');
    }
  }

  return $payload;
}

my $_oidc_verifier;

sub verify_oidc {
  my ($class, $token, %options) = @_;

  $_oidc_verifier //= Google::Auth::IDTokens::Verifier->new(
    key_source => Google::Auth::IDTokens::JwkHttpKeySource->new({
        uri => 'https://www.googleapis.com/oauth2/v3/certs'
      }
    ),
    iss => ['accounts.google.com', 'https://accounts.google.com']);

  return $_oidc_verifier->verify($token, %options);
}

my $_iap_verifier;

sub verify_iap {
  my ($class, $token, %options) = @_;

  $_iap_verifier //= Google::Auth::IDTokens::Verifier->new(
    key_source => Google::Auth::IDTokens::JwkHttpKeySource->new({
        uri => 'https://www.googleapis.com/iap/verify/public_key-jwk'
      }
    ),
    iss => 'https://cloud.google.com/iap'
  );

  return $_iap_verifier->verify($token, %options);
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Auth::IDTokens::Verifier - Cryptographic verifier for Google OIDC and IAP ID tokens (RS256/ES256)

=head1 SYNOPSIS

    use Google::Auth::IDTokens::Verifier;

    my $verifier = Google::Auth::IDTokens::Verifier->new(
        key_source => $key_source,
    );
    my $claims = $verifier->verify($jwt, aud => $expected_audience);

=head1 DESCRIPTION

Verifies Google-signed JWT ID tokens with strict algorithm allowlisting (RS256, ES256), key-algorithm binding, OpenSSL XS signature verification, and numeric exp/nbf/iat claim checks.

=head1 METHODS AND ATTRIBUTES

=over 4

=item * B<key_source>

=item * B<aud>

=item * B<azp>

=item * B<iss>

=item * B<verify>

=item * B<verify_oidc>

=item * B<verify_iap>

=back

=head1 SEE ALSO

L<Google::Auth>, L<Google::Auth::Credentials>

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2026 Google LLC and contributors.

Licensed under the Apache License, Version 2.0.

=cut
