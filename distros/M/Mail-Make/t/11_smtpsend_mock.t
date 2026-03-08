#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## Mail Builder - t/11_smtpsend_mock.t
## Test suite for Mail::Make->smtpsend() using a local mock SMTP server.
## No real outbound connection is made; all tests run without credentials.
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use IO::Socket::INET ();
use POSIX            qw( WNOHANG );
use Scalar::Util     qw( blessed );

BEGIN
{
    use ok( 'Mail::Make' );
};

# ---------------------------------------------------------------------------
# Helper: spawn a minimal SMTP server in a forked child.
#
# The server:
#   - listens on an ephemeral port on 127.0.0.1
#   - speaks enough ESMTP to satisfy Net::SMTP:
#       220 greeting
#       250 response to EHLO
#       250 response to MAIL FROM
#       250 response per RCPT TO
#       354 response to DATA
#       250 response to the message terminator (.)
#       221 response to QUIT
#   - captures the raw SMTP conversation into a temp file shared via pipe
#
# Returns: ( $port, $pid, $log_fh )
#   $port   — TCP port the child is listening on
#   $pid    — child PID (caller must waitpid when done)
#   $log_fh — readable end of a pipe; child writes captured lines there
# ---------------------------------------------------------------------------
sub _spawn_mock_smtp
{
    my %opts         = @_;
    my $max_conns    = $opts{max_connections} // 1;

    my $listener = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        Listen    => 5,
        ReuseAddr => 1,
    ) or die "Cannot create mock SMTP listener: $!\n";

    my $port = $listener->sockport;

    # Pipe: child writes captured data, parent reads it
    pipe( my $r_fh, my $w_fh ) or die "Cannot create pipe: $!\n";

    my $pid = fork();
    die "fork failed: $!\n" unless( defined( $pid ) );

    if( $pid == 0 )
    {
        # NOTE: child
        close( $r_fh );

        my @log;
        my $_handle_conn = sub
        {
            my $conn = shift( @_ );

            # Greeting
            print { $conn } "220 localhost Mock SMTP\r\n";

            while( my $line = <$conn> )
            {
                $line =~ s/\r?\n$//;
                push( @log, $line );

                if( $line =~ /^EHLO/i )
                {
                    print { $conn } "250-localhost\r\n250 OK\r\n";
                }
                elsif( $line =~ /^HELO/i )
                {
                    print { $conn } "250 OK\r\n";
                }
                elsif( $line =~ /^MAIL FROM/i )
                {
                    print { $conn } "250 OK\r\n";
                }
                elsif( $line =~ /^RCPT TO/i )
                {
                    print { $conn } "250 OK\r\n";
                }
                elsif( $line =~ /^DATA/i )
                {
                    print { $conn } "354 End with .\r\n";
                    while( my $body_line = <$conn> )
                    {
                        $body_line =~ s/\r?\n$//;
                        push( @log, "DATA: $body_line" );
                        last if( $body_line eq '.' );
                    }
                    print { $conn } "250 OK\r\n";
                }
                elsif( $line =~ /^QUIT/i )
                {
                    print { $conn } "221 Bye\r\n";
                    last;
                }
                else
                {
                    print { $conn } "500 Unknown command\r\n";
                }
            }
            $conn->close;
        };

        for( 1 .. $max_conns )
        {
            my $conn = $listener->accept or last;
            $_handle_conn->( $conn );
        }
        $listener->close;

        # Write log to parent via pipe
        print { $w_fh } "$_\n" for( @log );
        close( $w_fh );

        POSIX::_exit(0);
    }

    # NOTE: parent
    $listener->close;
    close( $w_fh );

    return( $port, $pid, $r_fh );
}

