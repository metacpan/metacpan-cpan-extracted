# $Id: Object.pm,v 1.3 2004/02/26 19:24:51 tvierling Exp $
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

package Mail::Milter::Object;

use 5.006;
use base Exporter;

use strict;
use warnings;

use Sendmail::Milter 0.18; # get needed constants
use Symbol;
use UNIVERSAL;

our $VERSION = '0.03';

=pod

=head1 NAME

Mail::Milter::Object - Perl extension to encapsulate a milter in an object

=head1 SYNOPSIS

    package Foo;
    use base Mail::Milter::Object;

    sub connect_callback {
        my $this = shift;
        my $ctx = shift;
        my @connect_args = @_;
        ...
    }

    ...
    my $milter = new Foo;

=head1 DESCRIPTION

Normally, milters passed to C<Sendmail::Milter> consist of nondescript
hash references.  C<Mail::Milter::Object> transforms these callback hashes
into fully qualified objects that are easier to maintain and understand.
In conjunction with C<Mail::Milter::Chain>, this also allows for a more
modular approach to milter implementation, by allowing each milter to be a
small, granular object that can exist independently of other milters.

Each object inheriting from this class has access to the hash reference
making up the object itself.  Two caveats must be noted when accessing
this hashref:

* Key names used for private data should be prefixed by an underscore (_)
in order to prevent accidental recognition as a callback name.

* Since a milter object can be reused many times throughout its existence,
and perhaps reentrantly if threads are in use, the hashref should contain
only global configuration data for this object rather than per-message
data.  Data stored per message or connection should be stashed in the
milter context object by calling C<getpriv()> and C<setpriv()> on the
context object.

=head1 METHODS

=over 4

=item new()

Creates a new C<Mail::Milter::Object>.  The fully qualified class is
scanned for milter callback methods with names of the form
CALLBACK_callback.  If such a method exists, a corresponding callback
entry point is added to this object.

=cut

sub new ($) {
	my $this = bless {}, shift;

	foreach my $cbname (keys %Sendmail::Milter::DEFAULT_CALLBACKS) {
		my $fullcbname = $cbname.'_callback';
		next unless (UNIVERSAL::can($this, $fullcbname));

		$this->{$cbname} = sub {
			$this->$fullcbname(@_);
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

L<Mail::Milter>, L<Sendmail::Milter>.

=cut
