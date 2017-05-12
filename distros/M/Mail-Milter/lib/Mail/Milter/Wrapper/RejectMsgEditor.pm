# $Id: RejectMsgEditor.pm,v 1.6 2004/02/26 19:24:53 tvierling Exp $
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

package Mail::Milter::Wrapper::RejectMsgEditor;

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

Mail::Milter::Wrapper::RejectMsgEditor - milter wrapper to edit rejection messages

=head1 SYNOPSIS

    use Mail::Milter::Wrapper::RejectMsgEditor;

    my $milter = ...;
    my $wrapper = new Mail::Milter::Wrapper::RejectMsgEditor($milter, \&sub);

    my $wrapper2 = &RejectMsgEditor($milter, \&sub); # convenience

=head1 DESCRIPTION

Mail::Milter::Wrapper::RejectMsgEditor is a convenience milter wrapper
which allows editing of the messages returned for all SMFIS_REJECT
rejections.  The subroutine provided should edit $_ and need not return
any value.

If the contained milter did not call C<$ctx->setreply()> before returning
a rejection code, then a default message will be used.

For example:

    my $wrapped_milter = &RejectMsgEditor($milter, sub {
        s,$, - Please e-mail postmaster\@foo.com for assistance.,
    });

=cut

our @EXPORT = qw(&RejectMsgEditor);

sub RejectMsgEditor {
	new Mail::Milter::Wrapper::RejectMsgEditor(@_);
}

sub new ($$\&) {
	my $this = Mail::Milter::Wrapper::new(shift, shift,
		\&wrapper, qw{connect close});

	$this->{_editor} = shift;

	$this;
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

	my $rc = &$callback_sub($newctx, @_);
	my $reply = $newctx->get_key('reply');
	$newctx->set_key(reply => undef);

	if ($rc == SMFIS_REJECT) {
		$reply = [ 554, '5.7.0', 'Command rejected' ] unless $reply;

		local $_ = $reply->[2];
		&{$this->{_editor}};
		$reply->[2] = $_;
	}

	$oldctx->setreply(@$reply) if $reply;
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
