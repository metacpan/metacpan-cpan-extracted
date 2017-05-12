# $Id: ConnectRegex.pm,v 1.10 2004/02/26 19:24:52 tvierling Exp $
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

package Mail::Milter::Module::ConnectRegex;

use 5.006;
use base Exporter;
use base Mail::Milter::Object;

use strict;
use warnings;

use Carp;
use Sendmail::Milter 0.18; # get needed constants
use Socket;

our $VERSION = '0.03';

=pod

=head1 NAME

Mail::Milter::Module::ConnectRegex - milter to accept/reject connecting hosts matching regex(es)

=head1 SYNOPSIS

    use Mail::Milter::Module::ConnectRegex;

    my $milter = new Mail::Milter::Module::ConnectRegex('^foo$');

    my $milter2 = &ConnectRegex(qw{^foo$ ^bar$}); # convenience

    $milter2->set_message('Connections from %H disallowed');

=head1 DESCRIPTION

This milter module rejects any connecting host whose hostname or IP address
matches user-supplied regular expressions.  It can also function as a
whitelisting Chain element; see C<accept_match()>.

=head1 METHODS

=over 4

=cut

our @EXPORT = qw(&ConnectRegex);

sub ConnectRegex {
	new Mail::Milter::Module::ConnectRegex(@_);
}

=pod

=item new(REGEX[, ...])

Accepts one or more regular expressions, as strings or qr// precompiled
regexes.  They are tested in sequence, and the first match terminates
checking.  Note that all IP address literals will be enclosed in [square
brackets]; so to test an IP address rather than a hostname, ensure those
brackets exist:

    ^\[ADDRESS\]$

=cut

sub new ($$;@) {
	my $this = Mail::Milter::Object::new(shift);

	$this->{_accept} = 0;
	$this->{_message} = 'Not accepting connections from %H';

	croak 'new ConnectRegex: no regexes supplied' unless scalar @_;
	$this->{_regexes} = [ map qr/$_/i, @_ ];

	$this;
}

=pod

=item accept_match(FLAG)

If FLAG is 0 (the default), a matching regex will cause the connection to
be rejected.

If FLAG is 1, a matching regex will cause this module to return SMFIS_ACCEPT
instead.  This allows a C<ConnectRegex> to be used inside a
C<Mail::Milter::Chain> container (in C<accept_break(1)> mode), to function
as a whitelist rather than a blacklist.

This method returns a reference to the object itself, allowing this method
call to be chained.

=cut

sub accept_match ($$) {
	my $this = shift;
	my $flag = shift;

	croak 'accept_match: flag argument is undef' unless defined($flag);
	$this->{_accept} = $flag;

	$this;
}

=pod

=item set_message(MESSAGE)

Sets the message used when rejecting connections.  This string may contain
the substring C<%H>, which will be replaced by the matching hostname or IP
address.

This method returns a reference to the object itself, allowing this method
call to be chained.

=cut

sub set_message ($$) {
	my $this = shift;

	$this->{_message} = shift;

	$this;
}

sub connect_callback {
	my $this = shift;
	my $ctx = shift;
	my $hostname = shift;
	my $pack = shift;
	my $addr;

	if ($hostname =~ /^\[/) {
		$addr = $hostname;
		undef $hostname;
	}

	# First try IPv4 unpacking.
	$addr = eval {
		my @unpack = unpack_sockaddr_in($pack);
		'['.inet_ntoa($unpack[1]).']';
	} unless defined($addr);

	$addr = eval {
		require Socket6;
		my @unpack = Socket6::unpack_sockaddr_in6($pack);
		'['.Socket6::inet_ntop(&Socket6::AF_INET6, $unpack[1]).']';
	} unless defined($addr);

	foreach my $rx (@{$this->{_regexes}}) {
		my $match;

		if (defined($hostname) && $hostname =~ $rx) {
			$match = $hostname;
		} elsif (defined($addr) && $addr =~ $rx) {
			$match = $addr;
		}

		if (defined($match)) {
			my $msg = $this->{_message};

			return SMFIS_ACCEPT if $this->{_accept};

			if (defined($msg)) {
				$msg =~ s/%H/$match/g;
				$ctx->setreply('554', '5.7.1', $msg);
			}

			return SMFIS_REJECT;
		}
	}

	SMFIS_CONTINUE; # don't whitelist a fallthrough
}

1;
__END__

=back

=head1 BUGS

In Sendmail 8.11 and 8.12, a milter rejection at "connect" stage does not
allow the reply message to be set -- it simply becomes "not accepting
messages".  However, this module still attempts to set the reply code and
message in the hope that this will be fixed.

=head1 AUTHOR

Todd Vierling, E<lt>tv@duh.orgE<gt> E<lt>tv@pobox.comE<gt>

=head1 SEE ALSO

L<Mail::Milter::Object>

=cut
