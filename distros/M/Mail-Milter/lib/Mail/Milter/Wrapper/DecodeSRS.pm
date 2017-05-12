# $Id: DecodeSRS.pm,v 1.2 2004/12/15 17:47:07 tvierling Exp $
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

package Mail::Milter::Wrapper::DecodeSRS;

use 5.006;
use base Exporter;
use base Mail::Milter::Wrapper;

use strict;
use warnings;

use Carp;
use Mail::Milter::ContextWrapper;
use Sendmail::Milter 0.18; # get needed constants

our $VERSION = '0.02';

=pod

=head1 NAME

Mail::Milter::Wrapper::DecodeSRS - milter wrapper to decode SRS-encoded return path

=head1 SYNOPSIS

    use Mail::Milter::Wrapper::DecodeSRS;

    my $milter = ...;
    my $wrapper = new Mail::Milter::Wrapper::DecodeSRS($milter);

    my $wrapper2 = &DecodeSRS($milter); # convenience

=head1 DESCRIPTION

Mail::Milter::Wrapper::DecodeSRS is a convenience milter wrapper which 
decodes MAIL FROM: return paths which have been encoded by the Sender 
Rewrite Scheme, SRS.  (More information:  http://www.libsrs2.org/)
This wrapper internally understands both the SRS0 and SRS1 encoding 
schemes documented by the Mail::SRS author.

The decoded address is made available to the contained milter via the 
C<envfrom> callback, in the same way that a raw address would.

NOTE:  If the address is not SRS encoded, the contained milter is NOT 
called for the duration of the message; instead, SMFIS_ACCEPT is returned. 
This is because the milter writer is expected to use this wrapper in a 
chain that also includes the contained milter without wrapping, in order 
to prevent a malicious sender from using SRS to bypass access checks.  

For instance, the following is a proper usage of this wrapper in a chain:

    my $envfrommilter = ...;

    my $combinedmilter = new Mail::Milter::Chain(
        new Mail::Milter::Wrapper::UnwrapSRS($envfrommilter),
        $envfrommilter
    );

This behavior can also be used if, e.g., the MTA already does one form of 
MAIL FROM: check, and the contained milter repeats that same database 
check against SRS rewritten addresses.  (A good example would be a milter 
emulating Sendmail's access_db map.)

=cut

our @EXPORT = qw(&DecodeSRS);

sub DecodeSRS {
	new Mail::Milter::Wrapper::DecodeSRS(@_);
}

sub new ($$) {
	my $this = Mail::Milter::Wrapper::new(shift, shift,
		\&wrapper, qw{connect close});

	$this;
}

# internal methods
sub wrapper {
	my $this = shift;
	my $cbname = shift;
	my $callback_sub = shift;

	if ($cbname eq 'envfrom') {
		my $addr = $_[1];

		# Mail::SRS::Guarded SRS1: strip to Mail::SRS::Guarded SRS0
		$addr =~ s/^<SRS1[=\+-](?:[^=]+=)?[^=]+\.[^=]+=[=\+-]/SRS0=/;

		if ($addr =~ /^<SRS0[=\+-][^=]+=(?:[^=]+=)?([^=]+\.[^=]+)=(.+)\@/) {
			# Mail::SRS::Guarded SRS0
			$_[1] = "<$2\@$1>";
		} else {
			return SMFIS_ACCEPT; # skip this message
		}
	}

	&$callback_sub(@_);
}

1;
__END__

=head1 AUTHOR

Todd Vierling, E<lt>tv@duh.orgE<gt> E<lt>tv@pobox.comE<gt>

=head1 SEE ALSO

L<Mail::Milter::Wrapper>

=cut
