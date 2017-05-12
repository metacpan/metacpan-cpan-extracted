# $Id: AccessDB.pm,v 1.3 2004/12/29 04:39:35 tvierling Exp $
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

package Mail::Milter::Module::AccessDB;

use 5.006;
use base Exporter;
use base Mail::Milter::Object;

use strict;
use warnings;

use Carp;
use Net::DNS; # XXX should be optional (needed for MX: tagged check)
use Sendmail::Milter 0.18; # get needed constants
use Socket;
use UNIVERSAL;

our $VERSION = '0.01';
our $DEBUGLEVEL = 0;

=pod

=head1 NAME

Mail::Milter::Module::AccessDB - emulator for Sendmail "access_db" in a milter

=head1 SYNOPSIS

    use Mail::Milter::Module::AccessDB;

    my $milter = new Mail::Milter::Module::AccessDB(\%hashref);

    my $milter2 = &AccessDB(\%hashref); # convenience

=head1 DESCRIPTION

Sendmail's "access_db" is a powerful access restriction database tool, but 
it is limited only to data explicitly available through the SMTP session.  
This milter module allows rewriting to take place (such as through 
Mail::Milter::Wrapper::DecodeSRS) before applying the access rules.

Not all access_db functionality is duplicated here; some is unimplemented, 
while some is Sendmail-internal only.  See DATABASE FORMAT, below, for a 
list of supported tags and result codes in this module.

NOTE:  As of this version, this module might not be thread-safe.  A future 
version of this module will share the hashref between threads and lock it 
properly.

ESPECIALLY NOTE:  This module is highly experimental, does not support all
accessdb data types yet, and is not guaranteed to work at all.  Feel free
to try it out and to send comments to the author, but it is not yet
recommended to use this module in a production setup.

=head1 DATABASE FORMAT

[XXX: TBD]

=head1 METHODS

=over 4

=cut

our @EXPORT = qw(&AccessDB);

sub AccessDB {
	new Mail::Milter::Module::AccessDB(@_);
}

=pod

=item new(HASHREF)

Create this milter using a provided hash reference.  This may be a tied 
hash, such as to an already opened Sendmail-style database.

Currently there is no support for automatically reopening databases, hence 
this one-shot constructor.  (Sendmail does not support automatic reopening 
either, for that matter.)

=cut

sub new ($$) {
	my $this = Mail::Milter::Object::new(shift);
	my $hashref = shift;

	$this->{_ignoretempfail} = 0;
	$this->{_message} = '[%0] Access denied';
	croak 'new AccessDB: no hashref supplied' unless UNIVERSAL::isa($hashref, 'HASH');
	$this->{_db} = $hashref;

	$this;
}

=pod

=item ignore_tempfail(FLAG)

If FLAG is 0 (the default), a DNS lookup which fails the underlying DNS
query will cause the milter to return a temporary failure result
(SMFIS_TEMPFAIL).

If FLAG is 1, a temporary DNS failure will be treated as if the lookup
resulted in an empty record set (SMFIS_CONTINUE).

This method returns a reference to the object itself, allowing this method
call to be chained.

=cut

sub ignore_tempfail ($$) {
	my $this = shift;
	my $flag = shift;

	croak 'ignore_tempfail: flag argument is undef' unless defined($flag);
	$this->{_ignoretempfail} = $flag;

	$this;
}

=pod

=item set_message(MESSAGE)

Sets the message used when rejecting messages.  This string may contain 
the substring C<%0>, which will be replaced by the matching lookup key 
(not including type tag).

This method returns a reference to the object itself, allowing this method
call to be chained.

=cut

sub set_message ($$) {
	my $this = shift;

	$this->{_message} = shift;

	$this;
}

