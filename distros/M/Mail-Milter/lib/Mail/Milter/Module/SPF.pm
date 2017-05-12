# $Id: SPF.pm,v 1.3 2006/03/22 15:48:23 tvierling Exp $
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

package Mail::Milter::Module::SPF;

use 5.006;
use base Exporter;
use base Mail::Milter::Object;

use strict;
use warnings;

use Carp;
use Mail::SPF::Query 1.996;
use Sendmail::Milter 0.18; # get needed constants
use Socket;
use UNIVERSAL;

our $VERSION = '0.01';

=pod

=head1 NAME

Mail::Milter::Module::SPF - milter to use Sender Policy Framework for accept/reject

=head1 SYNOPSIS

    use Mail::Milter::Module::SPF;

    my $milter = new Mail::Milter::Module::SPF;

    my $milter2 = &SPF; # convenience

=head1 WARNING

This module is known to have major problems.  It should NOT be used in a
production environment at this time.

=head1 DESCRIPTION

This milter module rejects any mail from a sender (in the MAIL FROM part of 
the SMTP transaction, not in the From: header) if that sender's domain 
publishes a Sender Policy Framework (SPF) record denying access to the 
connection host.

The pass/fail result from SPF is configurable as to whether mail will be 
accepted or rejected immediately.  By default, this module will reject a 
sender whose SPF lookup returns "fail", and allow others to pass, setting a 
Received-SPF: header with the SPF lookup result.  See the methods below for 
knobs tunable for different situations.

This module requires the Mail::SPF::Query module (version 1.996 or later) to 
be installed in order to fetch the SPF record.

Be sure to read BUGS at the bottom of this documentation for a list of 
currently unsupported features.

=head1 METHODS

=over 4

=cut

our @EXPORT = qw(&SPF);

sub SPF {
	new Mail::Milter::Module::SPF(@_);
}

=pod

=item new()

Creates a SPF object.  There are no arguments to configure this module from 
the constructor; see the methods below for changeable options.

=cut

sub new ($) {
	my $this = Mail::Milter::Object::new(shift);

	$this->{_addheader} = 'Received-SPF';
	$this->{_ignoresoftfail} = 1;
	$this->{_ignoretempfail} = 0;
	$this->{_message} = 'Mail from %M failed SPF check: %E';
	$this->{_spfopts} = {};
	$this->{_whitelistpass} = 0;

	$this;
}

=pod

=item add_header(HEADERNAME)

Tell this module to append a header on messages which are not rejected, 
indicating the SPF result value and a comment explaining the result.  By 
default, this is enabled with the standard header name C<Received-SPF>.

Note that this header is not appended if C<whitelist_pass(1)> is in effect, 
and a sender is whitelisted by a SPF "pass" result.  This is because 
whitelisting skips all other mail processing, so this module cannot add 
headers at the end of processing.

If HEADERNAME is undef, the header is disabled and will not be appended to 
any message.

This method returns a reference to the object itself, allowing this method 
call to be chained.

=cut

sub add_header ($$) {
	my $this = shift;
	my $headername = shift;

	$this->{_addheader} = $headername;

	$this;
}

=pod

=item ignore_softfail(FLAG)

If FLAG is 0, a SPF record resulting in "softfail" will be rejected as if 
the result were "fail".

If FLAG is 1 (the default), a "softfail" is ignored, treated as if it 
returned "neutral".

This method returns a reference to the object itself, allowing this method 
call to be chained.

=cut

sub ignore_softfail ($$) {
	my $this = shift;
	my $flag = shift;

	croak 'ignore_softfail: flag argument is undef' unless defined($flag);
	$this->{_ignoresoftfail} = $flag;

	$this;
}

=pod

=item ignore_tempfail(FLAG)

If FLAG is 0 (the default), a DNS lookup which fails the underlying DNS 
query (a SPF "error" result) will cause the milter to return a temporary 
failure result (SMFIS_TEMPFAIL).

If FLAG is 1, a temporary DNS failure will be treated as if the lookup 
resulted in an empty record set (and thus a SPF "none" result).

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

=item local_rules(RULETEXT)

Add one or more SPF rules to try before a "-all" or "?all" record is 
encountered, in an attempt to validate the mail.  This is useful for 
enumerating secondary MX servers or non-SRS-compliant forwarding systems 
which send mail to this host.

The rules must be contained in a single string, separated by spaces.

This method returns a reference to the object itself, allowing this method 
call to be chained.

=cut

sub local_rules ($$) {
	my $this = shift;
	my $locals = shift;

	if (defined($this->{_spfopts}{local})) {
		$this->{_spfopts}{local} .= " $locals";
	} else {
		$this->{_spfopts}{local} = $locals;
	}

	$this;
}

=pod

=item set_message(MESSAGE)

Sets the message used when rejecting messages.  This string may contain the 
substring C<%M>, which will be replaced by the matching e-mail address, 
and/or C<%E>, which will be replaced by the SPF explanatory URL and text.

This method returns a reference to the object itself, allowing this method 
call to be chained.

