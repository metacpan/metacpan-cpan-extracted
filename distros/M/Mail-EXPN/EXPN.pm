# $Id: EXPN.pm,v 1.3 2003/02/01 10:45:49 florian Exp $

package Mail::EXPN;

use Net::DNS;
use Net::SMTP;
use IO::Socket;
require Exporter;
use strict;
use vars qw(@ISA @EXPORT_OK $BAD $VERSION $first);
@ISA = qw(Exporter);
@EXPORT_OK = qw(isfake $BAD);

$VERSION = '0.04';

$BAD = "SMTP response not understood";


sub isfake ($;$) {
	my @tokens = split(/\@/, shift);
	my $mx = shift;
	unless ($mx) {
		return 'not in user@host format' unless @tokens == 2;
		foreach (@tokens) {
			return 'contains illegal characters' if /[;()<>]/;
		}
		return 'malformed mail domain' unless ($tokens[1] =~ /\./);
		my @mx = mx($tokens[1]);
		return 'bogus mail domain' unless @mx;
		##@mx = sort { $b->preference <=> $a->preference} @mx;
		$mx = $mx[0]->exchange;
	}
	my $sock = new IO::Socket::INET("$mx:25") || return undef;
	my $result = step1($sock, join('@', @tokens));
	$sock->close;
	$result;
}

sub step1 {
	my ($sock, $email) = @_;
	return $BAD unless code($sock) == 220;
	$first = 1;
	out($sock, "HELO Mail-Check");
	return $BAD unless code($sock) == 250;
	out($sock, "EXPN $email");
	my $code = code($sock);
	return step2($sock, $email) if ($code == 502);
	return "" if ($code == 250);
	return "bogus username" if ($code == 550);
	return $BAD;
}

sub step2 {
	my ($sock, $email) = @_;
	out($sock, "VRFY $email");
	my $code = code($sock);
	return step3($sock, $email) if ($code == 252);
	return "bogus username" if ($code == 550);
	return "" if ($code == 250);
	return $BAD;
}

sub step3 {
	my ($sock, $email) = @_;
	out($sock, "MAIL FROM:<>");
	return $BAD unless code($sock) == 250;
	out($sock, "RCPT TO:<$email>");
	my $code = code($sock);
	return "bogus username" if ($code == 550);
	return "" if ($code == 250);
	return $BAD;
}

sub out ($$) {
	my ($sock, $text) = @_;
	$sock->send("$text\n");
}

sub code ($) {
	my ($sock) = @_;
	my $line = <$sock>;
	my @tokens = split(/[- ]+/, $line);
	my $ret = $tokens[0];
	return code($sock) if $first && $ret == 220;
	$first = undef;
	return $ret;
}

1;
__END__

=head1 NAME

Mail::EXPN - Perl extension for validation of email addresses

=head1 SYNOPSIS

  use Mail::EXPN qw(isfake);

  $reason = isfake('bill@microsoft.com');
  if ($reason) {
    print "Bad email: $reason\n";
  } elsif (defined($reason)) {
    print "Email address perfect\n";
  } else {
    print "Could not verify email address: EXPN is turned off at target computer";
  }

  $reason = isfake('bigboss', 'mail.acme.com');
  ...

=head1 DESCRIPTION

This module checks validity of email addresses. It ensure the
existence of a username and domain, unless you specified the
MTA, searches the DNS for the MTA (if not specified), and then
attempts to use the SMTP keyword EXPN to verify the username.
Since EXPN is usually turned off, the module will return I<undef>
in such cases, and defined but false if the verification passed.
If for any reason the check failed, the module will return a string
describing the reason.

=head1 CAVEATS

Contemporary ISPs never turn EXPN on, to prevent mail abusers
harass more efficiently by molesting only existing addresses
with junk mail. Therefore, this is not an excellent solution
to check the fill-out forms in your site for users supplying
false email addresses. Most addresses associated with valid MTAs
will return I<undef>.

=head1 NOTE ON RFC 2821

Mail::EXPN only checks the first mx specified, as it is likely to be the only 
one to contain the user list.

=head1 TO DO

I tried to rewrite the module using Net::SMTP, but could not figure how
to handle the expand and verify methods. They seemed to return an
empty reply.

=head1 CREDITS

Idea by Raz Information Systems, http://www.raz.co.il.

=head1 AUTHOR

Ariel Brosh, schop@cpan.org.

=head1 MAINTAINER

Florian Helmberger, florian@cpan.org.

=head1 VERSION

$Id: EXPN.pm,v 1.3 2003/02/01 10:45:49 florian Exp $

=head1 SEE ALSO

perl(1).

=cut
