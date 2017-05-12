#
# Mail::SPF::Request
# SPF request class.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: Request.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::Request;

=head1 NAME

Mail::SPF::Request - SPF request class

=cut

use warnings;
use strict;

use base 'Mail::SPF::Base';

use NetAddr::IP;

use Mail::SPF::Util;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant versions_for_scope => {
    helo    => [1   ],
    mfrom   => [1, 2],
    pra     => [   2]
};

use constant scopes_by_version => {
    1       => ['helo', 'mfrom'       ],
    2       => [        'mfrom', 'pra']
};

use constant default_localpart => 'postmaster';

# Interface:
##############################################################################

=head1 SYNOPSIS

    use Mail::SPF;

    my $request = Mail::SPF::Request->new(
        versions    => [1, 2],              # optional
        scope       => 'mfrom',             # or 'helo', 'pra'
        identity    => 'fred@example.com',
        ip_address  => '192.168.0.1',
        helo_identity                       # optional,
                    => 'mta.example.com'    #   for %{h} macro expansion
    );

    my @versions    = $request->versions;
    my $scope       = $request->scope;
    my $authority_domain
                    = $request->authority_domain;
    my $identity    = $request->identity;   # 'localpart@domain' or 'domain'
    my $domain      = $request->domain;
    my $localpart   = $request->localpart;
    my $ip_address  = $request->ip_address;     # IPv4 or IPv6 address
    my $ip_address_v6                           # native IPv6 address or
                    = $request->ip_address_v6;  #   IPv4-mapped IPv6 address
    my $helo_identity                           # additional HELO identity
                    = $request->helo_identity;  #   for non-HELO scopes

    my $record      = $request->record;
        # the record selected during processing of the request, may be undef

    $request->state(field => 'value');
    my $value = $request->state('field');

=cut

# Implementation:
##############################################################################

=head1 DESCRIPTION

An object of class B<Mail::SPF::Request> represents an SPF request.

=head2 Constructors

The following constructors are provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::Request>

Creates a new SPF request object.  The request is considered the
I<root-request> for any subsequent sub-requests (see the L</new_sub_request>
constructor).

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<versions>

A reference to an I<array> of I<integer>s listing the versions of SPF records
that may be used for the SPF check.  Only those record versions that cover the
desired scope will actually be used.  At least one applicable version must be
specified.  For a single record version, a simple scalar may be specified
instead of an array-ref.  Defaults to all versions that cover the desired scope
(see below); defaults to B<[1, 2]> for the default scope of B<'mfrom'>.

The following versions are supported:

=over

=item B<1>

Use C<v=spf1> records.

=item B<2>

Use C<spf2.0> records.

=back

I<Example>:  A value of B<1> (or B<[1]>) means that only C<v=spf1> records
should be used for the SPF check.  If at the same time a scope of B<'pra'> is
specified, a I<Mail::SPF::EInvalidScope> exception will be thrown as C<v=spf1>
records do not cover the PRA scope.

=item B<scope>

A string denoting the authorization scope of the identity that should be
checked.  Defaults to B<'mfrom'>.  The following scope values are supported:

=over

=item B<'helo'>

The given identity is the C<HELO> parameter of an SMTP transaction (RFC 2821)
and should be checked against SPF records that cover the C<helo> scope
(C<v=spf1>).  See the SPFv1 specification (RFC 4408) for the formal definition
of the C<HELO> scope.

=item B<'mfrom'>

The given identity is the C<MAIL FROM> parameter of an SMTP transaction (RFC
2821), and should be checked against SPF records that cover the C<mfrom> scope
(C<v=spf1> and C<spf2.0/mfrom>).  See the SPFv1 specification (RFC 4408) for
the formal definition of the C<MAIL FROM> scope.

I<Note>:  In the case of an empty C<MAIL FROM> SMTP transaction parameter (C<<
MAIL FROM:<> >>), you should perform a check with the C<helo> scope instead.

=item B<'pra'>

The given identity is the "Purported Responsible Address" of an internet
message (RFC 2822) and should be checked against SPF records that cover the
C<pra> scope (C<spf2.0/pra>).  See the PRA specification (RFC 4407) for the
formal definition of the PRA scope.

=back

=item B<authority_domain>

A string denoting the domain name that should be queried for sender policy
records.  Defaults to the domain of the C<identity> option.  There is usually
no need to specify the C<authority_domain> option.

=item B<identity>

I<Required>.  A string denoting the sender identity whose authorization should
be checked.  This is a domain name for the C<helo> scope, and an e-mail address
for the C<mfrom> and C<pra> scopes.

I<Note>:  An empty identity must not be passed.  In the case of an empty C<MAIL
FROM> SMTP transaction parameter, you should perform a check with the C<helo>
scope instead.

