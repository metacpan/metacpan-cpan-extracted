# $Id: VirusBounceSpew.pm,v 1.9 2004/09/23 15:11:13 tvierling Exp $
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

package Mail::Milter::Module::VirusBounceSpew;

use 5.006;
use base Exporter;
use base Mail::Milter::Object;

use strict;
use warnings;

use Carp;
use Sendmail::Milter 0.18; # get needed constants

our $VERSION = '0.01';

=pod

=head1 NAME

Mail::Milter::Module::VirusBounceSpew - milter to reject antivirus messages typically sent to forged "senders"

=head1 SYNOPSIS

    use Mail::Milter::Module::VirusBounceSpew;

    my $milter = new Mail::Milter::Module::VirusBounceSpew;

    my $milter2 = &VirusBounceSpew; # convenience

=head1 DESCRIPTION

This module rejects messages at the DATA phase by searching for known
signs of misconfigured antivirus software.  An increasing problem on the
Internet as of this writing is a tendency for viruses and trojans to send
mail with a forged envelope from address.  This is triggering antivirus
warning messages back to these forged senders.

=head1 METHODS

=over 4

=cut

our @EXPORT = qw(&VirusBounceSpew);

sub VirusBounceSpew {
	new Mail::Milter::Module::VirusBounceSpew(@_);
}

=pod

=item new()

Creates a VirusBounceSpew milter object.  The match rules are internally
hardcoded and may be examined by reading the module source.

=cut

sub new ($$;@) {
	my $this = Mail::Milter::Object::new(shift);

	$this->{_message} = 'Antivirus warning messages are not accepted here.  Please configure your antivirus software not to send warning messages to forged senders!';

	$this;
}

=pod

=item set_message(MESSAGE)

Sets the message used when rejecting messages.

This method returns a reference to the object itself, allowing this method
call to be chained.

=cut

sub set_message ($$) {
	my $this = shift;

	$this->{_message} = shift;

	$this;
}

sub header_callback {
	my $this = shift;
	my $ctx = shift;
	my $hname = shift;
	my $header = "$hname: ".(shift);

	if (
		$header =~ /^From: amavisd(?:-new)? <postmaster\@/i ||
		$header =~ /^From: MailMarshal\@\s+$/ ||
		$header =~ /^Subject: ACHTUNG! Sie haben eine mit einem Virus/ ||
		$header =~ /^Subject: Antigen found VIRUS=/ ||
		$header =~ /^Subject: AVISO DE VIRUS / ||
		$header =~ /^Subject: Warning: antivirus system report$/ ||
		$header =~ /^Subject: Disallowed attachment type found in sent message/ ||
		$header =~ /^Subject: Email violation detected in an email you sent/ ||
		$header =~ /^Subject: Failed to clean virus file/ ||
		$header =~ /^Subject: Filter scan result notification from / ||
		$header =~ /^Subject: Illegal attachment type found in sent message/ ||
		$header =~ /^Subject: InterScan NT Alert$/ ||
		$header =~ /^Subject: Mail delivery failed \(virus detected\)/ ||
		$header =~ /^Subject: MDaemon (Notification -- Attachment Removed|Warning - Virus Found)/ ||
		$header =~ /^Subject: Norton AntiVirus detected (and quarantined )?a virus/ ||
		$header =~ /^Sublect: Panda Antivirus Platinum warning$/i ||
		$header =~ /^Subject: Returned due to virus; was:/ ||
		$header =~ /^Subject: Spam mail warning notification/ ||
		$header =~ /^Subject: Virenwarnung$/ ||
		$header =~ /^Subject: Virus detected$/ ||
		$header =~ /^Subject: Virus Detected by Network Associates/ ||
		$header =~ /^Subject: (?:MailMarshal|Symantec Mail Security) (?:has )?detected / ||
		$header =~ /^Subject: (?:Warning *[:!-]* *)?(?:E-mail )?Virus(?:es)? (Alert|Detected|Found)/i ||
	0) {
		my $msg = $this->{_message};

		if (defined($msg)) {
			$ctx->setreply('554', '5.7.1', $msg);
		}

		return SMFIS_REJECT;
	}

	SMFIS_CONTINUE;
}

1;
__END__

=back

=head1 BUGS

The rules could be much simpler, but at risk of catching legit mail.
A future release will simplify the regex tests.

=head1 AUTHOR

Todd Vierling, E<lt>tv@duh.orgE<gt> E<lt>tv@pobox.comE<gt>

=head1 SEE ALSO

L<Mail::Milter::Object>

=cut
