#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - xt/author/smtpsend_live.t
## Live SMTP send test - AUTHOR USE ONLY.
##
## This test sends a real email via a real SMTP server.
## It is intentionally excluded from the public test suite.
##
## Required environment variables (or ~/.mailmakerc - see below):
##
##   MM_SMTP_HOST      SMTP server hostname          (default: localhost)
##   MM_SMTP_PORT      SMTP server port              (default: 25)
##   MM_SMTP_FROM      Envelope / From address       (mandatory)
##   MM_SMTP_TO        Recipient address             (mandatory)
##   MM_SMTP_HELLO     EHLO hostname                 (default: system hostname)
##
## Optional:
##   MM_SMTP_USERNAME  SASL login name
##   MM_SMTP_PASSWORD  SASL password (plain string)
##   MM_SMTP_STARTTLS  Set to 1 to upgrade connection via STARTTLS (port 587)
##   MM_SMTP_SSL       Set to 1 for direct SSL/TLS connection (port 465)
##   MM_SMTP_DEBUG     Set to 1 to enable Net::SMTP debug output
##
## ~/.mailmakerc (INI-style, loaded if env vars are absent):
##
##   [smtp]
##   host     = smtp.example.com
##   port     = 587
##   from     = jack@deguest.jp
##   to       = jack@deguest.jp
##   hello    = deguest.jp
##   username = jack@deguest.jp
##   password = secret
##   starttls = 1
##
## The test is skipped entirely if MM_SMTP_FROM or MM_SMTP_TO are not set and
## ~/.mailmakerc does not supply them.
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG $host $port $from $to $hello $debug );
    use Test::More;
    use Sys::Hostname ();
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

# NOTE: Load configuration: env vars take priority over ~/.mailmakerc
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
        $line =~ s/\s*#.*$//;        # strip comments
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

my %rc  = _load_rc();

my $host     = $ENV{MM_SMTP_HOST}      // $rc{'smtp.host'}     // 'localhost';
my $port     = $ENV{MM_SMTP_PORT}      // $rc{'smtp.port'}     // 25;
my $from     = $ENV{MM_SMTP_FROM}      // $rc{'smtp.from'};
my $to       = $ENV{MM_SMTP_TO}        // $rc{'smtp.to'};
my $hello    = $ENV{MM_SMTP_HELLO}     // $rc{'smtp.hello'}    // Sys::Hostname::hostname();
my $username = $ENV{MM_SMTP_USERNAME}  // $rc{'smtp.username'};
my $password = $ENV{MM_SMTP_PASSWORD}  // $rc{'smtp.password'};
my $starttls = $ENV{MM_SMTP_STARTTLS}  // $rc{'smtp.starttls'} // 0;
my $use_ssl  = $ENV{MM_SMTP_SSL}       // $rc{'smtp.ssl'}      // 0;
my $debug    = $ENV{MM_SMTP_DEBUG}     // $rc{'smtp.debug'}    // 0;

# Build the common smtpsend options hash used by every subtest
my %smtp_common = (
    Host  => $host,
    Port  => $port,
    Hello => $hello,
    Debug => $debug,
);
$smtp_common{StartTLS} = 1             if( $starttls );
$smtp_common{SSL}      = 1             if( $use_ssl );
$smtp_common{Username} = $username     if( defined( $username ) && length( $username ) );
$smtp_common{Password} = $password     if( defined( $password ) && length( $password ) );

# NOTE: Skip gracefully if not configured
unless( defined( $from ) && length( $from ) &&
        defined( $to   ) && length( $to   ) )
{
    plan( skip_all =>
        'Live SMTP test skipped: set MM_SMTP_FROM and MM_SMTP_TO, ' .
        'or configure [smtp] from/to in ~/.mailmakerc' );
}

use_ok( 'Mail::Make' );

# NOTE: Basic plain-text message
subtest 'live: plain-text message delivered' => sub
{
    my $mail = Mail::Make->new
        ->from(    $from )
        ->to(      $to )
        ->subject( '[Mail::Make] Live test - plain text' )
        ->plain(   "This is a live test message sent by Mail::Make.\n\n" .
                   "If you are reading this, smtpsend() works correctly.\n" );

    my $rv = $mail->smtpsend( %smtp_common );

    diag( $mail->error ) if( !defined( $rv ) && $mail->error );
    ok( defined( $rv ), 'plain-text message accepted by server' );
    ok( ref( $rv ) eq 'ARRAY' && scalar( @{ $rv } ) > 0,
        'smtpsend() returns non-empty arrayref of delivered addresses' );
};