=item B<ip_address>

I<Required> for checks with the C<helo>, C<mfrom>, and C<pra> scopes.  Either a
string or a I<NetAddr::IP> object denoting the IP address of the host claiming
the identity that is being checked.  Can be either an IPv4 or an IPv6 address.
An IPv4-mapped IPv6 address (e.g. '::ffff:192.168.0.1') is treated as an IPv4
address.

=item B<helo_identity>

A string denoting the C<HELO> SMTP transaction parameter in the case that the
main identity is of a scope other than C<helo>.  This identity is then used
merely for the expansion of C<%{h}> macros during the policy evaluation of the
main identity.  Defaults to B<undef>, which will be expanded to B<'unknown'>.
If the main identity is of the C<helo> scope, this option is unused.

=back

=cut

sub new {
    my ($self, %options) = @_;

    # Create new object:
    $self = $self->SUPER::new(%options);
    # If the request object already has a state hash, clone its contents:
    $self->{state} = { %{$self->{state}} }
        if ref($self->{state}) eq 'HASH';

    # Scope:
    $self->{scope} ||= 'mfrom';
    my $versions_for_scope = $self->versions_for_scope->{$self->{scope}}
        or throw Mail::SPF::EInvalidScope("Invalid scope '$self->{scope}'");

    # Versions:
    if (not defined($self->{versions})) {
        # No versions specified, use all versions relevant to scope:
        $self->{versions} = $versions_for_scope;
    }
    else {
        if (not ref($self->{versions})) {
            # Single version specified as scalar:
            $self->{versions} = [$self->{versions}];
        }
        elsif (ref($self->{versions}) ne 'ARRAY') {
            # Something other than scalar or array-ref specified:
            throw Mail::SPF::EInvalidOptionValue(
                "'versions' option must be string or array-ref");
        }

        # All requested record versions must be supported:
        my @unsupported_versions = grep(
            (not defined($self->scopes_by_version->{$_})),
            @{$self->{versions}}
        );
        not @unsupported_versions
            or throw Mail::SPF::EInvalidOptionValue(
                'Unsupported record version(s) ' .
                join(', ', map("'$_'", @unsupported_versions)));

        # Use only those record versions that are relevant to the requested scope:
        my %versions_for_scope;
           @versions_for_scope{@$versions_for_scope} = ();
        my @versions = grep(exists($versions_for_scope{$_}), @{$self->{versions}});

        # Require at least one relevant record version that covers the scope:
        @versions
            or throw Mail::SPF::EInvalidScope(
                "Invalid scope '$self->{scope}' for record version(s) " .
                join(', ', @{$self->{versions}}));

        $self->{versions} = \@versions;
    }

    # Identity:
    defined($self->{identity})
        or throw Mail::SPF::EOptionRequired("Missing required 'identity' option");
    length($self->{identity})
        or throw Mail::SPF::EInvalidOptionValue("'identity' option must not be empty");

    # Extract domain and localpart from identity:
    if (
        ($self->{scope} eq 'mfrom' or $self->{scope} eq 'pra') and
        $self->{identity} =~ /^(.*)@(.*?)$/
    ) {
        $self->{domain}    = $2;
        $self->{localpart} = $1;
    }
    else {
        $self->{domain}    = $self->{identity};
    }
    $self->{domain} =~ s/^(.*?)\.?$/\L$1/;
        # Lower-case domain and remove eventual trailing dot.
    $self->{localpart} = $self->default_localpart
        if not defined($self->{localpart}) or not length($self->{localpart});

    # HELO identity:
    if ($self->{scope} eq 'helo') {
        $self->{helo_identity} ||= $self->{identity};
    }

    # IP address:
    throw Mail::SPF::EOptionRequired("Missing required 'ip_address' option")
        if  grep($self->{scope} eq $_, qw(helo mfrom pra))
        and not defined($self->{ip_address});

    # Ensure ip_address is a NetAddr::IP object:
    if (not UNIVERSAL::isa($self->{ip_address}, 'NetAddr::IP')) {
        my $ip_address = NetAddr::IP->new($self->{ip_address})
            or throw Mail::SPF::EInvalidOptionValue("Invalid IP address '$self->{ip_address}'");
        $self->{ip_address} = $ip_address;
    }

    # Convert IPv4 address to IPv4-mapped IPv6 address:
    if (Mail::SPF::Util->ipv6_address_is_ipv4_mapped($self->{ip_address})) {
        $self->{ip_address_v6} = $self->{ip_address};  # Accept as IPv6 address as-is.
        $self->{ip_address} = Mail::SPF::Util->ipv6_address_to_ipv4($self->{ip_address});
    }
    elsif ($self->{ip_address}->version == 4) {
        $self->{ip_address_v6} = Mail::SPF::Util->ipv4_address_to_ipv6($self->{ip_address});
    }
    elsif ($self->{ip_address}->version == 6) {
        $self->{ip_address_v6} = $self->{ip_address};
    }
    else {
        throw Mail::SPF::EInvalidOptionValue(
            "Unexpected IP address version '" . $self->{ip_address}->version . "'");
    }

    return $self;
}

