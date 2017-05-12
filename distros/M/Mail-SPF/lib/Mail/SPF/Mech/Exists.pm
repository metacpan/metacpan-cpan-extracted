#
# Mail::SPF::Mech::Exists
# SPF record "exists" mechanism class.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: Exists.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::Mech::Exists;

=head1 NAME

Mail::SPF::Mech::Exists - SPF record C<exists> mechanism class

=cut

use warnings;
use strict;

use base 'Mail::SPF::Mech';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant name           => 'exists';
use constant name_pattern   => qr/${\name}/i;

=head1 DESCRIPTION

An object of class B<Mail::SPF::Mech::Exists> represents an SPF record
mechanism of type C<exists>.

=head2 Constructors

The following constructors are provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::Mech::Exists>

Creates a new SPF record C<exists> mechanism object.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<qualifier>

=item B<domain_spec>

See L<Mail::SPF::Mech/new>.

=back

=item B<new_from_string($text, %options)>: returns I<Mail::SPF::Mech::Exists>;
throws I<Mail::SPF::ENothingToParse>, I<Mail::SPF::EInvalidMech>

Creates a new SPF record C<exists> mechanism object by parsing the string and
any options given.

=back

=head2 Class methods

The following class methods are provided:

=over

=item B<default_qualifier>

=item B<qualifier_pattern>

See L<Mail::SPF::Mech/Class methods>.

=item B<name>: returns I<string>

Returns B<'exists'>.

=item B<name_pattern>: returns I<Regexp>

Returns a regular expression that matches a mechanism name of B<'exists'>.

=back

=head2 Instance methods

The following instance methods are provided:

=over

=cut

sub parse_params {
    my ($self) = @_;
    $self->parse_domain_spec(TRUE);
    return;
}

=item B<text>

=item B<qualifier>

=item B<params>

=cut

sub params {
    my ($self) = @_;
    return defined($self->{domain_spec}) ? ':' . $self->{domain_spec} : undef;
}

=item B<stringify>

See L<Mail::SPF::Mech/Instance methods>.

=item B<domain_spec>: returns I<Mail::SPF::MacroString>

Returns the C<domain-spec> parameter of the mechanism.

=cut

# Make read-only accessor:
__PACKAGE__->make_accessor('domain_spec', TRUE);

=item B<match($server, $request)>: returns I<boolean>

Checks whether a DNS C<A> record exists for the mechanism's target domain name,
and returns B<true> if one does, or B<false> otherwise.  See RFC 4408, 5.7, for
details.

=cut

sub match {
    my ($self, $server, $request) = @_;

    $server->count_dns_interactive_term($request);

    my $domain = $self->domain($server, $request);
    my $packet = $server->dns_lookup($domain, 'A');
    my @rrs    = $packet->answer
        or $server->count_void_dns_lookup($request);

    foreach my $rr (@rrs) {
        return TRUE
            if $rr->type eq 'A';
    }
    return FALSE;
}

=back

=head1 SEE ALSO

L<Mail::SPF>, L<Mail::SPF::Record>, L<Mail::SPF::Term>, L<Mail::SPF::Mech>

L<http://tools.ietf.org/html/rfc4408>

For availability, support, and license information, see the README file
included with Mail::SPF.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>, Shevek <cpan@anarres.org>

=cut

TRUE;
