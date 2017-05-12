# $Id: Wrapper.pm,v 1.5 2004/02/26 19:24:52 tvierling Exp $
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

package Mail::Milter::Wrapper;

use 5.006;

use strict;
use warnings;

use Carp;
use Mail::Milter;
use Sendmail::Milter 0.18; # get needed constants

our $VERSION = '0.03';

=pod

=head1 NAME

Mail::Milter::Wrapper - Perl extension for wrappering milter objects

=head1 SYNOPSIS

    use Mail::Milter::Wrapper;

    my $milter = ...;
    my $wrapper = new Mail::Milter::Wrapper($milter, \&foo);

    use Sendmail::Milter;
    ...
    Sendmail::Milter::register('foo', $wrapper, SMFI_CURR_ACTS);

=head1 DESCRIPTION

Mail::Milter::Wrapper wraps another milter, allowing for interception
of the passed arguments and/or return code of the contained milter.

=head1 METHODS

=over 4

=item new(MILTER, CODEREF[, CALLBACK ...])

Creates a Mail::Milter::Wrapper object.

MILTER is the milter to wrap, which may be a plain hash reference or an
instance of a hashref object such as C<Mail::Milter::Object>.  CODEREF is
the wrapper subroutine.  CALLBACKs, if specified, are named callbacks
which are needed by the wrapper, even if the contained milter does not use
them.

The wrapper subroutine will be called with the following arguments, in
this order:

 * reference to the wrapper
 * name of callback
 * subroutine reference to call into the wrapped milter
 * arguments for the callback (>= 0)

This subroutine should ALWAYS pass the "close" callback through to the
contained milter.  Failure to do so may corrupt the contained milter's
state information and cause memory leaks.

As an example, a simple subroutine which just passes the callback through
might be written as:

    sub callback_wrapper {
        shift; # don't need $this
        my $cbname = shift;
        my $callback_sub = shift;

        &$callback_sub(@_);
    }

=cut

sub new ($$&;@) {
	my $this = bless {}, shift;
	my $callbacks = shift;
	my $wrapper_sub = shift || croak 'new Wrapper: wrapper_sub is undef';
	my %needed_cbs = map { $_ => 1 } @_;

	my $pkg = caller;

	foreach my $cbname (keys %Sendmail::Milter::DEFAULT_CALLBACKS) {
		my $cbref = $callbacks->{$cbname};

		if (defined($cbref)) {
			$cbref = Mail::Milter::resolve_callback($cbref, $pkg);
		} elsif (defined($needed_cbs{$cbname})) {
			$cbref = sub { SMFIS_CONTINUE; };
		}

		next unless defined($cbref);

		$this->{$cbname} = sub {
			&$wrapper_sub($this, $cbname, $cbref, @_);
		};
	}

	$this;
}

1;
__END__

=back

=head1 AUTHOR

Todd Vierling, E<lt>tv@duh.orgE<gt> E<lt>tv@pobox.comE<gt>

=head1 SEE ALSO

L<Mail::Milter>, L<Sendmail::Milter>

=cut