sub LookUpAddress ($$$) {
	my $this = shift;
	my $key = shift;
	my $tag = shift;
	my $db = $this->{_db};
	my $rv;

	print STDERR "$$: LookUpAddress: $tag:$key\n" if ($DEBUGLEVEL > 1);

	# lookup with tag
	$rv = $db->{"$tag:$key"};

	# lookup without tag
	$rv = $db->{$key} unless defined($rv);

	# found SKIP: return <default>
	return undef if (defined($rv) && $rv eq 'SKIP');

	# no match: remove last part
	$rv = $this->LookUpAddress($1, $tag)
		if (!defined($rv) && ($key =~ /^(.+)[:\.]+[^:\.]+$/));

	# match: return result
	$rv;
}

sub LookUpDomain ($$$) {
	my $this = shift;
	my $key = shift;
	my $tag = shift;
	my $db = $this->{_db};
	my $rv;

	print STDERR "$$: LookUpDomain: $tag:$key\n" if ($DEBUGLEVEL > 1);

	# lookup with tag (in front, no delimiter here)
	$rv = $db->{"$tag:$key"};

	# lookup without tag?
	$rv = $db->{$key} unless defined($rv);

	# LOOKUPDOTDOMAIN
	# XXX apply this also to IP addresses?
	# currently it works the wrong way round for [1.2.3.4]
	if (!defined($rv) && ($key =~ /^[^\.]+(\..+)$/)) {
		$rv = $db->{"$tag:$1"};
		$rv = $db->{$1} unless defined($rv);
	}

	# found SKIP: return <default>
	return undef if (defined($rv) && $rv eq 'SKIP');

	# not found: net
	return $this->LookUpDomain("[$1]", $tag)
		if (!defined($rv) && ($key =~ /^\[(.+)[:\.]+[^:\.]+\]$/));

	# not found, but subdomain: try again
	return $this->LookUpDomain($1, $tag)
		if (!defined($rv) && ($key =~ /^[^\.]+\.(.+)$/));

	# return <result of lookup>
	$rv;
}

sub LookUpExact ($$$) {
	my $this = shift;
	my $key = shift;
	my $tag = shift;
	my $db = $this->{_db};
	my $rv;

	print STDERR "$$: LookUpExact: $tag:$key\n" if ($DEBUGLEVEL > 1);

	$rv = $db->{"$tag:$key"};
	$rv = $db->{$key} unless defined($rv);

	$rv;
}

sub LookUpFull ($$$) {
	my $this = shift;
	my $key = shift;
	my $tag = shift;
	my $db = $this->{_db};
	my $rv;

	print STDERR "$$: LookUpFull: $tag:$key\n" if ($DEBUGLEVEL > 1);

	$rv = $db->{"$tag:$key"};
	$rv = $db->{$key} unless defined($rv);

	if (!defined($rv) && ($key =~ /^(.+)\+[^\+]*\@(.+)$/)) {
		$rv = $db->{"$tag:$1+*\@$2"};
		$rv = $db->{"$1+*\@$2"} unless defined($rv);
		$rv = $db->{"$tag:$1\@$2"} unless defined($rv);
		$rv = $db->{"$1\@$2"} unless defined($rv);
	}

	$rv;
}

sub LookUpUser ($$$) {
	my $this = shift;
	my $key = shift; # must end in @ just like in sendmail ruleset
	my $tag = shift;
	my $db = $this->{_db};
	my $rv;

	print STDERR "$$: LookUpUser: $tag:$key\n" if ($DEBUGLEVEL > 1);

	$rv = $db->{"$tag:$key"};
	$rv = $db->{$key} unless defined($rv);

	if (!defined($rv) && ($key =~ /^(.+)\+[^\+]*\@$/)) {
		$rv = $db->{"$tag:$1+*\@"};
		$rv = $db->{"$1+*\@"} unless defined($rv);
		$rv = $db->{"$tag:$1\@"} unless defined($rv);
		$rv = $db->{"$1\@"} unless defined($rv);
	}

	$rv;
}

