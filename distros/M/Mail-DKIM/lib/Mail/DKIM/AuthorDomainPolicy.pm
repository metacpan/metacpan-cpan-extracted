#!/usr/bin/perl

# Copyright 2005-2009 Messiah College.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;

package Mail::DKIM::AuthorDomainPolicy;
use base "Mail::DKIM::Policy";
# base class is used for parse(), as_string()

use Mail::DKIM::DNS;

=head1 NAME

Mail::DKIM::AuthorDomainPolicy - represents an Author Domain Signing Practices (ADSP) record

=head1 DESCRIPTION

The Author Domain Signing Policies (ADSP) record can be published by any
domain to help a receiver know what to do when it encounters an unsigned
message claiming to originate from that domain.

The record is published as a DNS TXT record at _adsp._domainkey.DOMAIN
where DOMAIN is the domain of the message's "From" address.

More details about this record can be found by reading the specification
itself at L<http://tools.ietf.org/html/rfc5617>.

=head1 CONSTRUCTORS

=head2 fetch()

Lookup an ADSP record in DNS.

  my $policy = Mail::DKIM::AuthorDomainPolicy->fetch(
            Protocol => "dns",
            Author => 'jsmith@example.org',
          );

If the ADSP record is found and appears to be valid, an object
containing that record's information will be constructed and returned.
If the ADSP record is blank or simply does not exist, an object
representing the default policy will be returned instead.
(See also L</"is_implied_default_policy()">.)
If a DNS error occurs (e.g. SERVFAIL or time-out), this method
will "die".

=cut

sub fetch
{
	my $class = shift;
	my %prms = @_;

	my $self = eval { $class->SUPER::fetch(%prms) };
	my $E = $@;

	if ($self && !$self->is_implied_default_policy)
	{
		return $self;
	}

	# didn't find a policy; check the domain itself
	{
		#FIXME- not good to have this code duplicated between
		#here and get_lookup_name()
		#
		if ($prms{Author} && !$prms{Domain})
		{
			$prms{Domain} = ($prms{Author} =~ /\@([^@]*)$/ and $1);
		}

		unless ($prms{Domain})
		{
			die "no domain to fetch policy for\n";
		}

		my @resp = Mail::DKIM::DNS::query($prms{Domain}, "MX");
		if (!@resp && $@ eq "NXDOMAIN")
		{
			return $class->nxdomain_policy;
		}
	}

	die $E if $E;
	return $self;
}
	
# get_lookup_name() - determine name of record to fetch
#
sub get_lookup_name
{
	my $self = shift;
	my ($prms) = @_;

	# in ADSP, the record to fetch is determined based on the From header

	if ($prms->{Author} && !$prms->{Domain})
	{
		$prms->{Domain} = ($prms->{Author} =~ /\@([^@]*)$/ and $1);
	}

	unless ($prms->{Domain})
	{
		die "no domain to fetch policy for\n";
	}

	# IETF seems poised to create policy records this way
	return "_adsp._domainkey." . $prms->{Domain};
}

=head2 new()

Construct a default policy object.

  my $policy = Mail::DKIM::AuthorDomainPolicy->new;

=cut

sub new
{
	my $class = shift;
	return $class->parse(String => "");
}

=head2 parse()

Construct an ADSP record from a string.

  my $policy = Mail::DKIM::AuthorDomainPolicy->parse(
          String => "dkim=all",
          Domain => "aaa.example",
      );

=cut

#undocumented private class method
our $DEFAULT_POLICY;
sub default
{
	my $class = shift;
	$DEFAULT_POLICY ||= $class->new;
	return $DEFAULT_POLICY;
}

#undocumented private class method
our $NXDOMAIN_POLICY;
sub nxdomain_policy
{
	my $class = shift;
	if (!$NXDOMAIN_POLICY)
	{
		$NXDOMAIN_POLICY = $class->new;
		$NXDOMAIN_POLICY->policy("NXDOMAIN");
	}
	return $NXDOMAIN_POLICY;
}
	
