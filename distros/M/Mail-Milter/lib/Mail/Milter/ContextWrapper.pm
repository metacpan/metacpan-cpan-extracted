# $Id: ContextWrapper.pm,v 1.4 2004/02/26 19:24:50 tvierling Exp $
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

package Mail::Milter::ContextWrapper;

use 5.006;

use strict;
use warnings;

use Carp;
use Sendmail::Milter 0.18; # get needed constants

our $VERSION = '0.03';
our $AUTOLOAD;

=pod

=head1 NAME

Mail::Milter::ContextWrapper - Perl extension for wrappering the milter context

=head1 SYNOPSIS

    use Mail::Milter::ContextWrapper;

    my $oldctx = ($ctx from callback);

    # in the connect_callback
    $oldctx->setpriv(new Mail::Milter::ContextWrapper($ctx,
        { methodname => \&methodimpl[, ...] }));

    # in all callbacks
    my $newctx = $ctx->getpriv();

    # in the close_callback
    $oldctx->setpriv(undef);

=head1 DESCRIPTION

Mail::Milter::ContextWrapper wraps the milter context with replacement
methods defined by the caller.  This can be used to intercept context
object actions and manipulate them from within a Mail::Milter::Wrapper.

Because the wrappering must occur on every callback, this implementation
suggests embedding the wrapper inside the private data of the milter
itself.  This works with existing milters by providing separate "setpriv"
and "getpriv" methods within the wrapper that do not propagate up to the
embedded context object.

=head1 METHODS

=over 4

=item new(CTX, { NAME => \&SUB[, ...] })

Creates a Mail::Milter::ContextWrapper object.  This should be called from
the "connect" callback and passed back to C<setpriv()>.

NAMEs are names of methods to override within the wrapper.  These methods
will be called with the wrapper as first argument (like a normal object
method).

=cut

sub new ($$$) {
	my $this = bless {}, shift;

	$this->{ctx} = shift;
	$this->{methods} = shift;

	$this->{keys} = {};

	$this;
}

# private autoloader method
sub AUTOLOAD {
	my $sub = $AUTOLOAD;
	my $this = $_[0];

	$sub =~ s/^Mail::Milter::ContextWrapper:://;
	my $subref = $this->{methods}{$sub};

	$subref = sub {
		my $this = shift;
		$this->get_ctx()->$sub(@_);
	} unless defined($subref);

	goto &$subref;
}

# since AUTOLOAD is here, we need a DESTROY
sub DESTROY {
	my $this = shift;
	%$this = ();
}

=pod

=item getpriv()

Returns a private data item set by C<setpriv()>.  See L<Sendmail::Milter>
for more information.  This implementation stores the datum in the
wrapper, thus allowing the parent context to store a reference to the
wrapper itself.

This method cannot be overridden by the user.

=cut

sub getpriv ($) {
	my $this = shift;

	$this->{priv};
}

=pod

=item get_ctx()

Returns the parent context object stored within this wrapper.  Typically
used by method overrides to defer back to the real method.

This method cannot be overridden by the user.

=cut

sub get_ctx ($) {
	my $this = shift;

	$this->{ctx};
}

=pod

=item get_key(NAME)

Get a keyed data item separate from the C<getpriv> private data.  This
provides out-of-band data storage that need not clobber the single "priv"
data item used by most milters.

=cut

sub get_key ($$) {
	my $this = shift;
	my $key = shift;

	$this->{keys}{$key};
}

=pod

=item getpriv()

Sets a private data item to be returned by C<getpriv()>.  See
L<Sendmail::Milter> for more information.  This implementation stores the
datum in the wrapper, thus allowing the parent context to store a
reference to the wrapper itself.

This method cannot be overridden by the user.

=cut

sub setpriv ($) {
	my $this = shift;

	$this->{priv} = shift;
	1;
}

=pod

=item set_key(NAME, VALUE)

=item set_key(NAME => VALUE)

Set a keyed data item separate from the C<getpriv> private data.  This
provides out-of-band data storage that need not clobber the single "priv"
data item used by most milters.

=cut

sub set_key ($$$) {
	my $this = shift;
	my $key = shift;

	$this->{keys}{$key} = shift;
	1;
}

1;
__END__

=back

=head1 AUTHOR

Todd Vierling, E<lt>tv@duh.orgE<gt> E<lt>tv@pobox.comE<gt>

=head1 SEE ALSO

L<Mail::Milter>, L<Sendmail::Milter>

=cut
