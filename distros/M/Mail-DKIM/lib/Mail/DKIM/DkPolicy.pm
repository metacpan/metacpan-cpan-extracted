#!/usr/bin/perl

# Copyright 2005-2009 Messiah College.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;

package Mail::DKIM::DkPolicy;
use base "Mail::DKIM::Policy";
use Mail::DKIM::DNS;

=head1 NAME

Mail::DKIM::DkPolicy - represents a DomainKeys Sender Signing Policy record

=head1 DESCRIPTION

DomainKeys sender signing policies are described in
RFC4870(historical). It is a record published in the message
sender's (i.e. the person who transmitted the message)
DNS that describes how they sign messages.

=head1 CONSTRUCTORS

=head2 fetch() - fetch a sender signing policy from DNS

  my $policy = Mail::DKIM::DkPolicy->fetch(
                   Protocol => "dns",
                   Sender => 'joe@example.org',
               );

The following named arguments are accepted:

=over

=item Protocol

always specify "dns"

=item Author

the "author" of the message for which policy is being checked.
This is the first email address in the "From" header.
According to RFC 2822, section 3.6.2, the "From" header lists
who is responsible for writing the message.

=item Sender

the "sender" of the message for which policy is being checked.
This is the first email address in the "Sender" header,
or if there is not a "Sender" header, the "From" header.
According to RFC 2822, section 3.6.2, the "Sender" header lists
who is responsible for transmitting the message.

=back

Depending on what type of policy is being checked, both the
Sender and Author fields may need to be specified.

If a DNS error or timeout occurs, an exception is thrown.

Otherwise, a policy object of some sort will be returned.
If no policy is actually published,
then the "default policy" will be returned.
To check when this happens, use

  my $is_default = $policy->is_implied_default_policy;

=cut

# get_lookup_name() - determine name of record to fetch
#
sub get_lookup_name
{
	my $self = shift;
	my ($prms) = @_;

	# in DomainKeys, the record to fetch is determined based on the
	# Sender header, then the From header

	if ($prms->{Author} && !$prms->{Sender})
	{
		$prms->{Sender} = $prms->{Author};
	}
	if ($prms->{Sender} && !$prms->{Domain})
	{
		# pick domain from email address
		$prms->{Domain} = ($prms->{Sender} =~ /\@([^@]*)$/ and $1);
	}

	unless ($prms->{Domain})
	{
		die "no domain to fetch policy for\n";
	}

	# IETF seems poised to create policy records this way
	#my $host = "_policy._domainkey." . $prms{Domain};

	# but Yahoo! policy records are still much more common
	# see historic RFC4870, section 3.6
	return "_domainkey." . $prms->{Domain};
}

=head2 new() - construct a default policy object

  my $policy = Mail::DKIM::DkPolicy->new;

=cut

sub new
{
	my $class = shift;
	return $class->parse(String => "o=~");
}

=head2 parse() - gets a policy object by parsing a string

  my $policy = Mail::DKIM::DkPolicy->parse(
                   String => "o=~; t=y"
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

=head1 METHODS

=head2 apply() - apply the policy to the results of a DKIM verifier

  my $result = $policy->apply($dkim_verifier);

The caller must provide an instance of L<Mail::DKIM::Verifier>, one which
has already been fed the message being verified.

Possible results are:

=over

=item accept

The message is approved by the sender signing policy.

=item reject

The message is rejected by the sender signing policy.

=item neutral

The message is neither approved nor rejected by the sender signing
policy. It can be considered suspicious.

=back

=cut

sub apply
{
	my $self = shift;
	my ($dkim) = @_;

	my $first_party;
	foreach my $signature ($dkim->signatures)
	{
		next if $signature->result ne "pass";

		my $oa = $dkim->message_sender->address;
		if ($signature->identity_matches($oa))
		{
			# found a first party signature
			$first_party = 1;
			last;
		}
	}

	return "accept" if $first_party;
	return "reject" if ($self->signall && !$self->testing);
	return "neutral";
}

=head2 flags() - get or set the flags (t=) tag

A vertical-bar separated list of flags.

=cut

sub flags
{
	my $self = shift;

	(@_) and 
		$self->{tags}->{t} = shift;

	$self->{tags}->{t};
}

=head2 is_implied_default_policy() - is this policy implied?

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

=head2 location() - where the policy was fetched from

DomainKeys policies only have per-domain policies, so this will
be the domain where the policy was published.

If nothing is published for the domain, and the default policy
was returned instead, the location will be C<undef>.

=cut

sub name
{
	return "sender";
}

=head2 note() - get or set the human readable notes (n=) tag

Human readable notes regarding the record. Undef if no notes specified.

=cut

sub note
{
	my $self = shift;

	(@_) and 
		$self->{tags}->{n} = shift;

	$self->{tags}->{n};
}

=head2 policy() - get or set the outbound signing policy (o=) tag

  my $sp = $policy->policy;

Outbound signing policy for the entity. Possible values are:

=over

=item C<~>

The default. The domain may sign some (but not all) email.

=item C<->

The domain signs all email.

=back

=cut

sub policy
{
	my $self = shift;

	(@_) and
		$self->{tags}->{o} = shift;

	if (defined $self->{tags}->{o})
	{
		return $self->{tags}->{o};
	}
	else
	{
		return "~"; # the default
	}
}

=head2 signall() - true if policy is "-"

=cut

sub signall
{
	my $self = shift;
	return ($self->policy && $self->policy eq "-");
}

sub signsome
{
	my $self = shift;

	$self->policy or
		return 1;

	$self->policy eq "~" and
		return 1;

	return;
}

=head2 testing() - checks the testing flag

  my $testing = $policy->testing;

If nonzero, the testing flag is set on the signing policy, and the
verify should not consider a message suspicious based on this policy.

=cut

sub testing
{
	my $self = shift;
	my $t = $self->flags;
	($t && $t =~ /y/i)
		and return 1;
	return;
}

1;

=head1 AUTHOR

Jason Long, E<lt>jlong@messiah.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2009 by Messiah College

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