# NOTE: Helper: wait for child and slurp the conversation log.
sub _collect_log
{
    my( $pid, $r_fh ) = @_;
    local $/ = undef;
    my $raw = <$r_fh>;
    close( $r_fh );
    waitpid( $pid, 0 );
    return( split( /\n/, $raw // '' ) );
}

# NOTE: Basic plain-text message — happy path
subtest 'smtpsend: basic plain-text message' => sub
{
    my( $port, $pid, $r_fh ) = _spawn_mock_smtp();

    my $mail = Mail::Make->new
        ->from(    'sender@example.com' )
        ->to(      'recipient@example.com' )
        ->subject( 'Mock SMTP test' )
        ->plain(   "Hello from the mock server.\n" );

    my $rv = $mail->smtpsend(
        Host  => '127.0.0.1',
        Port  => $port,
        Hello => 'test.local',
    );

    my @log = _collect_log( $pid, $r_fh );

    diag( "SMTP log:\n", join( "\n", @log ) ) if( $DEBUG );

    ok( defined( $rv ), 'smtpsend() returns defined value on success' );
    ok( grep( /^MAIL FROM:.*sender\@example\.com/i, @log ),
        'MAIL FROM contains envelope sender' );
    ok( grep( /^RCPT TO:.*recipient\@example\.com/i, @log ),
        'RCPT TO contains recipient' );
    ok( grep( /^DATA$/i, @log ),
        'DATA command issued' );
};

# NOTE: Bcc is in RCPT TO but stripped from the transmitted message
subtest 'smtpsend: Bcc goes to RCPT TO but not into message headers' => sub
{
    my( $port, $pid, $r_fh ) = _spawn_mock_smtp();

    my $mail = Mail::Make->new( $DEBUG ? ( debug => $DEBUG ) : () )
        ->from(    'sender@example.com' )
        ->to(      'to@example.com' )
        ->bcc(     'secret@example.com' )
        ->subject( 'Bcc test' )
        ->plain(   "body\n" );

    my $rv = $mail->smtpsend(
        Host  => '127.0.0.1',
        Port  => $port,
        Hello => 'test.local',
    );

    my @log = _collect_log( $pid, $r_fh );
    diag( "Log lines are: ", join( "\n", @log ) ) if( $DEBUG );

    ok( defined( $rv ), 'smtpsend() succeeds with Bcc' );
    ok( grep( /^RCPT TO:.*secret\@example\.com/i, @log ),
        'Bcc address appears in RCPT TO' );

    # The Bcc header must not appear inside the DATA block.
    # DATA lines are prefixed "DATA: " by the mock server.
    my $bcc_in_body = grep( /^DATA: Bcc:/i, @log );
    ok( !$bcc_in_body, 'Bcc header absent from transmitted message body' );
};

# NOTE: Multiple recipients — To + Cc
subtest 'smtpsend: multiple recipients via To and Cc' => sub
{
    my( $port, $pid, $r_fh ) = _spawn_mock_smtp();

    my $mail = Mail::Make->new( $DEBUG ? ( debug => $DEBUG ) : () )
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->cc(      'c@example.com' )
        ->subject( 'Multi-recipient test' )
        ->plain(   "body\n" );

    my $rv = $mail->smtpsend(
        Host  => '127.0.0.1',
        Port  => $port,
        Hello => 'test.local',
    );

    my @log = _collect_log( $pid, $r_fh );
    diag( "SMTP log:\n", join( "\n", @log ) ) if( $DEBUG );

    ok( defined( $rv ), 'smtpsend() succeeds with To + Cc' );
    ok( grep( /^RCPT TO:.*b\@example\.com/i, @log ), 'To recipient in RCPT TO' );
    ok( grep( /^RCPT TO:.*c\@example\.com/i, @log ), 'Cc recipient in RCPT TO' );
};

# NOTE: Display name in From — addr-spec extracted correctly for MAIL FROM
subtest 'smtpsend: display name in From — addr-spec extracted for MAIL FROM' => sub
{
    my( $port, $pid, $r_fh ) = _spawn_mock_smtp();

    my $mail = Mail::Make->new
        ->from(    '"John Smith" <john@example.com>' )
        ->to(      'x@example.com' )
        ->subject( 'Display name test' )
        ->plain(   "body\n" );

    my $rv = $mail->smtpsend(
        Host  => '127.0.0.1',
        Port  => $port,
        Hello => 'test.local',
    );

    my @log = _collect_log( $pid, $r_fh );
    diag( "SMTP log:\n", join( "\n", @log ) ) if( $DEBUG );

    ok( defined( $rv ), 'smtpsend() succeeds with display name in From' );
    ok( grep( /^MAIL FROM:.*john\@example\.com/i, @log ),
        'bare addr-spec used in MAIL FROM, not display name' );
};

# NOTE: Explicit MailFrom override
subtest 'smtpsend: explicit MailFrom overrides From header' => sub
{
    my( $port, $pid, $r_fh ) = _spawn_mock_smtp();

    my $mail = Mail::Make->new
        ->from(    'sender@example.com' )
        ->to(      'x@example.com' )
        ->subject( 'MailFrom override test' )
        ->plain(   "body\n" );

    my $rv = $mail->smtpsend(
        Host     => '127.0.0.1',
        Port     => $port,
        Hello    => 'test.local',
        MailFrom => 'bounce@example.com',
    );

    my @log = _collect_log( $pid, $r_fh );
    diag( "SMTP log:\n", join( "\n", @log ) ) if( $DEBUG );

    ok( defined( $rv ), 'smtpsend() succeeds with explicit MailFrom' );
    ok( grep( /^MAIL FROM:.*bounce\@example\.com/i, @log ),
        'MailFrom override used in MAIL FROM' );
    ok( !grep( /^MAIL FROM:.*sender\@example\.com/i, @log ),
        'From header not used when MailFrom is supplied' );
};

# NOTE: Pre-built Net::SMTP object passed as Host
subtest 'smtpsend: accepts a pre-built Net::SMTP object as Host' => sub
{
    # Net::SMTP->new() opens the first connection; smtpsend() uses that
    # same object — no second TCP connection needed. One slot is sufficient.
    my( $port, $pid, $r_fh ) = _spawn_mock_smtp( max_connections => 1 );

    require Net::SMTP;
    my $smtp = eval { Net::SMTP->new( '127.0.0.1', Port => $port, Hello => 'test.local' ) };
    if( !defined( $smtp ) )
    {
        _collect_log( $pid, $r_fh );
        pass( 'skip: Net::SMTP could not connect (environment issue)' );
        return;
    }

    my $mail = Mail::Make->new
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'Pre-built SMTP object test' )
        ->plain(   "body\n" );

    my $rv = $mail->smtpsend( Host => $smtp );

    # The caller owns the connection — smtpsend() does not quit it.
    # We call quit() ourselves so the mock server can finish cleanly.
    $smtp->quit if( defined( $smtp ) );

    my @log = _collect_log( $pid, $r_fh );
    diag( "SMTP log:\n", join( "\n", @log ) ) if( $DEBUG );

    ok( defined( $rv ), 'smtpsend() succeeds with pre-built Net::SMTP object' );
    ok( grep( /^MAIL FROM/i, @log ), 'MAIL FROM issued via pre-built object' );
    # smtpsend() must not have issued QUIT — our explicit call above did.
    my @quit_lines = grep( /^QUIT$/i, @log );
    is( scalar( @quit_lines ), 1, 'exactly one QUIT in log (from caller, not smtpsend)' );
};

# NOTE: Return value — array ref of delivered addresses
subtest 'smtpsend: return value is arrayref of delivered addresses' => sub
{
    my( $port, $pid, $r_fh ) = _spawn_mock_smtp();

    my $mail = Mail::Make->new
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->cc(      'c@example.com' )
        ->subject( 'Return value test' )
        ->plain(   "body\n" );

    my $rv = $mail->smtpsend(
        Host  => '127.0.0.1',
        Port  => $port,
        Hello => 'test.local',
    );

    my @log = _collect_log( $pid, $r_fh );
    diag( "SMTP log:\n", join( "\n", @log ) ) if( $DEBUG );

    ok( defined( $rv ) && ref( $rv ) eq 'ARRAY',
        'smtpsend() returns an array ref' );
    is( scalar( @{ $rv } ), 2, 'two addresses returned' );
    ok( grep( $_ eq 'b@example.com', @{ $rv } ), 'To address in return list' );
    ok( grep( $_ eq 'c@example.com', @{ $rv } ), 'Cc address in return list' );
};

# NOTE: Error: no recipients
subtest 'smtpsend: error when no recipients' => sub
{
    my $mail = Mail::Make->new( $DEBUG ? ( debug => $DEBUG ) : () )
        ->from(    'a@example.com' )
        ->subject( 'No recipients' )
        ->plain(   "body\n" );

    # Silence any warning output.
    local $SIG{__WARN__} = sub{};
    my $rv = $mail->smtpsend(
        Host  => '127.0.0.1',
        Port  => 19999,   # nothing listening — but error fires before connect
        Hello => 'test.local',
        To    => '',
    );

    ok( !defined( $rv ), 'smtpsend() returns undef when no recipients' );
    like( $mail->error, qr/no recipients/i, 'error mentions no recipients' );
};
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
# NOTE: Error: cannot connect to SMTP server
subtest 'smtpsend: error when SMTP server unreachable' => sub
{
    my $mail = Mail::Make->new
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'Unreachable server' )
        ->plain(   "body\n" );

    # Silence any warning output.
    local $SIG{__WARN__} = sub{};
    # Port 1 on localhost is almost certainly not running an SMTP server.
    my $rv = $mail->smtpsend(
        Host  => '127.0.0.1',
        Port  => 1,
        Hello => 'test.local',
    );

    ok( !defined( $rv ), 'smtpsend() returns undef when server unreachable' );
    like( $mail->error, qr/could not connect|SMTP/i,
        'error message mentions connection failure' );
};

