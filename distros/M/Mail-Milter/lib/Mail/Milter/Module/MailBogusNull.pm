# $Id: MailBogusNull.pm,v 1.2 2006/03/22 15:48:23 tvierling Exp $
#
# Copyright (c) 2006 Todd Vierling <tv@pobox.com> <tv@duh.org>
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

package Mail::Milter::Module::MailBogusNull;

use 5.006;
use base Exporter;
use base Mail::Milter::Object;

use strict;
use warnings;

use Carp;
use Sendmail::Milter 0.18; # get needed constants
use Socket;
use UNIVERSAL;

our $VERSION = '0.01';

=pod

=head1 NAME

Mail::Milter::Module::MailBogusNull - milter to reject null-sender mail to multiple recipients

=head1 SYNOPSIS

    use Mail::Milter::Module::MailBogusNull;

    my $milter = new Mail::Milter::Module::MailBogusNull;

    my $milter2 = &MailBogusNull; # convenience

    $milter2->set_message('Null sender mail should go to only one recipient');

=head1 DESCRIPTION

This milter module rejects any mail from a C<null sender> (empty 
C<E<lt>E<gt>> address) which attempts to deliver to multiple recipients.  
Normal delivery status notifications are intended for a single message, and 
thus should only ever be addressed to a single recipient.

=head1 METHODS

=over 4

=cut

our @EXPORT = qw(&MailBogusNull);

sub MailBogusNull {
	new Mail::Milter::Module::MailBogusNull(@_);
}

=pod

=item new()

Creates a MailBogusNull object.  There are no arguments to configure this 
module, as it is a fixed check.

=cut

sub new ($) {
	my $this = Mail::Milter::Object::new(shift);

	$this->{_ignoretempfail} = 0;
	$this->{_message} = 'Sender <> delivery status notifications cannot be addressed to more than one recipient';

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

sub envfrom_callback {
	my $this = shift;
	my $ctx = shift;

	if (shift ne '<>') {
		$ctx->setpriv(undef);
		return SMFIS_ACCEPT;
	}
	$ctx->setpriv(0);
	SMFIS_CONTINUE;
}

sub envrcpt_callback {
	my $this = shift;
	my $ctx = shift;

	my $nullcount = $ctx->getpriv;
	$ctx->setpriv(++$nullcount);

	if ($nullcount > 1) {
		$ctx->setreply(554, '5.7.0', $this->{_message});
		return SMFIS_REJECT;
	}
	SMFIS_CONTINUE;
}

sub eoh_callback {
	my $this = shift;
	my $ctx = shift;

	if ($ctx->getpriv() > 1) {
		$ctx->setreply(554, '5.7.0', $this->{_message});
		return SMFIS_REJECT;
	}
	SMFIS_ACCEPT;
}

1;
__END__

=back

=head1 AUTHOR

Todd Vierling, E<lt>tv@duh.orgE<gt> E<lt>tv@pobox.comE<gt>

=head1 SEE ALSO

L<Mail::Milter::Object>

=cut