sub TranslateValue ($$$$) {
	my $this = shift;
	my $ctx = shift;
	my $key = shift;
	my $value = shift;

	$value = "ERROR:\"554 $this->{_message}\""
		if ($value =~ /^REJECT\s*$/);

	$value =~ s/\s+$//;
	$value =~ s/\%0/$key/g;

	print STDERR "accessdb: $key: $value\n" if ($DEBUGLEVEL > 0);

	if ($value eq 'OK' || $value eq 'RELAY') {

		return SMFIS_CONTINUE;

	} elsif ($value =~ /^QUARANTINE:/) {

		# XXX not yet supported
		return SMFIS_CONTINUE;

	} elsif ($value =~ /^ERROR:([45]\.\d\.\d):"(([45])\d\d) (.*)"$/) {

		$ctx->setreply($2, $1, $4);
		return ($3 eq '5' ? SMFIS_REJECT : SMFIS_TEMPFAIL);

	} elsif ($value =~ /^(?:ERROR:)?"(([45])\d\d) (.*)"$/) {

		$ctx->setreply($1, substr($1, 0, 1).'.7.0', $3);
		return ($2 eq '5' ? SMFIS_REJECT : SMFIS_TEMPFAIL);

	} else {
		print STDERR "AccessDB: $key: unparseable result: $value\n";
	}

	SMFIS_TEMPFAIL;
}

sub connect_callback {
	my $this = shift;
	my $ctx = shift;
	my $hostname = lc(shift);
	my $pack = shift;
	my $value;

	return $this->TranslateValue($ctx, $hostname, $value)
		if defined($value = $this->LookUpDomain($hostname, 'connect'));

	# First try IPv4 unpacking.
	my $addr = eval {
		my @unpack = unpack_sockaddr_in($pack);
		inet_ntoa($unpack[1]);
	};

	$addr = eval {
		require Socket6;
		my @unpack = Socket6::unpack_sockaddr_in6($pack);
		Socket6::inet_ntop(&Socket6::AF_INET6, $unpack[1]);
	} unless defined($addr);

	if (defined($addr)) {
		return $this->TranslateValue($ctx, $addr, $value)
			if defined($value = $this->LookUpAddress($addr, 'connect'));
	}

	SMFIS_CONTINUE;
}

sub helo_callback {
	# XXX need something here
	SMFIS_CONTINUE;
}

sub envfrom_callback {
	my $this = shift;
	my $ctx = shift;
	my $from = lc(shift);
	my $value;

	print STDERR "$$: envfrom: $from\n" if ($DEBUGLEVEL > 1);

	$from =~ s/^<(.*)>$/$1/; # remove angle brackets

	return $this->TranslateValue($ctx, $from, $value)
		if defined($value = $this->LookUpFull($from, 'from'));

	$from =~ /^([^\@]+)(?:|\@([^\@]+))$/;
	my $user = $1;
	my $domain = $2;

	return $this->TranslateValue($ctx, $from, $value)
		if defined($value = $this->LookUpUser("$user\@", 'from'));

	return $this->TranslateValue($ctx, $from, $value)
		if (defined($domain) && defined($value = $this->LookUpDomain($domain, 'from')));

	# OK, no direct match.  Get the MX record(s) for the domain and try those.
	if (defined($domain)) {
		my $res = new Net::DNS::Resolver;
		my $query = $res->query($domain, 'MX');

		if (defined($query)) {
			foreach my $rr (grep { $_->type eq 'MX' } $query->answer) {
				my $mx = $rr->exchange;
				next if ($mx eq ''); # want to reject? Use MailDomainDotMX.

				print STDERR "$$: envfrom: MX:$mx\n" if ($DEBUGLEVEL > 2);

				return $this->TranslateValue($ctx, $from, $value)
					if (defined($domain) && defined($value = $this->LookUpDomain($mx, 'mx')));
			}
		} elsif (!$this->{_ignoretempfail}) {
			$ctx->setreply('451', '4.7.1', "Temporary failure in DNS lookup for $domain");
			return SMFIS_TEMPFAIL;
		}
	}

	SMFIS_CONTINUE;
}

sub envrcpt_callback {
	# XXX need something here
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
