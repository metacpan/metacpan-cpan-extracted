package HTML::Merge::Mail;

use IO::Socket;

require Exporter;
use strict;
use vars qw(@EXPORT @ISA);

@ISA = qw(Exporter);
@EXPORT = qw(OpenMail CloseMail);

sub OpenMail {
        my ($from, $to, $server) = @_;
	die "Anceint IO::Socket" unless ($IO::Socket::VERSION > 1.1602);
        my $sock = new IO::Socket::INET("$server:25" ) ||
                die "Could not connect to $server port 25";
        Expect($sock, 220);
        Inject($sock, "HELO mailback", 250);
        Inject($sock, "RSET", 250);
        Inject($sock, "MAIL FROM: <$from>", 250);
        Inject($sock, "RCPT TO: <$to>", 250);
        Inject($sock, "DATA", 354);
        return $sock;
}

sub CloseMail {
        my $sock = shift;
        Inject($sock, "\r\n.", 250);
        Inject($sock, "QUIT");
        close $sock;
}

sub Expect {
        my ($sock, $code) = @_;
        my $line = <$sock>;
        chop $line;
        my @tokens = split(/\s+/, $line);
        return if ($tokens[0] == $code);
        die "Mail: Expected code $code, got $tokens[0]";
}

sub Inject {
        my ($sock, $str, $code) = @_;
        print $sock "$str\r\n";
        Expect($sock, $code) if $code;
}
