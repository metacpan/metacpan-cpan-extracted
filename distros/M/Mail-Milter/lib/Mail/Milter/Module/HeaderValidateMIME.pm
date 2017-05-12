# $Id: HeaderValidateMIME.pm,v 1.1 2006/03/21 20:27:25 tvierling Exp $
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

package Mail::Milter::Module::HeaderValidateMIME;

use 5.006;
use base Exporter;
use base Mail::Milter::Object;

use strict;
use warnings;

use Sendmail::Milter 0.18; # get needed constants

our $VERSION = '0.01';

=pod

=head1 NAME

Mail::Milter::Module::HeaderValidateMIME - enforce MIME header conformance

=head1 SYNOPSIS

    use Mail::Milter::Module::HeaderValidateMIME;

    my $milter = new Mail::Milter::Module::HeaderValidateMIME();

    my $milter2 = &HeaderValidateMIME; # convenience

=head1 DESCRIPTION

This milter module rejects any message at the DATA stage that has one of
the Content-Type: or MIME-Version: headers, but not the other.  In the
future, this module may enforce stricter MIME checks.

=cut

our @EXPORT = qw(&HeaderValidateMIME);

sub HeaderValidateMIME {
	new Mail::Milter::Module::HeaderValidateMIME(@_);
}

sub envfrom_callback {
	shift; # $this
	my $ctx = shift;

	$ctx->setpriv({});

	SMFIS_CONTINUE;
}

sub header_callback {
	shift; # $this
	my $ctx = shift;
	my $hname = lc(shift);
	my $priv = $ctx->getpriv();

	if ($hname eq 'content-type' || $hname eq 'mime-version') {
		$priv->{$hname} = 1;
	}

	SMFIS_CONTINUE;
}

sub eoh_callback {
	shift; # $this
	my $ctx = shift;
	my $priv = $ctx->getpriv();

	if (defined($priv->{'content-type'}) xor defined($priv->{'mime-version'})) {
		$ctx->setreply("554", "5.6.0", "Message is corrupt -- RFC2047: MIME-Version and Content-Type must be used together, or not at all");
		return SMFIS_REJECT;
	}

	SMFIS_ACCEPT;
}

1;
__END__

=head1 AUTHOR

Todd Vierling, E<lt>tv@duh.orgE<gt> E<lt>tv@pobox.comE<gt>

=head1 SEE ALSO

L<Mail::Milter::Object>

=cut
