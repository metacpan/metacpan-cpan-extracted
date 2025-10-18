use Test::More tests => 5;

BEGIN { use_ok('Lemonldap::NG::Common::Util::Crypto') }
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::X509;

# Use small key size to avoid burning too much CPU
our $key_size = 1024;

subtest "Check genRsaKey" => sub {
    my ( $result, $checkpriv, $checkpub );
    $result    = Lemonldap::NG::Common::Util::Crypto::genRsaKey($key_size);
    $checkpriv = Crypt::OpenSSL::RSA->new_private_key( $result->{private} );
    $checkpub  = Crypt::OpenSSL::RSA->new_public_key( $result->{public} );
    is( $checkpriv->size * 8, $key_size, "Correct key size" );
    is(
        $checkpriv->get_public_key_string(),
        $checkpub->get_public_key_string(),
        'Public key matches private key'
    );
    ok( $result->{hash}, "Hash is non empty" );

    my $result =
      Lemonldap::NG::Common::Util::Crypto::genRsaKey( $key_size, "mytestkey" );
  SKIP: {
        skip "Crypt::OpenSSL::RSA doesn't support loading key with passphrase"
          if $Crypt::OpenSSL::RSA::VERSION < 0.33;
        $checkpriv = Crypt::OpenSSL::RSA->new_private_key( $result->{private},
            "mytestkey" );
        $checkpub = Crypt::OpenSSL::RSA->new_public_key( $result->{public} );
        is( $checkpriv->size * 8, $key_size, "Correct key size" );
        is(
            $checkpriv->get_public_key_string(),
            $checkpub->get_public_key_string(),
            'Public key matches private key'
        );
        ok( $result->{hash}, "Hash is non empty" );
    }
};

subtest "Check genCertKey" => sub {
    my ( $result, $checkpriv, $checkpub, $checkcert );
    $result    = Lemonldap::NG::Common::Util::Crypto::genCertKey($key_size);
    $checkpriv = Crypt::OpenSSL::RSA->new_private_key( $result->{private} );
    $checkcert = Crypt::OpenSSL::X509->new_from_string( $result->{public},
        Crypt::OpenSSL::X509::FORMAT_PEM );
    $checkpub = Crypt::OpenSSL::RSA->new_public_key( $checkcert->pubkey() );
    is( $checkpriv->size * 8, $key_size, "Correct key size" );
    is(
        $checkpriv->get_public_key_string(),
        $checkpub->get_public_key_string(),
        'Public key matches private key'
    );
    is( $checkcert->subject(), "CN=localhost", "Correct subject" );
    ok( $result->{hash}, "Hash is non empty" );

  SKIP: {
        skip "Crypt::OpenSSL::RSA doesn't support loading key with passphrase"
          if $Crypt::OpenSSL::RSA::VERSION < 0.33;
        my $result = Lemonldap::NG::Common::Util::Crypto::genCertKey( $key_size,
            "mytestkey" );
        $checkpriv = Crypt::OpenSSL::RSA->new_private_key( $result->{private},
            "mytestkey" );
        $checkcert = Crypt::OpenSSL::X509->new_from_string( $result->{public},
            Crypt::OpenSSL::X509::FORMAT_PEM );
        $checkpub = Crypt::OpenSSL::RSA->new_public_key( $checkcert->pubkey() );
        is( $checkpriv->size * 8, $key_size, "Correct key size" );
        is(
            $checkpriv->get_public_key_string(),
            $checkpub->get_public_key_string(),
            'Public key matches private key'
        );
        is( $checkcert->subject(), "CN=localhost", "Correct subject" );
        ok( $result->{hash}, "Hash is non empty" );
    }

    my $result =
      Lemonldap::NG::Common::Util::Crypto::genCertKey( $key_size, undef,
        "example.com" );
    $checkpriv = Crypt::OpenSSL::RSA->new_private_key( $result->{private} );
    $checkcert = Crypt::OpenSSL::X509->new_from_string( $result->{public},
        Crypt::OpenSSL::X509::FORMAT_PEM );
    $checkpub = Crypt::OpenSSL::RSA->new_public_key( $checkcert->pubkey() );
    is( $checkpriv->size * 8, $key_size, "Correct key size" );
    is(
        $checkpriv->get_public_key_string(),
        $checkpub->get_public_key_string(),
        'Public key matches private key'
    );
    is( $checkcert->subject(), "CN=example.com", "Correct subject" );
    ok( $result->{hash}, "Hash is non empty" );
};

SKIP: {
    eval { require Crypt::PK::ECC };
    skip "Crypt::PK::ECC missing", 2 if $@;
    subtest "Check genEcKey" => sub {

        my ( $result, $checkpriv, $checkpub );

        $result = Lemonldap::NG::Common::Util::Crypto::genEcKey('prime256v1');
        $checkpriv = Crypt::PK::ECC->new( \$result->{private} );
        $checkpub  = Crypt::PK::ECC->new( \$result->{public} );
        is(
            $checkpriv->export_key_pem('public'),
            $checkpub->export_key_pem('public'),
            "Public and private keys match"
        );
        ok( $result->{hash}, "Hash is non empty" );
    };

  SKIP: {
        skip "Net::SSLeay too old", 1 if $Net::SSLeay::VERSION < 1.75;
        subtest "Check genEcCertKey" => sub {

            my ( $result, $checkpriv, $checkpub );

            $result =
              Lemonldap::NG::Common::Util::Crypto::genEcCertKey('prime256v1');
            $checkpriv = Crypt::PK::ECC->new( \$result->{private} );
            $checkcert =
              Crypt::OpenSSL::X509->new_from_string( $result->{public},
                Crypt::OpenSSL::X509::FORMAT_PEM );
            $checkpub = Crypt::PK::ECC->new( \( $checkcert->pubkey() ) );
            is(
                $checkpriv->export_key_pem('public'),
                $checkpub->export_key_pem('public'),
                "Public and private keys match"
            );
            ok( $result->{hash}, "Hash is non empty" );
            is( $checkcert->subject(), "CN=localhost", "Correct subject" );

            $result =
              Lemonldap::NG::Common::Util::Crypto::genEcCertKey( 'prime256v1',
                "mytestkey" );
            $checkpriv =
              Crypt::PK::ECC->new( \$result->{private}, "mytestkey" );
            $checkcert =
              Crypt::OpenSSL::X509->new_from_string( $result->{public},
                Crypt::OpenSSL::X509::FORMAT_PEM );
            $checkpub = Crypt::PK::ECC->new( \( $checkcert->pubkey() ) );
            is(
                $checkpriv->export_key_pem('public'),
                $checkpub->export_key_pem('public'),
                'Public key matches private key'
            );
            is( $checkcert->subject(), "CN=localhost", "Correct subject" );
            ok( $result->{hash}, "Hash is non empty" );
        };
    }
}

genCertKey
