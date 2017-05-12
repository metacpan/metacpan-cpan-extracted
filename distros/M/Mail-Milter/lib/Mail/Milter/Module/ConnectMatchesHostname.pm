# $Id: ConnectMatchesHostname.pm,v 1.4 2004/04/12 15:27:00 tvierling Exp $
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

package Mail::Milter::Module::ConnectMatchesHostname;

use 5.006;
use base Exporter;
use base Mail::Milter::Object;

use strict;
use warnings;

use Carp;
use Sendmail::Milter 0.18; # get needed constants
use Socket;

our $VERSION = '0.01';

=pod

=head1 NAME

Mail::Milter::Module::ConnectMatchesHostname - milter to accept/reject connecting hosts matching regex(es)

=head1 SYNOPSIS

    use Mail::Milter::Module::ConnectMatchesHostname;

    my $milter = new Mail::Milter::Module::ConnectMatchesHostname;

    my $milter2 = &ConnectMatchesHostname; # convenience

    $milter2->set_message('Connecting hostname %H looks like a dynamic address');

=head1 DESCRIPTION

This milter module rejects any connecting host whose hostname contains one
of a group of built-in patterns that match the IP address of the connecting
host.  This is normally used to detect dynamic pool addresses.

Currently the following patterns embedded in the hostname are considered
matching, where 10.11.12.13 is the IPv4 address of the connecting host.  
In the following cases, the string must be preceded by a non-digit
character or otherwise must be at the start of the hostname.

    010.011.012.013. (optionally without internal dots, or with - in place of .)
    013.012.011.010. (optionally with - in place of .)
    10.11.12.13. (optionally without internal dots, or with - in place of .)
    13.12.11.10. (optionally with - in place of .)
    0A0B0C0D (hexadecimal, ignoring case)

More specific patterns are anticipated to be added in the future.  Because
of this, if you use ConnectMatchesHostname, pay attention to this perldoc
manual page when updating to a newer version of Mail::Milter.

One final note.  ISPs can and do use "dynamic-looking" reverse DNS entries
for what they consider to be legitimate server addresses.  This is not
ideal, and may require embedding this module in a Chain set to
"accept_break" with regular expressions; for example:

    my $milter = new Mail::Milter::Chain(
        &ConnectRegex(
            '\.fooisp\.com$',
        )->accept_match(1);
        &ConnectMatchesHostname,
    )->accept_break(1);

=head1 METHODS

=over 4

=cut

our @EXPORT = qw(&ConnectMatchesHostname);

sub ConnectMatchesHostname {
	new Mail::Milter::Module::ConnectMatchesHostname(@_);
}

=pod

=item new()

Creates a ConnectMatchesHostname object.

=cut

sub new ($) {
	my $this = Mail::Milter::Object::new(shift);

	$this->{_message} = 'Connecting hostname %H looks like a dynamic pool address (contains the connecting address %A)';

	$this;
}

=pod

=item set_message(MESSAGE)

Sets the message used when rejecting connections.  This string may contain
the substring C<%H>, which will be replaced by the matching hostname, and/or
the substring C<%A>, which will be replaced by the matching IP address.

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

	return SMFIS_ACCEPT if ($hostname =~ /^\[/);

	# We want IPv4 only (for now).
	$addr = eval {
		my @unpack = unpack_sockaddr_in($pack);
		inet_ntoa($unpack[1]);
	} unless defined($addr);

	return SMFIS_ACCEPT unless defined($addr);

	my ($i1, $i2, $i3, $i4) = split(/\./, $addr);
	my $f1 = sprintf('%03d', $i1);
	my $f2 = sprintf('%03d', $i2);
	my $f3 = sprintf('%03d', $i3);
	my $f4 = sprintf('%03d', $i4);
	my $hex = sprintf('%08x', unpack('N', pack('C4', $i1, $i2, $i3, $i4)));

	if (
		$hostname =~ /(?:\A|\D)$i1[\.-]$i2[\.-]$i3[\.-]$i4\D/ ||
		$hostname =~ /(?:\A|\D)$f1[\.-]?$f2[\.-]?$f3[\.-]?$f4\D/ ||
		$hostname =~ /(?:\A|\D)$i4[\.-]$i3[\.-]$i2[\.-]$i1\D/ ||
		$hostname =~ /(?:\A|\D)$f4[\.-]?$f3[\.-]?$f2[\.-]?$f1\D/ ||
		$hostname =~ /$hex/i
	) {
		my $msg = $this->{_message};

		if (defined($msg)) {
			$msg =~ s/%H/$hostname/g;
			$msg =~ s/%A/$addr/g;
			$ctx->setreply('554', '5.7.1', $msg);
		}

		return SMFIS_REJECT;
	}

	SMFIS_ACCEPT;
}

1;
__END__

=back

=head1 BUGS

In Sendmail 8.11 and 8.12, a milter rejection at "connect" stage does not
allow the reply message to be set -- it simply becomes "not accepting
messages".  However, this module still attempts to set the reply code and
message in the hope that this will be fixed.

The implementation of this module could be much more efficient.

=head1 AUTHOR

Todd Vierling, E<lt>tv@duh.orgE<gt> E<lt>tv@pobox.comE<gt>

=head1 SEE ALSO

L<Mail::Milter::Object>

=cut
