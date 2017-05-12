# $Id: MailDomainDNSBL.pm,v 1.9 2006/03/22 15:48:23 tvierling Exp $
#
# Copyright (c) 2002-2006 Todd Vierling <tv@pobox.com> <tv@duh.org>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of the author nor the names of contributors may be used
# to endorse or promote products derived from this software without specific
# prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package Mail::Milter::Module::MailDomainDNSBL;

use 5.006;
use base Exporter;
use base Mail::Milter::Object;

use strict;
use warnings;

use Carp;
use Sendmail::Milter 0.18; # get needed constants
use Socket;
use UNIVERSAL;

our $VERSION = '0.04';

=pod

=head1 NAME

Mail::Milter::Module::MailDomainDNSBL - milter to accept/reject mail whose sender domain matches a DNSBL

=head1 SYNOPSIS

    use Mail::Milter::Module::MailDomainDNSBL;

    my $milter = new Mail::Milter::Module::MailDomainDNSBL('foo.spamlist.dom');

    my $milter2 = &MailDomainDNSBL('foo.spamlist.dom'); # convenience

    $milter2->set_message('Mail from %M disallowed');

=head1 DESCRIPTION

This milter module rejects any mail from a sender's domain (in the MAIL
FROM part of the SMTP transaction, not in the From: header) matching a
given DNS Blocking List (DNSBL).  It can also function as a whitelisting
Chain element; see C<accept_match()>.  (This is known as a "RHSBL" check
in some anti-spam lingo.)

The check used by this module is a simple "A" record lookup, via the
standard "gethostbyname" lookup mechanism.  This method does not require
the use of Net::DNS and is thus typically very fast.

=head1 METHODS

=over 4

=cut

our @EXPORT = qw(&MailDomainDNSBL);

sub MailDomainDNSBL {
	new Mail::Milter::Module::MailDomainDNSBL(@_);
}

=pod

=item new(DNSBL)

=item new(DNSBL, MATCHRECORD[, ...])

=item new(DNSBL, SUBREF)

Creates a MailDomainDNSBL object.  DNSBL is the root host hierarchy to use
for lookups.  Three methods of matching can be used:

If no additional arguments are provided, the match succeeds if there is
any address entry present for the DNSBL lookup; the values are not
examined.

If one or more MATCHRECORD values are supplied, they are string
representations of IPv4 addresses.  If any of these match record values is
the same as any address record returned by the DNSBL lookup, the match
succeeds.

If a SUBREF (reference to a subroutine; may be an anonymous inline
C<sub{}>) is supplied, it is called for each of the address records
returned by the DNSBL lookup.  The subroutine should return 0 or undef to
indicate a failed match, and nonzero to indicate a successful match.  The
subroutine receives two arguments: a binary-encoded four byte scalar that
should be transformed as needed with C<inet_ntoa()> or C<unpack>, and the
domain name being checked by the DNSBL.

=cut

sub new ($$;@) {
	my $this = Mail::Milter::Object::new(shift);
	my $dnsbl = $this->{_dnsbl} = shift;

	$this->{_accept} = 0;
	$this->{_checksupers} = 0;
	$this->{_ignoretempfail} = 0;
	$this->{_message} = 'Access denied to sender address %M (domain is listed by %L)';

	if (UNIVERSAL::isa($_[0], 'CODE')) {
		$this->{_matcher} = shift;
	} else {
		my @records;

		foreach my $record (@_) {
			my $addr = inet_aton($record);

			croak "new MailDomainDNSBL: address $record is not a valid IPv4 address" unless defined($addr);

			push(@records, $addr);
		}

		if (scalar @records) {
			$this->{_matcher} = sub {
				my $addr = shift;
				foreach my $record (@records) {
					return 1 if ($addr eq $record);
				}
				undef;
			};
		} else {
			$this->{_matcher} = sub { 1 };
		}
	}

	$this;
}

=pod

=item accept_match(FLAG)

If FLAG is 0 (the default), a matching DNSBL will cause the mail to be
rejected.

If FLAG is 1, a matching DNSBL will cause this module to return
SMFIS_ACCEPT instead.  This allows a C<MailDomainDNSBL> to be used inside
a C<Mail::Milter::Chain> container (in C<accept_break(1)> mode), to
function as a whitelist rather than a blacklist.