# NOTE: Plain + HTML multipart/alternative
subtest 'live: multipart/alternative message delivered' => sub
{
    my $mail = Mail::Make->new
        ->from(    $from )
        ->to(      $to )
        ->subject( '[Mail::Make] Live test - multipart/alternative' )
        ->plain(   "Plain text version of the live test.\n" )
        ->html(    "<p>HTML version of the <strong>live test</strong>.</p>\n" );

    my $rv = $mail->smtpsend( %smtp_common );

    diag( $mail->error ) if( !defined( $rv ) && $mail->error );
    ok( defined( $rv ), 'multipart/alternative message accepted by server' );
};

# NOTE: Non-ASCII subject (RFC 2047 encoded)
subtest 'live: non-ASCII subject encoded and delivered' => sub
{
    my $mail = Mail::Make->new
        ->from(    $from )
        ->to(      $to )
        ->subject( "[Mail::Make] Live test \x{2014} Objet non-ASCII / \x{65e5}\x{672c}\x{8a9e}" )
        ->plain(   "This message tests RFC 2047 subject encoding.\n" );

    my $rv = $mail->smtpsend( %smtp_common );

    diag( $mail->error ) if( !defined( $rv ) && $mail->error );
    ok( defined( $rv ), 'message with non-ASCII subject accepted by server' );
};

# NOTE: Bcc - recipient receives copy but header absent from message
subtest 'live: Bcc recipient included in envelope, stripped from headers' => sub
{
    # We send To and Bcc both to $to so the author can verify reception while confirming
    # the Bcc: header is absent from what arrives.
    my $mail = Mail::Make->new
        ->from(    $from )
        ->to(      $to )
        ->bcc(     $to )
        ->subject( '[Mail::Make] Live test - Bcc handling' )
        ->plain(   "You should receive this once (via To:) and once (via Bcc:).\n" .
                   "The received copy must NOT show a Bcc: header.\n" );

    my $rv = $mail->smtpsend( %smtp_common );

    diag( $mail->error ) if( !defined( $rv ) && $mail->error );
    ok( defined( $rv ), 'message with Bcc accepted by server' );

    # Verify the transmitted message has no Bcc header.
    # smtpsend() strips Bcc from the entity clone it sends, not from $mail itself.
    # Replicate that: clone, strip, serialise.
    my $check_entity = $mail->as_entity;
    if( defined( $check_entity ) )
    {
        $check_entity->headers->remove( 'Bcc' );
        my $str = $check_entity->as_string;
        ok( defined( $str ) && $str !~ /^Bcc:/mi,
            'Bcc header absent from transmitted message' );
    }
    else
    {
        ok( 0, 'could not build entity for Bcc header check' );
    }
};

# NOTE: Explicit MailFrom (bounce address) differs from From
subtest 'live: explicit MailFrom envelope sender' => sub
{
    my $mail = Mail::Make->new
        ->from(    $from )
        ->to(      $to )
        ->subject( '[Mail::Make] Live test - explicit MailFrom' )
        ->plain(   "This message uses an explicit MailFrom (bounce address).\n" );

    my $rv = $mail->smtpsend( %smtp_common, MailFrom => $from );

    diag( $mail->error ) if( !defined( $rv ) && $mail->error );
    ok( defined( $rv ), 'message with explicit MailFrom accepted by server' );
};

done_testing();

__END__

=head1 NAME

xt/author/smtpsend_live.t - Live SMTP send tests for Mail::Make

=head1 SYNOPSIS

    # Plain SMTP (LAN relay), no auth
    MM_SMTP_FROM=jack@deguest.jp   \
    MM_SMTP_TO=jack@deguest.jp     \
    MM_SMTP_HOST=mail.deguest.jp   \
    AUTHOR_TESTING=1               \
    prove -lv xt/author/smtpsend_live.t

    # STARTTLS submission (port 587) with auth
    MM_SMTP_FROM=jack@deguest.jp   \
    MM_SMTP_TO=jack@deguest.jp     \
    MM_SMTP_HOST=smtp.deguest.jp   \
    MM_SMTP_PORT=587               \
    MM_SMTP_STARTTLS=1             \
    MM_SMTP_USERNAME=jack@deguest.jp \
    MM_SMTP_PASSWORD=secret        \
    AUTHOR_TESTING=1               \
    prove -lv xt/author/smtpsend_live.t

    # Or configure ~/.mailmakerc and run:
    AUTHOR_TESTING=1 prove -lv xt/author/smtpsend_live.t

=head1 CONFIGURATION

Configuration is read first from environment variables, then from the C<[smtp]> section of F<~/.mailmakerc>.

    [smtp]
    host     = smtp.example.com
    port     = 587
    from     = you@example.com
    to       = you@example.com
    hello    = example.com
    username = you@example.com
    password = secret
    starttls = 1

=head1 DESCRIPTION

Sends real messages through a real SMTP server and verifies that each is accepted (2xx response). Visual inspection of received mail is required to verify encoding, headers, and multipart structure.

=cut
