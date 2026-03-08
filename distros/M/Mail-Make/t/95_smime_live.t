#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - t/95_smime_live.t
## Live S/MIME signing and encryption tests — AUTHOR USE ONLY.
##
## Sends real signed and/or encrypted emails via a real SMTP server and
## verifies the message is accepted.  Visual inspection in a S/MIME-capable
## mail client (Thunderbird, Outlook, etc.) is required to confirm that:
##   - multipart/signed messages verify cleanly
##   - enveloped messages decrypt correctly
##   - sign+encrypt messages do both
##
## Required: SMTP configuration (same as smtpsend_live.t):
##   MM_SMTP_FROM, MM_SMTP_TO  (or [smtp] section in ~/.mailmakerc)
##
## Required: S/MIME configuration:
##   MM_SMIME_CERT      Path to signer certificate PEM file
##   MM_SMIME_KEY       Path to signer private key PEM file
##   MM_SMIME_CA        Path to CA certificate PEM file (optional but recommended)
##   MM_SMIME_REC_CERT  Path to recipient certificate PEM file
##                      Defaults to MM_SMIME_CERT when omitted (self-send)
##
## ~/.mailmakerc: optional [smime] section:
##   [smime]
##   cert     = /some/path/smime-jacques.cert.pem
##   key      = /some/path/smime-jacques.key.pem
##   ca_cert  = /some/path/dev-rootCA.crt
##   rec_cert = /some/path/smime-jacques.cert.pem
##
## Run:
##   MM_RC=dev/mailmake_rc.pl AUTHOR_TESTING=1 prove -lv t/95_smime_live.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
};

use strict;
use warnings;

