package Mail::DKIM::Policy;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: abstract base class for originator "signing" policies

# Copyright 2005-2007 Messiah College.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Mail::DKIM::DNS;


sub fetch {
    my $class  = shift;
    my $waiter = $class->fetch_async(@_);
    return $waiter->();
}

sub fetch_async {
    my $class = shift;
    my %prms  = @_;

    ( $prms{'Protocol'} eq 'dns' )
      or die "invalid protocol '$prms{Protocol}'\n";

    my $host       = $class->get_lookup_name( \%prms );
    my %callbacks  = %{ $prms{Callbacks} || {} };
    my $on_success = $callbacks{Success} || sub { $_[0] };
    $callbacks{Success} = sub {
        my @resp = @_;
        unless (@resp) {

            # no requested resource records or NXDOMAIN,
            # use default policy
            return $on_success->( $class->default );
        }

        my $strn;
        foreach my $rr (@resp) {
            next unless $rr->type eq 'TXT';

            # join with no intervening spaces, RFC 5617
            if ( Net::DNS->VERSION >= 0.69 ) {

                # must call txtdata() in a list context
                $strn = join '', $rr->txtdata;
            }
            else {
                # char_str_list method is 'historical'
                $strn = join '', $rr->char_str_list;
            }
        }

        unless ($strn) {

            # empty record found in DNS, use default policy
            return $on_success->( $class->default );
        }

        my $self = $class->parse(
            String => $strn,
            Domain => $prms{Domain},
        );
        return $on_success->($self);
    };

    #
    # perform DNS query for domain policy...
    #
    my $waiter =
      Mail::DKIM::DNS::query_async( $host, 'TXT', Callbacks => \%callbacks, );
    return $waiter;
}

sub parse {
    my $class = shift;
    my %prms  = @_;

    my $text = $prms{'String'};
    my %tags;
    foreach my $tag ( split /;/, $text ) {

        # strip whitespace
        $tag =~ s/^\s+|\s+$//g;

        my ( $tagname, $value ) = split /=/, $tag, 2;
        unless ( defined $value ) {
            die "policy syntax error\n";
        }

        $tagname =~ s/\s+$//;
        $value =~ s/^\s+//;
        $tags{$tagname} = $value;
    }

    $prms{tags} = \%tags;
    return bless \%prms, $class;
}


sub apply {
    my $self = shift;
    my ($dkim) = @_;

    my $first_party;
    foreach my $signature ( $dkim->signatures ) {
        next if $signature->result ne 'pass';

        my $oa = $dkim->message_sender->address;
        if ( $signature->identity_matches($oa) ) {

            # found a first party signature
            $first_party = 1;
            last;
        }
    }

    return 'accept' if $first_party;
    return 'reject' if ( $self->signall && !$self->testing );
    return 'neutral';
}


sub as_string {
    my $self = shift;

    return join(
        '; ', map { "$_=" . $self->{tags}->{$_} }
          keys %{ $self->{tags} }
    );
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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::Policy - abstract base class for originator "signing" policies

=head1 VERSION

version 1.20220520

=head1 SYNOPSIS

  # get all policies that apply to a verified message
  foreach my $policy ($dkim->policies)
  {

      # the name of this policy
      my $name = $policy->name;

      # the location in DNS where this policy was found
      my $location = $policy->location;

      # apply this policy to the message being verified
      my $result = $policy->apply($dkim);

  }

=head1 DESCRIPTION

Between the various versions of the DomainKeys/DKIM standards, several
different forms of sender "signing" policies have been defined.
In order for the L<Mail::DKIM> library to support these different
policies, it uses several different subclasses. All subclasses support
this general interface, so that a program using L<Mail::DKIM> can
support any and all policies found for a message.

=head1 METHODS

These methods are supported by all classes implementing the
L<Mail::DKIM::Policy> interface.

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

=item neutral

The message is neither approved nor rejected by the sender signing
policy. It can be considered suspicious.

=back

=head2 as_string()

The policy as a string.

Note that the string returned by this method will not necessarily have
the tags ordered the same as the text record found in DNS.

=head2 is_implied_default_policy()

Is this policy implied?

  my $is_implied = $policy->is_implied_default_policy;

If you fetch the policy for a particular domain, but that domain
does not have a policy published, then the "default policy" is
in effect. Use this method to detect when that happens.

=head2 location()

Where the policy was fetched from.

This is generally a domain name, the domain name where the policy
was published.

If nothing is published for the domain, and the default policy
was returned instead, the location will be C<undef>.

=head2 name()

Identify what type of policy this is.

This currently returns strings like "sender", "author", and "ADSP".
It is subject to change in the next version of Mail::DKIM.

=head1 SEE ALSO

L<Mail::DKIM::DkPolicy> - for RFC4870(historical) DomainKeys
sender signing policies

L<Mail::DKIM::DkimPolicy> - for early draft DKIM sender signing policies

L<Mail::DKIM::AuthorDomainPolicy> - for Author Domain Signing Practices
(ADSP)

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