=head1 METHODS

=head2 apply()

Apply the policy to the results of a DKIM verifier.

  my $result = $policy->apply($dkim_verifier);

The caller must provide an instance of L<Mail::DKIM::Verifier>, one which
has already been fed the message being verified.

Possible results are:

=over

=item accept

The message is approved by the sender signing policy.

=item reject

The message is rejected by the sender signing policy.
It can be considered very suspicious.

=item neutral

The message is neither approved nor rejected by the sender signing
policy. It can be considered somewhat suspicious.

=back

Note: in the future, these values may become:
 none - no ADSP record is published
 pass - a passing signature is present
 fail - ADSP record is "all" and no passing signature is found
 discard - ADSP record is "discardable" and no passing signature is found
 nxdomain - the DNS domain does not exist
 temperror - transient error occurred
 permerror - non-transient error occurred

=cut

sub apply
{
	my $self = shift;
	my ($dkim) = @_;

	# first_party indicates whether there is a DKIM signature with
	# a d= tag matching the address in the From: header
	my $first_party;

	my @passing_signatures = grep {
		$_->result && $_->result eq "pass"
		} $dkim->signatures;

	foreach my $signature (@passing_signatures)
	{
		my $author_domain = $dkim->message_originator->host;
		if (lc $author_domain eq lc $signature->domain)
		{
			# found a first party signature
			$first_party = 1;
			last;
		}
	}

	return "accept" if $first_party;
	return "reject" if ($self->signall_strict);

	return "neutral";
}

=head2 is_implied_default_policy()

Tells whether this policy implied.

  my $is_implied = $policy->is_implied_default_policy;

If you fetch the policy for a particular domain, but that domain
does not have a policy published, then the "default policy" is
in effect. Use this method to detect when that happens.

=cut

sub is_implied_default_policy
{
	my $self = shift;
	my $default_policy = ref($self)->default;
	return ($self == $default_policy);
}

=head2 location()

Tells where the policy was fetched from.

If the policy is domain-wide, this will be domain where the policy was
published.

If the policy is user-specific, TBD.

If nothing is published for the domain, and the default policy
was returned instead, the location will be C<undef>.

=cut

sub location
{
	my $self = shift;
	return $self->{Domain};
}

sub name
{
	return "ADSP";
}

=head2 policy()

Get or set the outbound signing policy (dkim=) tag.

  my $sp = $policy->policy;

Outbound signing policy for the entity. Possible values are:

=over

=item C<unknown>

The default. The entity may sign some or all email.

=item C<all>

All mail from the domain is expected to be signed, using a valid Author
signature, but the author does not suggest discarding mail without a
valid signature.

=item C<discardable>

All mail from the domain is expected to be signed, using a valid Author
signature, and the author is so confident that non-signed mail claiming
to be from this domain can be automatically discarded by the recipient's
mail server.

=item C<"NXDOMAIN">

The domain is out of scope, i.e., the domain does not exist in the
DNS.

=back

=cut

sub policy
{
	my $self = shift;

	(@_) and
		$self->{tags}->{dkim} = shift;

	if (defined $self->{tags}->{dkim})
	{
		return $self->{tags}->{dkim};
	}
	else
	{
		return "unknown";
	}
}

=head2 signall()

True if policy is "all".

=cut

sub signall
{
	my $self = shift;

	return $self->policy &&
		($self->policy =~ /all/i);
}

=head2 signall_discardable()

True if policy is "strict".

=cut

sub signall_strict
{
	my $self = shift;

	return $self->policy &&
		($self->policy =~ /discardable/i);
}

1;

=head1 BUGS

=over

=item *

Section 4.3 of the specification says to perform a query on the
domain itself just to see if it exists. This class is not
currently doing that, i.e. it might report NXDOMAIN because
_adsp._domainkey.example.org is nonexistent, but it should
not be treated the same as example.org being nonexistent.

=back

=head1 AUTHOR

Jason Long, E<lt>jlong@messiah.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2009 by Messiah College

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
