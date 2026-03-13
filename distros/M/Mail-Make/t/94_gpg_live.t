#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - t/94_gpg_live.t
## Live GPG signing and encryption tests - AUTHOR USE ONLY.
##
## Sends real signed and/or encrypted emails via a real SMTP server and
## verifies the message is accepted. Visual inspection in a GPG-capable
## mail client (Thunderbird, Mutt, etc.) is required to confirm that:
##   - multipart/signed messages verify cleanly
##   - multipart/encrypted messages decrypt correctly
##   - sign+encrypt messages do both
##
## Required: SMTP configuration (same as smtpsend_live.t):
##   MM_SMTP_FROM, MM_SMTP_TO  (or [smtp] section in ~/.mailmakerc)
##
## Required: GPG configuration:
##   MM_GPG_KEY_ID      Signing key fingerprint or ID (e.g. 35ADBC3A...)
##   MM_GPG_PASSPHRASE  Passphrase for the key (omit to use gpg-agent)
##   MM_GPG_RECIPIENT   Recipient address for encryption tests
##                      Defaults to MM_SMTP_TO when omitted
##   MM_GPG_BIN         Full path to gpg binary (optional; default: gpg2/gpg)
##
## ~/.mailmakerc: optional [gpg] section:
##   [gpg]
##   key_id     = 35ADBC3AF8355E845139D8965F3C0261CDB2E752
##   passphrase = secret
##   recipient  = jack@deguest.jp
##   bin        = /usr/bin/gpg2
##
## Run:
##   MM_RC=dev/mailmake_rc.pl AUTHOR_TESTING=1 prove -lv t/94_gpg_live.t
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

# SMTP config (shared with smtpsend)
my $smtp_host     = $ENV{MM_SMTP_HOST}     // $rc{'smtp.host'}     // 'localhost';
my $smtp_port     = $ENV{MM_SMTP_PORT}     // $rc{'smtp.port'}     // 25;
my $smtp_from     = $ENV{MM_SMTP_FROM}     // $rc{'smtp.from'};
my $smtp_to       = $ENV{MM_SMTP_TO}       // $rc{'smtp.to'};
my $smtp_hello    = $ENV{MM_SMTP_HELLO}    // $rc{'smtp.hello'}    // do { require Sys::Hostname; Sys::Hostname::hostname() };
my $smtp_username = $ENV{MM_SMTP_USERNAME} // $rc{'smtp.username'};
my $smtp_password = $ENV{MM_SMTP_PASSWORD} // $rc{'smtp.password'};
my $smtp_starttls = $ENV{MM_SMTP_STARTTLS} // $rc{'smtp.starttls'} // 0;
my $smtp_ssl      = $ENV{MM_SMTP_SSL}      // $rc{'smtp.ssl'}      // 0;
my $smtp_debug    = $ENV{MM_SMTP_DEBUG}    // $rc{'smtp.debug'}    // 0;

# GPG config
my $gpg_key_id     = $ENV{MM_GPG_KEY_ID}     // $rc{'gpg.key_id'};
my $gpg_passphrase = $ENV{MM_GPG_PASSPHRASE} // $rc{'gpg.passphrase'};
my $gpg_recipient  = $ENV{MM_GPG_RECIPIENT}  // $rc{'gpg.recipient'} // $smtp_to;
my $gpg_bin        = $ENV{MM_GPG_BIN}        // $rc{'gpg.bin'};

# NOTE: Dependency and configuration checks
# diag( "\$smtp_from is '", ( $smtp_from // 'undef' ), "' and \$smtp_to is '", ( $smtp_to // 'undef' ), "'" );
unless( defined( $smtp_from ) && length( $smtp_from ) &&
        defined( $smtp_to   ) && length( $smtp_to   ) )
{
    plan( skip_all =>
        'Live GPG test skipped: set MM_SMTP_FROM + MM_SMTP_TO ' .
        'or configure [smtp] from/to in ~/.mailmakerc' );
}

eval{ require IPC::Run }
    or plan( skip_all => 'IPC::Run not installed - required for GPG operations' );

eval{ require File::Which }
    or plan( skip_all => 'File::Which not installed - required to locate gpg binary' );

# Locate gpg binary early so we can skip cleanly if absent
my $gpg_bin_found;
if( defined( $gpg_bin ) && length( $gpg_bin ) )
{
    $gpg_bin_found = -x $gpg_bin ? $gpg_bin : undef;
}

unless( defined( $gpg_bin_found ) && length( $gpg_bin_found ) )
{
    for my $candidate ( qw( gpg2 gpg ) )
    {
        my $p = File::Which::which( $candidate );
        if( defined( $p ) && length( $p ) )
        {
            $gpg_bin_found = $p;
            last;
        }
    }
}
unless( defined( $gpg_bin_found ) )
{
    plan( skip_all => 'gpg binary not found in PATH - install GnuPG or set MM_GPG_BIN' );
}

# Signing tests require a key ID
my $can_sign = ( defined( $gpg_key_id ) && length( $gpg_key_id ) );

