use warnings;
use strict;
use Test::More;

BEGIN { use_ok('Lemonldap::NG::Common::EmailTransport') }

my %base = (
    SMTPServer   => 'smtp.example.com',
    SMTPPort     => 587,
    SMTPAuthUser => 'dwho',
    SMTPAuthPass => 'dwho',
);

# Email::Sender provides sasl_authenticator since 1.300032 only, and
# Authen::SASL is an optional dependency
my $saslSupported = Email::Sender::Transport::SMTP->can('sasl_authenticator')
  && eval { require Authen::SASL; 1 };

# No SMTP server -> no transport (local sendmail is used)
is( Lemonldap::NG::Common::EmailTransport->new( {} ),
    undef, 'No transport without SMTPServer' );

# Default: credentials are given to Net::SMTP which chooses the mechanism
my $transport = Lemonldap::NG::Common::EmailTransport->new( {%base} );
is( $transport->sasl_username, 'dwho', 'sasl_username is set' );
is( $transport->sasl_password, 'dwho', 'sasl_password is set' );

# SMTPAuthMech is ignored when no user is set
$transport = Lemonldap::NG::Common::EmailTransport->new(
    { %base, SMTPAuthUser => '', SMTPAuthMech => 'PLAIN' } );
ok( !$transport->sasl_username, 'No sasl_username without SMTPAuthUser' );

SKIP: {
    skip 'Email::Sender or Authen::SASL is too old to select the mechanism', 7
      unless $saslSupported;

    $transport = Lemonldap::NG::Common::EmailTransport->new( {%base} );
    ok( !$transport->sasl_authenticator, 'No SASL authenticator by default' );

    # SMTPAuthMech: an Authen::SASL object restricted to the wanted
    # mechanism(s) is used instead
    $transport = Lemonldap::NG::Common::EmailTransport->new(
        { %base, SMTPAuthMech => 'PLAIN LOGIN CRAM-MD5' } );
    ok( !$transport->sasl_username, 'sasl_username is not set' );
    my $sasl = $transport->sasl_authenticator;
    ok( $sasl, 'SASL authenticator is set' );
    is( $sasl->mechanism, 'PLAIN LOGIN CRAM-MD5', 'Mechanisms are restricted' );

    # Only the wanted mechanism is used
    $transport = Lemonldap::NG::Common::EmailTransport->new(
        { %base, SMTPAuthMech => 'PLAIN' } );
    my $client =
      $transport->sasl_authenticator->client_new( 'smtp', 'smtp.example.com' );
    is( $client->mechanism, 'PLAIN', 'Chosen mechanism' );

    $transport = Lemonldap::NG::Common::EmailTransport->new(
        { %base, SMTPAuthUser => '', SMTPAuthMech => 'PLAIN' } );
    ok( !$transport->sasl_authenticator,
        'No SASL object without SMTPAuthUser' );

    my ( $res, $msg ) = Lemonldap::NG::Common::EmailTransport->configTest(
        { %base, SMTPAuthMech => 'PLAIN' } );
    ok( !$msg, 'No warning in configTest' ) or diag($msg);
}

done_testing();
