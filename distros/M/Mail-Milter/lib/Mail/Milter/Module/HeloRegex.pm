# $Id: HeloRegex.pm,v 1.1 2004/04/12 14:24:08 tvierling Exp $
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

package Mail::Milter::Module::HeloRegex;

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

Mail::Milter::Module::HeloRegex - milter to accept/reject connections with certain HELO values

=head1 SYNOPSIS

    use Mail::Milter::Module::HeloRegex;

    my $milter = new Mail::Milter::Module::HeloRegex('^foo\.com$');

    my $milter2 = &HeloRegex('^foo\.com$'); # convenience

=head1 DESCRIPTION

This milter module rejects entire SMTP connections if the connecting client
issues a HELO command matching user-supplied regular expressions.  Note that
only the initial word of the HELO string is tested; any EHLO parameters are
not checked by the regexes.

=head1 METHODS

=over 4

=cut

our @EXPORT = qw(&HeloRegex);

sub HeloRegex {
	new Mail::Milter::Module::HeloRegex(@_);
}

=pod

=item new(REGEX[, ...])

Accepts one or more regular expressions, as strings or qr// precompiled
regexes.  They are tested in sequence, and the first match terminates
checking.

=cut

sub new ($$;@) {
	my $this = Mail::Milter::Object::new(shift);

	$this->{_message} = 'HELO parameter "%H" not permitted at this site';

	croak 'new HeloRegex: no regexes supplied' unless scalar @_;
	$this->{_regexes} = [ map qr/$_/i, @_ ];

	$this;
}

=pod

=item set_message(MESSAGE)

Sets the message used when rejecting messages.  This string may contain the
substring C<%H>, which will be replaced by the matching HELO parameter.

This method returns a reference to the object itself, allowing this method
call to be chained.

=cut

sub set_message ($$) {
	my $this = shift;

	$this->{_message} = shift;

	$this;
}

sub helo_callback {
	my $this = shift;
	my $ctx = shift;
	my $helo = shift;
	# ignore additional parameters

	foreach my $rx (@{$this->{_regexes}}) {
		if ($helo =~ $rx) {
			my $msg = $this->{_message};

			if (defined($msg)) {
				$msg =~ s/%H/$helo/g;
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
