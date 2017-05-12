# $Id: MailDomainDotMX.pm,v 1.2 2004/12/15 22:07:59 tvierling Exp $
#
# Copyright (c) 2002-2004 Todd Vierling <tv@pobox.com> <tv@duh.org>
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

package Mail::Milter::Module::MailDomainDotMX;

use 5.006;
use base Exporter;
use base Mail::Milter::Object;

use strict;
use warnings;

use Carp;
use Net::DNS;
use Sendmail::Milter 0.18; # get needed constants
use Socket;
use UNIVERSAL;

our $VERSION = '0.01';

=pod

=head1 NAME

Mail::Milter::Module::MailDomainDotMX - milter to reject mail whose sender domain publishes a null MX record

=head1 SYNOPSIS

    use Mail::Milter::Module::MailDomainDotMX;

    my $milter = new Mail::Milter::Module::MailDomainDotMX;

    my $milter2 = &MailDomainDotMX; # convenience

    $milter2->set_message('Mail from %M domain invalid (has dot-MX record)');

=head1 DESCRIPTION

This milter module rejects any mail from a sender's domain (in the MAIL FROM 
part of the SMTP transaction, not in the From: header) if that domain 
publishes a "null", or "dot" MX record.  Such a record looks like the 
following in DNS:

    example.com. IN MX 0 .

This lookup requires the Net::DNS module to be installed in order to fetch 
the MX record.

An extra check as to whether the MX is valid is not (yet) done here.  It is
currently assumed that the MTA does rudimentary checking for the presence of
a valid MX or A record on the sending domain.

=head1 METHODS

=over 4

=cut

our @EXPORT = qw(&MailDomainDotMX);

sub MailDomainDotMX {
	new Mail::Milter::Module::MailDomainDotMX(@_);
}

=pod

=item new()

Creates a MailDomainDotMX object.  There are no arguments to configure this 
module, as it is a fixed check.

=cut

sub new ($) {
	my $this = Mail::Milter::Object::new(shift);

	$this->{_ignoretempfail} = 0;
	$this->{_message} = 'Access denied to sender address %M (domain publishes a deliberately invalid MX record)';

	$this;
}

=pod

=item ignore_tempfail(FLAG)

If FLAG is 0 (the default), a DNS lookup which fails the underlying DNS
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

=item set_message(MESSAGE)

Sets the message used when rejecting messages.  This string may contain
the substring C<%M>, which will be replaced by the matching e-mail
address.

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

	my $fromdomain = $from;

	$fromdomain =~ s/^[^\@]+\@//;

	my $res = new Net::DNS::Resolver;
	my $query = $res->query($fromdomain, 'MX');

	if (!defined($query)) {
		return SMFIS_CONTINUE if $this->{_ignoretempfail};
		$ctx->setreply('451', '4.7.1', "Temporary failure in DNS lookup for $fromdomain");
		return SMFIS_TEMPFAIL;
	}

	foreach my $rr (grep { $_->type eq 'MX' } $query->answer) {
		if ($rr->exchange eq '') {
			my $msg = $this->{_message};

			if (defined($msg)) {
				$msg =~ s/%M/$from/g;
				$ctx->setreply('554', '5.7.1', $msg);
			}

			return SMFIS_REJECT;
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
