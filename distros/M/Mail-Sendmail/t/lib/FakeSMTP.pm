package FakeSMTP;

# Test helper: run Mail::Sendmail's sendmail() against a throwaway local
# SMTP server (no real network, no real mail) and return the raw DATA
# payload the client put on the wire, so tests can inspect exactly what
# was transmitted.
#
# The server lifecycle (fork, ephemeral port, readiness wait, cleanup) is
# handled by Test::TCP; we only supply the tiny SMTP dialog.

use strict;
use warnings;

use Exporter 'import';
use File::Temp ();
use IO::Socket::INET ();
use Mail::Sendmail ();
use Test::TCP ();

our @EXPORT = qw(capture_sent);

# capture_sent(%mail) -> the raw DATA payload (headers + body) that
# sendmail() transmitted for %mail.
sub capture_sent {
    my %mail = @_;

    # The server runs in a child process; it hands the captured payload
    # back through this temp file.  Kept in scope for the whole sub so
    # File::Temp does not unlink it before we read it.
    my $capture = File::Temp->new;
    my $capture_path = $capture->filename;

    my $server = Test::TCP->new( code => sub { _serve(shift, $capture_path) } );

    # Don't MIME-encode the body, so the captured payload is predictable.
    local $Mail::Sendmail::mailcfg{mime} = 0;
    $mail{Smtp} = '127.0.0.1:' . $server->port;
    Mail::Sendmail::sendmail(%mail);

    open my $fh, '<', $capture_path or die "no captured payload: $!";
    local $/;
    my $data = <$fh>;
    close $fh;
    return $data;
}

# The fake SMTP server: accept a connection, answer just enough of the
# dialog to reach DATA, capture the payload, then acknowledge.
sub _serve {
    my ($port, $capture_path) = @_;

    my $listen = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => $port,
        Listen    => 5,
        ReuseAddr => 1,
        Proto     => 'tcp',
    ) or die "fake SMTP listen failed: $!";

    while (my $client = $listen->accept) {
        $client->autoflush(1);
        print {$client} "220 fake ESMTP\r\n";
        my $data = '';
        while (my $line = <$client>) {
            if ($line =~ /^DATA/i) {
                print {$client} "354 go ahead\r\n";
                while (my $dl = <$client>) {
                    last if $dl eq ".\r\n" or $dl eq ".\n";
                    $data .= $dl;
                }
                # Record the payload BEFORE the 250 that releases the
                # client, so the parent can rely on it being complete
                # once sendmail() returns.
                open my $fh, '>', $capture_path or die "capture: $!";
                print {$fh} $data;
                close $fh;
                print {$client} "250 queued\r\n";
            }
            elsif ($line =~ /^QUIT/i) { print {$client} "221 bye\r\n"; last }
            else                      { print {$client} "250 ok\r\n" }  # greeting/EHLO/MAIL/RCPT
        }
    }
}

1;
