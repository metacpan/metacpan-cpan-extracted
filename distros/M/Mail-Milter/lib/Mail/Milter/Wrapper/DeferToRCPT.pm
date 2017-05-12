# $Id: DeferToRCPT.pm,v 1.8 2004/04/23 15:54:14 tvierling Exp $
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

package Mail::Milter::Wrapper::DeferToRCPT;

use 5.006;
use base Exporter;
use base Mail::Milter::Wrapper;

use strict;
use warnings;

use Carp;
use Mail::Milter::ContextWrapper;
use Sendmail::Milter 0.18; # get needed constants

our $VERSION = '0.03';

=pod

=head1 NAME

Mail::Milter::Wrapper::DeferToRCPT - milter wrapper to delay failure returns

=head1 SYNOPSIS

    use Mail::Milter::Wrapper::DeferToRCPT;

    my $milter = ...;
    my $wrapper = new Mail::Milter::Wrapper::DeferToRCPT($milter);

    my $wrapper2 = &DeferToRCPT($milter); # convenience

=head1 DESCRIPTION

Mail::Milter::Wrapper::DeferToRCPT is a convenience milter wrapper which
defers any error return during the "connect", "helo", and/or "envfrom"
callbacks to the "envrcpt" callback.

Many broken client mailers exist in the real world and will do such things
as instantaneously reconnect when receiving an error at the MAIL FROM:
stage.  This wrapper ensures that errors are never propagated back to the
MTA until at least the RCPT TO: phase.

Errors in "connect" and "helo" will apply to the entire SMTP transaction.  
Errors in "envfrom" will only apply to that particular message.

This wrapper can also be used to enhance logging.  Though the contained
milter may wish to reject a mail in progress, it may be useful for logging
purposes to capture the HELO string, sender, and recipient addresses of
each attempted mail.

=cut

our @EXPORT = qw(&DeferToRCPT);

sub DeferToRCPT {
	new Mail::Milter::Wrapper::DeferToRCPT(@_);
}

sub new ($$) {
	Mail::Milter::Wrapper::new(shift, shift,
		\&wrapper, qw{connect envfrom envrcpt close});
}

# internal methods
sub wrapper {
	my $this = shift;
	my $cbname = shift;
	my $callback_sub = shift;
	my $oldctx = shift;

	my $newctx = $oldctx->getpriv();

	unless (defined($newctx)) {
		$newctx = new Mail::Milter::ContextWrapper($oldctx, {
			setreply => sub { shift->set_key(reply => [ @_ ]); },
		});
		$oldctx->setpriv($newctx);
	}

	# If rejection is pending, "stage" has the value:
	# 0, if rejected in "connect" or "helo" for whole connection.
	# 1, if rejected in "envfrom".
	# 2, if rejected in "envrcpt" or later.

	my $rc = $newctx->get_key('rc');

	if ($cbname eq 'connect' || $cbname eq 'close') {
		#
		# Always start fresh.
		#
		$newctx->set_key(stage => 0);
		$newctx->set_key(reply => undef);
		$newctx->set_key(rc => ($rc = SMFIS_CONTINUE));
	} elsif ($cbname eq 'envfrom') {
		#
		# If we've reached this point naturally or the last
		# reject was in "envfrom", then reset state.
		#
		if ($rc == SMFIS_CONTINUE || $newctx->get_key('stage') >= 1) {
			$newctx->set_key(stage => 1);
			$newctx->set_key(reply => undef);
			$newctx->set_key(rc => ($rc = SMFIS_CONTINUE));
		}
	} elsif ($cbname eq 'envrcpt') {
		#
		# If we've reached this point naturally, then reset state.
		#
		if ($rc == SMFIS_CONTINUE) {
			$newctx->set_key(stage => 2);
			$newctx->set_key(reply => undef);
			$newctx->set_key(rc => $rc);
		}
	}

	# Only call the callback if there is not a pending error.
	$rc = &$callback_sub($newctx, @_) if ($rc == SMFIS_CONTINUE);

	if (($cbname eq 'connect' || $cbname eq 'helo' || $cbname eq 'envfrom') &&
	    ($rc == SMFIS_TEMPFAIL || $rc == SMFIS_REJECT)) {
		#
		# Convert error to pending, and return CONTINUE.
		#
		$newctx->set_key(rc => $rc);
		$rc = SMFIS_CONTINUE;
	}

	# Propagate the replycode only if we'll be returning an error.
	if ($rc == SMFIS_TEMPFAIL || $rc == SMFIS_REJECT) {
		my $reply = $newctx->get_key('reply');

		if ($reply) {
			$reply->[0] = 550 if ($reply->[0] == 554);
			$oldctx->setreply(@$reply);
		}
	}

	if ($newctx->get_key('stage') >= 2) {
		#
		# If we weren't rejected in stages 0 or 1, then reset state.
		#
		$newctx->set_key(rc => SMFIS_CONTINUE);
		$newctx->set_key(reply => undef);
	} 

	$oldctx->setpriv(undef) if ($cbname eq 'close');

	$rc;
}

1;
__END__

=head1 AUTHOR

Todd Vierling, E<lt>tv@duh.orgE<gt> E<lt>tv@pobox.comE<gt>

=head1 SEE ALSO

L<Mail::Milter::Wrapper>

=cut
