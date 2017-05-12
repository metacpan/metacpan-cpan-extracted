# $Id: HeaderRegex.pm,v 1.5 2004/04/12 14:21:41 tvierling Exp $
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

package Mail::Milter::Module::HeaderRegex;

use 5.006;
use base Exporter;
use base Mail::Milter::Object;

use strict;
use warnings;

use Carp;
use Sendmail::Milter 0.18; # get needed constants

our $VERSION = '0.03';

=pod

=head1 NAME

Mail::Milter::Module::HeaderRegex - milter to accept/reject messages with certain headers

=head1 SYNOPSIS

    use Mail::Milter::Module::HeaderRegex;

    my $milter = new Mail::Milter::Module::HeaderRegex('^Foo: ');

    my $milter2 = &HeaderRegex('^Foo: Bar'); # convenience

=head1 DESCRIPTION

This milter module rejects messages at DATA phase if one of the message's
headers matches user-supplied regular expressions.

=head1 METHODS

=over 4

=cut

our @EXPORT = qw(&HeaderRegex);

sub HeaderRegex {
	new Mail::Milter::Module::HeaderRegex(@_);
}

=pod

=item new(REGEX[, ...])

Accepts one or more regular expressions, as strings or qr// precompiled
regexes.  They are tested in sequence, and the first match terminates
checking.

=cut

sub new ($$;@) {
	my $this = Mail::Milter::Object::new(shift);

	$this->{_message} = 'Malformed or invalid header %H: in message';

	croak 'new HeaderRegex: no regexes supplied' unless scalar @_;
	$this->{_regexes} = [ map qr/$_/i, @_ ];

	$this;
}

=pod

=item set_message(MESSAGE)

Sets the message used when rejecting messages.  This string may contain the
substring C<%H>, which will be replaced by the matching header name.

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

	foreach my $rx (@{$this->{_regexes}}) {
		if ($header =~ $rx) {
			my $msg = $this->{_message};

			if (defined($msg)) {
				$msg =~ s/%H/$hname/g;
				$ctx->setreply('554', '5.7.1', $msg);
			}

			return SMFIS_REJECT;
		}
	}

	SMFIS_CONTINUE;
}

1;
__END__

=back

=head1 AUTHOR

Todd Vierling, E<lt>tv@duh.orgE<gt> E<lt>tv@pobox.comE<gt>

=head1 SEE ALSO

L<Mail::Milter::Object>

=cut
