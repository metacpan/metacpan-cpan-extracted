# $Id: HeloUnqualified.pm,v 1.4 2004/02/26 19:24:52 tvierling Exp $
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

package Mail::Milter::Module::HeloUnqualified;

use 5.006;
use base Exporter;
use base Mail::Milter::Object;

use strict;
use warnings;

use Sendmail::Milter 0.18; # get needed constants

our $VERSION = '0.03';

=pod

=head1 NAME

Mail::Milter::Module::HeloUnqualified - milter to check for an unqualified HELO name

=head1 SYNOPSIS

    use Mail::Milter::Module::HeloUnqualified;

    my $milter = new Mail::Milter::Module::HeloUnqualified([EXCEPT]);

    my $milter2 = &HeloUnqualified([EXCEPT]); # convenience

=head1 DESCRIPTION

This milter module rejects any domain name that HELOs without a dot, and
which is not an IPv4/IPv6 literal.  Whether or not the HELO value
corresponds to the connecting host is not checked by this module.

If the EXCEPT argument is supplied, it should be a regex enclosed in a
string which will be exempted from this check.  Commonly, '^localhost' is
excepted.

=cut

our @EXPORT = qw(&HeloUnqualified);

sub HeloUnqualified {
	new Mail::Milter::Module::HeloUnqualified(@_);
}

sub new ($;$) {
	my $this = Mail::Milter::Object::new(shift);
	my $except = shift;

	$this->{_except} = qr/$except/i if defined($except);

	$this;
}

sub helo_callback {
	my $this = shift;
	my $ctx = shift;
	my $helo = shift;

	if (($helo !~ /\./) && ($helo !~ /^\[.*\]$/) &&
	    !(defined($this->{_except}) && $helo =~ $this->{_except})) {
		$ctx->setreply("554", "5.7.1", "HELO/EHLO $helo: command rejected: domain name not qualified");
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
