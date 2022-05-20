package Mail::DKIM::DkimPolicy;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: represents a DKIM Sender Signing Practices record

# Copyright 2005-2007 Messiah College.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use base 'Mail::DKIM::Policy';

# base class is used for parse(), as_string()

use Mail::DKIM::DNS;


# get_lookup_name() - determine name of record to fetch
#
sub get_lookup_name {
    my $self = shift;
    my ($prms) = @_;

    # in DKIM, the record to fetch is determined based on the From header

    if ( $prms->{Author} && !$prms->{Domain} ) {
        $prms->{Domain} = ( $prms->{Author} =~ /\@([^@]*)$/ and $1 );
    }

    unless ( $prms->{Domain} ) {
        die "no domain to fetch policy for\n";
    }

    # IETF seems poised to create policy records this way
    return '_policy._domainkey.' . $prms->{Domain};
}


sub new {
    my $class = shift;
    return $class->parse( String => 'o=~' );
}

#undocumented private class method
our $DEFAULT_POLICY;

sub default {
    my $class = shift;
    $DEFAULT_POLICY ||= $class->new;
    return $DEFAULT_POLICY;
}


sub apply {
    my $self = shift;
    my ($dkim) = @_;

    # first_party indicates whether there is a DKIM signature with
    # an i= tag matching the address in the From: header
    my $first_party;

    #FIXME - if there are multiple verified signatures, each one
    # should be checked

    foreach my $signature ( $dkim->signatures ) {

        # only valid/verified signatures are considered
        next unless ( $signature->result && $signature->result eq 'pass' );

        my $oa = $dkim->message_originator->address;
        if ( $signature->identity_matches($oa) ) {

            # found a first party signature
            $first_party = 1;
            last;
        }
    }

    #TODO - consider testing flag

    return 'accept' if $first_party;
    return 'reject' if ( $self->signall_strict && !$self->testing );

    if ( $self->signall ) {

        # is there ANY valid signature?
        my $verify_result = $dkim->result;
        return 'accept' if $verify_result eq 'pass';
    }

    return 'reject' if ( $self->signall && !$self->testing );
    return 'neutral';
}


sub flags {
    my $self = shift;

    (@_)
      and $self->{tags}->{t} = shift;

    $self->{tags}->{t};
}


sub is_implied_default_policy {
    my $self           = shift;
    my $default_policy = ref($self)->default;
    return ( $self == $default_policy );
}


sub location {
    my $self = shift;
    return $self->{Domain};
}

sub name {
    return 'author';
}


sub policy {
    my $self = shift;

    (@_)
      and $self->{tags}->{dkim} = shift;

    if ( defined $self->{tags}->{dkim} ) {
        return $self->{tags}->{dkim};
    }
    elsif ( defined $self->{tags}->{o} ) {
        return $self->{tags}->{o};
    }
    else {
        return 'unknown';
    }
}


sub signall {
    my $self = shift;

    return $self->policy
      && ( $self->policy =~ /all/i
        || $self->policy eq '-' );    # an older symbol for "all"
}


sub signall_strict {
    my $self = shift;

    return $self->policy
      && ( $self->policy =~ /strict/i
        || $self->policy eq '!' );    # "!" is an older symbol for "strict"
}

sub signsome {
    my $self = shift;

    $self->policy
      or return 1;

    $self->policy eq '~'
      and return 1;

    return;
}


sub testing {
    my $self = shift;
    my $t    = $self->flags;
    ( $t && $t =~ /y/i )
      and return 1;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::DkimPolicy - represents a DKIM Sender Signing Practices record

=head1 VERSION

version 1.20220520

=head1 DESCRIPTION

The Sender Signing Practices (SSP) record can be published by any
domain to help a receiver know what to do when it encounters an unsigned
message claiming to originate from that domain.

The record is published as a DNS TXT record at _policy._domainkey.DOMAIN
where DOMAIN is the domain of the message's "From" address.

This record format has been superceded by ADSP. See
L<Mail::DKIM::AuthorDomainPolicy> for information about ADSP.
It is implemented here because at one time it appeared this is what
would be standardized by the IETF. It will be removed from Mail::DKIM
at some point in the future.
The last version of the SSP specification can be found at
L<http://tools.ietf.org/html/draft-ietf-dkim-ssp-02>.

=head1 CONSTRUCTORS

=head2 fetch()

Lookup a DKIM signing practices record.

  my $policy = Mail::DKIM::DkimPolicy->fetch(
            Protocol => 'dns',
            Author => 'jsmith@example.org',
          );

=head2 new()

Construct a default policy object.

  my $policy = Mail::DKIM::DkimPolicy->new;

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

=head2 flags()

Get or set the flags (t=) tag.

A colon-separated list of flags. Flag values are:

=over

=item y

The entity is testing signing practices, and the Verifier
SHOULD NOT consider a message suspicious based on the record.

=item s

The signing practices apply only to the named domain, and
not to subdomains.

=back

=head2 is_implied_default_policy()

Is this policy implied?

  my $is_implied = $policy->is_implied_default_policy;

If you fetch the policy for a particular domain, but that domain
does not have a policy published, then the "default policy" is
in effect. Use this method to detect when that happens.

=head2 location()

Where the policy was fetched from.

If the policy is domain-wide, this will be domain where the policy was
published.

If the policy is user-specific, TBD.

If nothing is published for the domain, and the default policy
was returned instead, the location will be C<undef>.

=head2 policy()

Get or set the outbound signing policy (dkim=) tag.

  my $sp = $policy->policy;

Outbound signing policy for the entity. Possible values are:

=over

=item C<unknown>

The default. The entity may sign some or all email.

=item C<all>

All mail from the entity is signed.
(The DKIM signature can use any domain, not necessarily matching
the From: address.)

=item C<strict>

All mail from the entity is signed with Originator signatures.
(The DKIM signature uses a domain matching the From: address.)

=back

=head2 signall()

True if policy is "all".

=head2 signall_strict()

True if policy is "strict".

=head2 testing()

Checks the testing flag.

  my $testing = $policy->testing;

If nonzero, the testing flag is set on the signing policy, and the
verify should not consider a message suspicious based on this policy.

=head1 BUGS

=over

=item *

If a sender signing policy is not found for a given domain, the
fetch() method should search the parent domains, according to
section 4 of the dkim-ssp Internet Draft.

=back

=head1 AUTHORS

=over 4

=item *

Jason Long <jason@long.name>

=item *

Marc Bradshaw <marc@marcbradshaw.net>

=item *

Bron Gondwana <brong@fastmailteam.com> (ARC)

=back

=head1 THANKS

Work on ensuring that this module passes the ARC test suite was
generously sponsored by Valimail (https://www.valimail.com/)

=head1 COPYRIGHT AND LICENSE

=over 4

=item *

Copyright (C) 2013 by Messiah College

=item *

Copyright (C) 2010 by Jason Long

=item *

Copyright (C) 2017 by Standcore LLC

=item *

Copyright (C) 2020 by FastMail Pty Ltd

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