=item B<new_sub_request(%options)>: returns I<Mail::SPF::Request>

Must be invoked on an existing request object.  Creates a new sub-request
object by cloning the invoked request, which is then considered the new
request's I<super-request>.  Any specified options (see the L</new>
constructor) override the parameters of the super-request.  There is usually no
need to specify any options I<besides> the C<authority_domain> option.

=cut

sub new_sub_request {
    my ($super_request, %options) = @_;
    UNIVERSAL::isa($super_request, __PACKAGE__)
        or throw Mail::SPF::EInstanceMethod;
    my $self = $super_request->new(%options);
    $self->{super_request} = $super_request;
    $self->{root_request}  = $super_request->root_request;
    return $self;
}

=back

=head2 Instance methods

The following instance methods are provided:

=over

=item B<root_request>: returns I<Mail::SPF::Request>

Returns the root of the request's chain of super-requests.  Specifically,
returns the request itself if it has no super-requests.

=cut

sub root_request {
    my ($self) = @_;
    # Read-only!
    return $self->{root_request} || $self;
}

=item B<super_request>: returns I<Mail::SPF::Request>

Returns the super-request of the request, or B<undef> if there is none.

=cut

# Make read-only accessor:
__PACKAGE__->make_accessor('super_request', TRUE);

=item B<versions>: returns I<list> of I<string>

Returns a list of the SPF record versions that are used for request.  See the
description of the L</new> constructor's C<versions> option.

=cut

sub versions {
    my ($self) = @_;
    # Read-only!
    return @{$self->{versions}};
}

=item B<scope>: returns I<string>

Returns the scope of the request.  See the description of the L</new>
constructor's C<scope> option.

=item B<authority_domain>: returns I<string>

Returns the authority domain of the request.  See the description of the
L</new> constructor's C<authority_domain> option.

=cut

sub authority_domain {
    my ($self) = @_;
    return $self->{authority_domain} || $self->{domain};
}

=item B<identity>: returns I<string>

Returns the identity of the request.  See the description of the L</new>
constructor's C<identity> option.

=item B<domain>: returns I<string>

Returns the identity domain of the request.  See the description of the
L</new> constructor's C<identity> option.

=item B<localpart>: returns I<string>

Returns the identity localpart of the request.  See the description of the
L</new> constructor's C<identity> option.

=item B<ip_address>: returns I<NetAddr::IP>

Returns the IP address of the request as a I<NetAddr::IP> object.  See the
description of the L</new> constructor's C<ip_address> option.

=item B<ip_address_v6>: returns I<NetAddr::IP>

Like the C<ip_address> method, however, an IPv4 address is returned as an
IPv4-mapped IPv6 address (e.g. '::ffff:192.168.0.1') to facilitate uniform
processing.

=item B<helo_identity>: returns I<string>

Returns the C<HELO> SMTP transaction parameter of the request.  See the
description of the L</new> constructor's C<helo_identity> option.

=cut

# Make read-only accessors:
__PACKAGE__->make_accessor($_, TRUE)
    foreach qw(
        scope identity domain localpart
        ip_address ip_address_v6 helo_identity
    );

=item B<record>: returns I<Mail::SPF::Record>

Returns the SPF record selected during the processing of the request, or
B<undef> if there is none.

=cut

# Make read/write accessor:
__PACKAGE__->make_accessor('record', FALSE);

=item B<state($field)>: returns anything

=item B<state($field, $value)>: returns anything

Provides an interface for storing temporary state information with the request
object.  This is primarily meant to be used internally by I<Mail::SPF::Server>
and other Mail::SPF classes.

If C<$value> is specified, stores it in a state field named C<$field>.  Returns
the current (new) value of the state field named C<$field>.  This method may be
used as an lvalue.

=cut

sub state :lvalue {
    my ($self, $field, @value) = @_;
    defined($field)
        or throw Mail::SPF::EOptionRequired('Field name required');
    $self->{state}->{$field} = $value[0]
        if @value;
    $self->{state}->{$field};
}

=back

=head1 SEE ALSO

L<Mail::SPF>, L<Mail::SPF::Server>

L<http://tools.ietf.org/html/rfc4408>

For availability, support, and license information, see the README file
included with Mail::SPF.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>, Shevek <cpan@anarres.org>

=cut

TRUE;