# NOTE: Common helpers
my %smtp_common = (
    Host  => $smtp_host,
    Port  => $smtp_port,
    Hello => $smtp_hello,
    Debug => $smtp_debug,
);
$smtp_common{StartTLS} = 1            if( $smtp_starttls );
$smtp_common{SSL}      = 1            if( $smtp_ssl );
$smtp_common{Username} = $smtp_username if( defined( $smtp_username ) && length( $smtp_username ) );
$smtp_common{Password} = $smtp_password if( defined( $smtp_password ) && length( $smtp_password ) );

my %gpg_common = ( GpgBin => $gpg_bin_found );

sub _make_base_mail
{
    my( $subject, $body ) = @_;
    require Mail::Make;
    return( Mail::Make->new
        ->from(    $smtp_from )
        ->to(      $smtp_to )
        ->subject( $subject )
        ->plain(   $body ) );
}

sub _send_and_check
{
    my( $mail, $label ) = @_;
    my $rv = $mail->smtpsend( %smtp_common );
    if( !defined( $rv ) )
    {
        diag( 'smtpsend error: ' . ( $mail->error // 'unknown' ) );
    }
    ok( defined( $rv ), "$label accepted by server" );
    return( defined( $rv ) );
}

# NOTE: Tests
use_ok( 'Mail::Make' );
use_ok( 'Mail::Make::GPG' );

# NOTE: Plain-signed message (multipart/signed, RFC 3156 §5)
SKIP:
{
    skip( 'MM_GPG_KEY_ID not set - signing tests skipped', 2 ) unless( $can_sign );

    subtest 'live: gpg_sign - multipart/signed delivered' => sub
    {
        plan( tests => 2 );
        my $mail = _make_base_mail(
            '[Mail::Make] Live GPG test - sign only',
            "This message is signed with a detached OpenPGP signature.\n\n" .
            "Your mail client should show a valid signature indicator.\n",
        );

        my %sign_opts = ( %gpg_common, KeyId => $gpg_key_id );
        $sign_opts{Passphrase} = $gpg_passphrase if( defined( $gpg_passphrase ) );

        local $@;
        my $signed = eval { $mail->gpg_sign( %sign_opts ) };
        if( $@ || !defined( $signed ) )
        {
            diag( 'gpg_sign error: ' . ( $@ || $mail->error // 'unknown' ) );
            ok( 0, 'gpg_sign() succeeded' );
            ok( 0, 'signed message accepted by server' );
            return;
        }
        ok( 1, 'gpg_sign() succeeded' );
        _send_and_check( $signed, 'signed message' );
    };

    # NOTE: SHA-512 digest variant
    subtest 'live: gpg_sign - SHA-512 digest' => sub
    {
        plan( tests => 2 );
        my $mail = _make_base_mail(
            '[Mail::Make] Live GPG test - sign SHA-512',
            "Signed with SHA-512 digest algorithm.\n",
        );

        my %sign_opts = ( %gpg_common, KeyId => $gpg_key_id, Digest => 'SHA512' );
        $sign_opts{Passphrase} = $gpg_passphrase if( defined( $gpg_passphrase ) );

        local $@;
        my $signed = eval { $mail->gpg_sign( %sign_opts ) };
        if( $@ || !defined( $signed ) )
        {
            diag( 'gpg_sign SHA-512 error: ' . ( $@ || $mail->error // 'unknown' ) );
            ok( 0, 'gpg_sign() SHA-512 succeeded' );
            ok( 0, 'SHA-512 signed message accepted by server' );
            return;
        }
        ok( 1, 'gpg_sign() SHA-512 succeeded' );
        _send_and_check( $signed, 'SHA-512 signed message' );
    };
}

# NOTE: Encrypted message (multipart/encrypted, RFC 3156 §4)
subtest 'live: gpg_encrypt - multipart/encrypted delivered' => sub
{
    plan( tests => 2 );
    my $mail = _make_base_mail(
        '[Mail::Make] Live GPG test - encrypt only',
        "This message is encrypted with OpenPGP.\n\n" .
        "Only the holder of the private key for $gpg_recipient can read this.\n",
    );

    local $@;
    my $encrypted = eval
    {
        $mail->gpg_encrypt(
            %gpg_common,
            Recipients => [ $gpg_recipient ],
        );
    };
    if( $@ || !defined( $encrypted ) )
    {
        diag( 'gpg_encrypt error: ' . ( $@ || $mail->error // 'unknown' ) );
        ok( 0, 'gpg_encrypt() succeeded' );
        ok( 0, 'encrypted message accepted by server' );
        return;
    }
    ok( 1, 'gpg_encrypt() succeeded' );
    _send_and_check( $encrypted, 'encrypted message' );
};

# NOTE: Sign then encrypt
SKIP:
{
    skip( 'MM_GPG_KEY_ID not set - sign+encrypt test skipped', 1 ) unless( $can_sign );

    subtest 'live: gpg_sign_encrypt - signed and encrypted delivered' => sub
    {
        plan( tests => 2 );
        my $mail = _make_base_mail(
            '[Mail::Make] Live GPG test - sign + encrypt',
            "This message is signed and encrypted with OpenPGP.\n\n" .
            "Only $gpg_recipient can decrypt it, and the signature proves\n" .
            "it came from the holder of key $gpg_key_id.\n",
        );

        my %opts = (
            %gpg_common,
            KeyId      => $gpg_key_id,
            Recipients => [ $gpg_recipient ],
        );
        $opts{Passphrase} = $gpg_passphrase if( defined( $gpg_passphrase ) );

        local $@;
        my $result = eval { $mail->gpg_sign_encrypt( %opts ) };
        if( $@ || !defined( $result ) )
        {
            diag( 'gpg_sign_encrypt error: ' . ( $@ || $mail->error // 'unknown' ) );
            ok( 0, 'gpg_sign_encrypt() succeeded' );
            ok( 0, 'sign+encrypt message accepted by server' );
            return;
        }
        ok( 1, 'gpg_sign_encrypt() succeeded' );
        _send_and_check( $result, 'sign+encrypt message' );
    };
}

# NOTE: Structure check - no SMTP send, just verify MIME output
subtest 'structure: gpg_sign produces multipart/signed entity' => sub
{
    plan( tests => 3 );

    skip( 'MM_GPG_KEY_ID not set', 3 ) unless( $can_sign );

    my $mail = _make_base_mail(
        'Structure check - multipart/signed',
        "Testing MIME structure without sending.\n",
    );

    my %sign_opts = ( %gpg_common, KeyId => $gpg_key_id );
    $sign_opts{Passphrase} = $gpg_passphrase if( defined( $gpg_passphrase ) );

    local $@;
    my $signed = eval { $mail->gpg_sign( %sign_opts ) };
    if( $@ || !defined( $signed ) )
    {
        diag( 'gpg_sign error: ' . ( $@ || $mail->error // 'unknown' ) );
        ok( 0, 'gpg_sign() succeeded' ) for( 1..3 );
        return;
    }
    ok( 1, 'gpg_sign() succeeded' );

    my $entity = $signed->as_entity;
    ok( defined( $entity ), 'as_entity() returns defined value' );

    my $ct = $entity->headers->get( 'Content-Type' ) // '';
    like( $ct, qr{multipart/signed}i, 'Content-Type is multipart/signed' );
};

subtest 'structure: gpg_encrypt produces multipart/encrypted entity' => sub
{
    plan( tests => 3 );

    my $mail = _make_base_mail(
        'Structure check - multipart/encrypted',
        "Testing MIME structure without sending.\n",
    );

    local $@;
    my $encrypted = eval
    {
        $mail->gpg_encrypt(
            %gpg_common,
            Recipients => [ $gpg_recipient ],
        );
    };
    if( $@ || !defined( $encrypted ) )
    {
        diag( 'gpg_encrypt error: ' . ( $@ || $mail->error // 'unknown' ) );
        ok( 0, 'gpg_encrypt() succeeded' ) for( 1..3 );
        return;
    }
    ok( 1, 'gpg_encrypt() succeeded' );

    my $entity = $encrypted->as_entity;
    ok( defined( $entity ), 'as_entity() returns defined value' );

    my $ct = $entity->headers->get( 'Content-Type' ) // '';
    like( $ct, qr{multipart/encrypted}i, 'Content-Type is multipart/encrypted' );
};

done_testing();

__END__

=head1 NAME

t/94_gpg_live.t - Live OpenPGP signing and encryption tests for Mail::Make

=head1 SYNOPSIS

    # Minimal: encrypt only (no key ID needed, uses MM_SMTP_TO as recipient)
    MM_RC=dev/mailmake_rc.pl \
    AUTHOR_TESTING=1 \
    prove -lv t/94_gpg_live.t

    # Full: sign + encrypt
    MM_RC=dev/mailmake_rc.pl    \
    MM_GPG_KEY_ID=35ADBC3AF8355E845139D8965F3C0261CDB2E752 \
    MM_GPG_PASSPHRASE=secret    \
    MM_GPG_RECIPIENT=jack@deguest.jp \
    AUTHOR_TESTING=1            \
    prove -lv t/94_gpg_live.t

=head1 CONFIGURATION

SMTP options are identical to F<t/smtpsend_live.t>.

Add a C<[gpg]> section to F<~/.mailmakerc>:

    [gpg]
    key_id     = 35ADBC3AF8355E845139D8965F3C0261CDB2E752
    passphrase = secret
    recipient  = jack@deguest.jp
    bin        = /usr/bin/gpg2

=head1 TESTS

=over 4

=item 1. C<gpg_sign()> - multipart/signed, SHA-256

=item 2. C<gpg_sign()> - multipart/signed, SHA-512

=item 3. C<gpg_encrypt()> - multipart/encrypted

=item 4. C<gpg_sign_encrypt()> - signed + encrypted

=item 5. Structure check - multipart/signed Content-Type (no SMTP)

=item 6. Structure check - multipart/encrypted Content-Type (no SMTP)

=back

Tests 1, 2, 4, and 5 are skipped automatically when C<MM_GPG_KEY_ID> is not set.

=cut
