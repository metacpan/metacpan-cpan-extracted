package Lemonldap::NG::Common::OpenIDConnect::Constants;

use strict;
use Exporter 'import';

our @EXPORT = (qw(
  BACKCHANNEL_EVENTSKEY
  PROFILE
  EMAIL
  ADDRESS
  PHONE
  DEFAULT_SCOPES
  COMPLEX_CLAIM
  ENC_ALG_SUPPORTED
  ENC_SUPPORTED
));

use constant BACKCHANNEL_EVENTSKEY =>
  'http://schemas.openid.net/event/backchannel-logout';

# OpenID Connect standard claims
use constant PROFILE => [
    qw/name family_name given_name middle_name nickname preferred_username
      profile picture website gender birthdate zoneinfo locale updated_at/
];
use constant EMAIL => [qw/email email_verified/];
use constant ADDRESS =>
  [qw/formatted street_address locality region postal_code country/];
use constant PHONE => [qw/phone_number phone_number_verified/];

use constant DEFAULT_SCOPES => {
    profile => PROFILE,
    email   => EMAIL,
    address => ADDRESS,
    phone   => PHONE,
};

use constant COMPLEX_CLAIM => {
    formatted      => "address",
    street_address => "address",
    locality       => "address",
    region         => "address",
    postal_code    => "address",
    country        => "address",
};

use constant ENC_ALG_SUPPORTED => [ qw(
      RSA-OAEP ECDH-ES RSA-OAEP-256
      ECDH-ES+A256KW
      ECDH-ES+A192KW
      ECDH-ES+A128KW
      RSA1_5
    )
];

# Unsupported: A128KW A192KW A256KW A128GCMKW A192GCMKW A256GCMKW PBES2-HS256+A128KW PBES2-HS384+A192KW PBES2-HS512+A256KW

use constant ENC_SUPPORTED => [ qw(
      A256CBC-HS512 A256GCM A192CBC-HS384 A192GCM A128CBC-HS256 A128GCM
    )
];

1;