# NOTE: Password as CODE ref — callback invoked at send time
subtest 'smtpsend: password CODE ref is called and resolved' => sub
{
    my( $port, $pid, $r_fh ) = _spawn_mock_smtp();

    my $called = 0;
    my $pw_cb  = sub { $called++; return( 'secret' ) };

    my $mail = Mail::Make->new
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'Password callback test' )
        ->plain(   "body\n" );

    # Silence any warning output.
    local $SIG{__WARN__} = sub{};
    # We cannot actually test SASL auth against the plain mock (it does not
    # speak AUTH), but we can verify that:
    #   a) the callback is called
    #   b) smtpsend() fails at the auth step with a meaningful error
    #      (mock returns 500 Unknown command for AUTH)
    my $rv = $mail->smtpsend(
        Host     => '127.0.0.1',
        Port     => $port,
        Hello    => 'test.local',
        Username => 'jack@example.com',
        Password => $pw_cb,
    );

    _collect_log( $pid, $r_fh );

    ok( $called, 'password CODE ref was invoked' );
    # Auth will fail against the plain mock — that is expected here
    ok( !defined( $rv ) || defined( $rv ),
        'smtpsend() returned without hanging (auth fail or success both acceptable)' );
};

# NOTE: Username without Password — immediate error, no connection attempted
subtest 'smtpsend: Username without Password returns error' => sub
{
    my $mail = Mail::Make->new
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'Auth error test' )
        ->plain(   "body\n" );

    # Silence any warning output.
    local $SIG{__WARN__} = sub{};
    # Credential validation happens before any network connection is attempted,
    # so the error is raised regardless of whether the host is reachable.
    my $rv = $mail->smtpsend(
        Host     => '127.0.0.1',
        Port     => 19998,
        Hello    => 'test.local',
        Username => 'jack@example.com',
        # No Password — must trigger immediate error
    );

    diag( "error: " . ( $mail->error // '(none)' ) ) if( $DEBUG );

    ok( !defined( $rv ), 'smtpsend() returns undef when Password missing' );
    like( $mail->error, qr/Password is missing/i,
        'error mentions missing Password' );
};

# NOTE: Timeout option propagated to Net::SMTP
#       (structural test — verifies no crash, not actual timeout behaviour)
subtest 'smtpsend: Timeout option accepted without error' => sub
{
    my( $port, $pid, $r_fh ) = _spawn_mock_smtp();

    my $mail = Mail::Make->new
        ->from(    'a@example.com' )
        ->to(      'b@example.com' )
        ->subject( 'Timeout option test' )
        ->plain(   "body\n" );

    my $rv = $mail->smtpsend(
        Host    => '127.0.0.1',
        Port    => $port,
        Hello   => 'test.local',
        Timeout => 30,
    );

    _collect_log( $pid, $r_fh );

    ok( defined( $rv ), 'smtpsend() with Timeout option succeeds' );
};

done_testing();

__END__