# NOTE: Load configuration
sub _load_rc
{
    my %cfg;
    my $rc = $ENV{MM_RC} || do{ ( $ENV{HOME} // '' ) . '/.mailmakerc' };
    return( %cfg ) unless( -f $rc );
    open( my $fh, '<', $rc ) or return( %cfg );
    my $section = '';
    while( my $line = <$fh> )
    {
        chomp( $line );
        $line =~ s/\s*#.*$//;
        next unless( length( $line ) );
        if( $line =~ /^\[(\w+)\]$/ )
        {
            $section = lc( $1 );
            next;
        }
        if( $line =~ /^(\w+)\s*=\s*(.+)$/ )
        {
            $cfg{ $section . '.' . lc( $1 ) } = $2;
        }
    }
    close( $fh );
    return( %cfg );
}

my %rc = _load_rc();

# SMTP config
my $smtp_host = $ENV{MM_SMTP_HOST} // $rc{'smtp.host'} // 'localhost';
my $smtp_port = $ENV{MM_SMTP_PORT} // $rc{'smtp.port'} // 25;
my $smtp_from = $ENV{MM_SMTP_FROM} // $rc{'smtp.from'};
my $smtp_to   = $ENV{MM_SMTP_TO}   // $rc{'smtp.to'};
my $smtp_user = $ENV{MM_SMTP_USER} // $rc{'smtp.user'};
my $smtp_pass = $ENV{MM_SMTP_PASS} // $rc{'smtp.password'};
my $smtp_ssl  = $ENV{MM_SMTP_SSL}  // $rc{'smtp.ssl'};
my $smtp_tls  = $ENV{MM_SMTP_TLS}  // $rc{'smtp.starttls'};

# S/MIME config
my $smime_cert     = $ENV{MM_SMIME_CERT}     // $rc{'smime.cert'};
my $smime_key      = $ENV{MM_SMIME_KEY}      // $rc{'smime.key'};
my $smime_ca       = $ENV{MM_SMIME_CA}       // $rc{'smime.ca_cert'};
my $smime_rec_cert = $ENV{MM_SMIME_REC_CERT} // $rc{'smime.rec_cert'} // $smime_cert;

# NOTE: Skip conditions
plan( tests => 7 );

use_ok( 'Mail::Make' );
use_ok( 'Mail::Make::SMIME' );

my $can_sign = ( defined( $smime_cert ) && length( $smime_cert )
              && defined( $smime_key  ) && length( $smime_key  )
              && -r $smime_cert && -r $smime_key );

my $can_encrypt = ( defined( $smime_rec_cert ) && length( $smime_rec_cert )
                 && -r $smime_rec_cert );

my $can_send = ( defined( $smtp_from ) && length( $smtp_from )
              && defined( $smtp_to   ) && length( $smtp_to   ) );

# NOTE: Helper: build a base Mail::Make object
sub _make_base_mail
{
    my( $subject_suffix, $body ) = @_;
    my $mail = Mail::Make->new;
    $mail->from( $smtp_from );
    $mail->to( $smtp_to );
    $mail->subject( "[Mail::Make] Live S/MIME test \x{2014} $subject_suffix" );
    $mail->plain( $body );
    return( $mail );
}

# NOTE: Helper: send and check
sub _send_and_check
{
    my( $mail_obj, $label ) = @_;
    my %send_opts = (
        Host => $smtp_host,
        Port => $smtp_port,
    );
    $send_opts{Username} = $smtp_user if( defined( $smtp_user ) );
    $send_opts{Password} = $smtp_pass if( defined( $smtp_pass ) );
    $send_opts{SSL}      = 1          if( $smtp_ssl );
    $send_opts{StartTLS} = 1          if( $smtp_tls );

    my $result = $mail_obj->smtpsend( %send_opts );
    ok( $result, "$label accepted by server" )
        or diag( "smtpsend error: " . ( $mail_obj->error // 'unknown' ) );
}

# NOTE: Subtest 1: sign only
subtest 'live: smime_sign — multipart/signed delivered' => sub
{
    plan( tests => 2 );

    SKIP:
    {
        skip( 'S/MIME signing credentials not configured', 2 )
            unless( $can_sign && $can_send );

        my $mail = _make_base_mail(
            'sign only',
            "This message is signed with a detached S/MIME signature.\n\n"
            . "Your mail client should show a valid signature indicator.\n"
        );

        my $signed;
        eval
        {
            $signed = $mail->smime_sign(
                Cert   => $smime_cert,
                Key    => $smime_key,
                ( defined( $smime_ca ) ? ( CACert => $smime_ca ) : () ),
            );
        };
        ok( !$@ && defined( $signed ), 'smime_sign() succeeded' )
            or diag( "smime_sign error: " . ( $@ || $mail->error // '' ) );

        _send_and_check( $signed, 'signed message' ) if( defined( $signed ) );
    }
};

# NOTE: Subtest 2: encrypt only
subtest 'live: smime_encrypt — enveloped message delivered' => sub
{
    plan( tests => 2 );

    SKIP:
    {
        skip( 'S/MIME encryption credentials not configured', 2 )
            unless( $can_encrypt && $can_send );

        my $mail = _make_base_mail(
            'encrypt only',
            "This message is encrypted with S/MIME.\n\n"
            . "Your mail client should decrypt it automatically.\n"
        );

        my $encrypted;
        eval
        {
            $encrypted = $mail->smime_encrypt(
                RecipientCert => $smime_rec_cert,
            );
        };
        ok( !$@ && defined( $encrypted ), 'smime_encrypt() succeeded' )
            or diag( "smime_encrypt error: " . ( $@ || $mail->error // '' ) );

        _send_and_check( $encrypted, 'encrypted message' ) if( defined( $encrypted ) );
    }
};

# NOTE: Subtest 3: sign + encrypt
subtest 'live: smime_sign_encrypt — sign+encrypt delivered' => sub
{
    plan( tests => 2 );

    SKIP:
    {
        skip( 'S/MIME sign+encrypt credentials not configured', 2 )
            unless( $can_sign && $can_encrypt && $can_send );

        my $mail = _make_base_mail(
            'sign + encrypt',
            "This message is signed and encrypted with S/MIME.\n\n"
            . "Your mail client should show: decrypted + valid signature.\n"
        );

        my $result;
        eval
        {
            $result = $mail->smime_sign_encrypt(
                Cert          => $smime_cert,
                Key           => $smime_key,
                RecipientCert => $smime_rec_cert,
                ( defined( $smime_ca ) ? ( CACert => $smime_ca ) : () ),
            );
        };
        ok( !$@ && defined( $result ), 'smime_sign_encrypt() succeeded' )
            or diag( "smime_sign_encrypt error: " . ( $@ || $mail->error // '' ) );

        _send_and_check( $result, 'sign+encrypt message' ) if( defined( $result ) );
    }
};

# NOTE: Subtest 4: structure — smime_sign produces multipart/signed
subtest 'structure: smime_sign produces multipart/signed entity' => sub
{
    plan( tests => 3 );

    SKIP:
    {
        skip( 'S/MIME signing credentials not configured', 3 )
            unless( $can_sign );

        my $mail = _make_base_mail( 'structure check', "Structure test.\n" );

        my $signed;
        eval
        {
            $signed = $mail->smime_sign(
                Cert   => $smime_cert,
                Key    => $smime_key,
                ( defined( $smime_ca ) ? ( CACert => $smime_ca ) : () ),
            );
        };
        ok( !$@ && defined( $signed ), 'smime_sign() succeeded' )
            or diag( "smime_sign error: " . ( $@ || $mail->error // '' ) );

        my $entity = defined( $signed ) ? $signed->as_entity : undef;
        ok( defined( $entity ), 'as_entity() returns defined value' );

        if( defined( $entity ) )
        {
            my $ct = $entity->headers->get( 'Content-Type' ) // '';
            like( $ct, qr{multipart/signed}i, 'Content-Type is multipart/signed' );
        }
        else
        {
            fail( 'Content-Type is multipart/signed' );
        }
    }
};

# NOTE: Subtest 5: structure — smime_encrypt produces pkcs7-mime
subtest 'structure: smime_encrypt produces application/pkcs7-mime' => sub
{
    plan( tests => 3 );

    SKIP:
    {
        skip( 'S/MIME encryption credentials not configured', 3 )
            unless( $can_encrypt );

        my $mail = _make_base_mail( 'encrypt structure', "Encrypt structure test.\n" );

        my $encrypted;
        eval
        {
            $encrypted = $mail->smime_encrypt(
                RecipientCert => $smime_rec_cert,
            );
        };
        ok( !$@ && defined( $encrypted ), 'smime_encrypt() succeeded' )
            or diag( "smime_encrypt error: " . ( $@ || $mail->error // '' ) );

        my $entity = defined( $encrypted ) ? $encrypted->as_entity : undef;
        ok( defined( $entity ), 'as_entity() returns defined value' );

        if( defined( $entity ) )
        {
            my $ct = $entity->headers->get( 'Content-Type' ) // '';
            like( $ct, qr{application/pkcs7-mime}i, 'Content-Type is application/pkcs7-mime' );
        }
        else
        {
            fail( 'Content-Type is application/pkcs7-mime' );
        }
    }
};

done_testing();

__END__