This method returns a reference to the object itself, allowing this method
call to be chained.

=cut

sub accept_match ($$) {
	my $this = shift;
	my $flag = shift;

	croak 'accept_match: flag argument is undef' unless defined($flag);
	$this->{_accept} = $flag;

	$this;
}

=pod

=item ignore_tempfail(FLAG)

If FLAG is 0 (the default), a DNSBL lookup which fails the underlying DNS
query will cause the milter to return a temporary failure result
(SMFIS_TEMPFAIL).

If FLAG is 1, a temporary DNS failure will be treated as if the lookup
resulted in an empty record set (SMFIS_CONTINUE).

This method returns a reference to the object itself, allowing this method
call to be chained.

=cut

sub ignore_tempfail ($$) {
	my $this = shift;
	my $flag = shift;

	croak 'ignore_tempfail: flag argument is undef' unless defined($flag);
	$this->{_ignoretempfail} = $flag;

	$this;
}

=pod

=item check_superdomains(NUM)

If no match is returned by checking the domain name verbatim, recurse
one level upward at a time and attempt the check again.  If NUM is
positive, the recursion will stop after NUM recursions; if negative,
the recursion will stop when abs(NUM) domain levels have been reached.
The default is 0, meaning that no recursion will be done.

For example, when checking the domain name FOO.BAR.BAZ.COM, NUM=1 will
also check BAR.BAZ.COM; NUM=-1 will check BAR.BAZ.COM, BAZ.COM, and COM.

This method returns a reference to the object itself, allowing this method
call to be chained.

=cut

sub check_superdomains ($$) {
	my $this = shift;
	my $flag = shift;

	$this->{_checksupers} = $flag;

	$this;
}

=pod

=item set_message(MESSAGE)

Sets the message used when rejecting messages.  This string may contain
the substring C<%M>, which will be replaced by the matching e-mail
address, or C<%L>, which will be replaced by the name of the matching
DNSBL.

This method returns a reference to the object itself, allowing this method
call to be chained.

=cut

sub set_message ($$) {
	my $this = shift;

	$this->{_message} = shift;

	$this;
}

sub envfrom_callback {
	my $this = shift;
	my $ctx = shift;
	my $from = lc(shift);

	$from =~ s/^<//;
	$from =~ s/>$//;

	return SMFIS_CONTINUE if ($from eq ''); # null <> sender

	my $dnsbl = $this->{_dnsbl};
	my $fdomain = $from;

	$fdomain =~ s/^[^\@]+\@//;

	my @domainparts = split(/\./, $fdomain);
	my $startmax = $this->{_checksupers};

	$startmax += scalar(@domainparts) if ($startmax < 0);
	$startmax = 0 if ($startmax < 0);

	for (my $i = 0; $i <= $#domainparts && $i <= $startmax; ++$i) {
		my $fromdomain = join('.', @domainparts[$i..$#domainparts]);
		my $lookup = $fromdomain.'.'.$dnsbl;
		my @lookup_addrs;
		(undef, undef, undef, undef, @lookup_addrs) = gethostbyname($lookup);

		unless (scalar @lookup_addrs) {
			# h_errno 1 == HOST_NOT_FOUND
			next if ($? == 1 || $this->{_ignoretempfail});

			$ctx->setreply('451', '4.7.1', "Temporary failure in DNS lookup for $lookup");
			return SMFIS_TEMPFAIL;
		}

		foreach my $lookup_addr (@lookup_addrs) {
			if (&{$this->{_matcher}}($lookup_addr, $fromdomain)) {
				return SMFIS_ACCEPT if $this->{_accept};

				my $msg = $this->{_message};

				if (defined($msg)) {
					$msg =~ s/%M/$from/g;
					$msg =~ s/%L/$dnsbl/g;
					$ctx->setreply('550', '5.7.1', $msg);
				}

				return SMFIS_REJECT;
			}
		}
	}

	SMFIS_CONTINUE; # don't whitelist a fallthrough
}

1;
__END__

=back

=head1 AUTHOR

Todd Vierling, E<lt>tv@duh.orgE<gt> E<lt>tv@pobox.comE<gt>

=head1 SEE ALSO

L<Mail::Milter::Object>

=cut