=cut

sub set_message ($$) {
	my $this = shift;

	$this->{_message} = shift;

	$this;
}

=pod

=item whitelist_pass(FLAG)

If FLAG is 0 (the default), a SPF "pass" result will be treated like any 
other non-failure result, allowing the message to pass through without other 
special handling.

If FLAG is 1, a SPF "pass" result will cause this module to return 
SMFIS_ACCEPT, a value that is used by the accept_break(1) behavior of 
Mail::Milter::Chain, to ignore the results of other modules in the chain.  
Note that because SPF does not accept or reject until the MAIL FROM: stage, 
it may be necessary to embed a DeferToRCPT wrapper into the whitelisting 
chain.  For example,

    use Mail::Milter::Chain;
    use Mail::Milter::Module::SPF;
    use Mail::Milter::Wrapper::DeferToRCPT;

    my $spf_whitelisted_chain = new Mail::Milter::Chain(
        &SPF->whitelist_pass(1),
        &DeferToRCPT(new Mail::Milter::Chain(
            $milter1, ...
        ))
    )->accept_break(1);

This method returns a reference to the object itself, allowing this method 
call to be chained.

=cut

sub whitelist_pass ($$) {
	my $this = shift;
	my $flag = shift;

	croak 'whitelist_pass: flag argument is undef' unless defined($flag);
	$this->{_whitelistpass} = $flag;

	$this;
}

sub connect_callback {
	my $this = shift;
	my $ctx = shift;
	shift; # $hostname
	my $pack = shift; # XXX should handle IPv6 via getsymval parsing

	my $addr = eval {
		my @unpack = unpack_sockaddr_in($pack);
		$unpack[1];
	};

	return SMFIS_CONTINUE unless defined($addr);

	my $spfopts = {};
	$ctx->setpriv({ _spfopts => $spfopts });

	$spfopts->{helo} = 'UNKNOWN'; # in case MTA allows skipping HELO step
	$spfopts->{ip} = join('.', unpack('C4', $addr));
	$spfopts->{myhostname} = $ctx->getsymval('j');

	SMFIS_CONTINUE;
}

sub helo_callback {
	my $this = shift;
	my $ctx = shift;
	my $helo = shift;
	my $spfopts = $ctx->getpriv()->{_spfopts};

	$spfopts->{helo} = $helo;

	SMFIS_CONTINUE;
}

sub envfrom_callback {
	my $this = shift;
	my $ctx = shift;
	my $from = shift;

	$from =~ s/^<//;
	$from =~ s/>$//;

	return SMFIS_CONTINUE if ($from eq ''); # null <> sender

	my $data = $ctx->getpriv();
	my $query = new Mail::SPF::Query(
		%{$this->{_spfopts}}, %{$data->{_spfopts}}, sender => $from
	);
	if (defined($@) && $@ ne '') {
		warn "SPF query problem: $@";
		return SMFIS_TEMPFAIL;
	}

	my ($result, $smtp_comment, $header_comment) = $query->result();

	$data->{result} = $result;
	$data->{header_comment} = $header_comment;

	if ($result eq 'fail' || ($result eq 'softfail' && !$this->{_ignoresoftfail})) {
		my $msg = $this->{_message};
		$msg =~ s/%M/$from/g;
		$msg =~ s/%E/$smtp_comment/g;

		$ctx->setreply('554', '5.7.1', $msg);
		return SMFIS_REJECT;
	} elsif ($result eq 'error' && !$this->{_ignoretempfail}) {
		my $domain = $from;
		$domain =~ s/^.*\@([^\@]+)$/$1/;

		$ctx->setreply('451', '4.7.0', "Temporary DNS error encountered while fetching SPF record for $domain");
		return SMFIS_TEMPFAIL;
	} elsif ($result eq 'pass' && $this->{_whitelistpass}) {
		return SMFIS_ACCEPT;
	}

	SMFIS_CONTINUE; # don't whitelist a fallthrough
}

sub eom_callback {
	my $this = shift;
	my $ctx = shift;
	my $data = $ctx->getpriv();

	$ctx->addheader($this->{_addheader}, ($data->{result}).' ('.($data->{header_comment}).')')
		if defined($this->{_addheader});

	SMFIS_CONTINUE;
}

1;
__END__

=back

=head1 BUGS

Currently this module only handles IPv4 connecting hosts.  IPv6 hosts pass 
through without any SPF handling.

This module does not currently support the C<result2()> form of the SPF 
query for special secondary-MX handling.  Currently C<local_rules()> must be 
used to set up SPF exceptions for those secondary MX hosts.

The C<best_guess()> and C<trusted_forwarder()> special lookups are not yet 
supported.

=head1 AUTHOR

Todd Vierling, E<lt>tv@duh.orgE<gt> E<lt>tv@pobox.comE<gt>

=head1 SEE ALSO

L<Mail::Milter::Object>, L<Mail::SPF::Query>

the Sender Policy Framework Web site, http://spf.pobox.com/

=cut
