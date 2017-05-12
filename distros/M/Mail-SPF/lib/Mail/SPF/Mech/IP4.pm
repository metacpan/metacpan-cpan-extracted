#
# Mail::SPF::Mech::IP4
# SPF record "ip4" mechanism class.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: IP4.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::Mech::IP4;

=head1 NAME

Mail::SPF::Mech::IP4 - SPF record C<ip4> mechanism class

=cut

use warnings;
use strict;

use base 'Mail::SPF::SenderIPAddrMech';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant name           => 'ip4';
use constant name_pattern   => qr/${\name}/i;

=head1 DESCRIPTION

An object of class B<Mail::SPF::Mech::IP4> represents an SPF record mechanism
of type C<ip4>.

=head2 Constructors

The following constructors are provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::Mech::IP4>

Creates a new SPF record C<ip4> mechanism object.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<qualifier>

=item B<ip_network>

See L<Mail::SPF::Mech/new>.

=back

=item B<new_from_string($text, %options)>: returns I<Mail::SPF::Mech::IP4>;
throws I<Mail::SPF::ENothingToParse>, I<Mail::SPF::EInvalidMech>

Creates a new SPF record C<ip4> mechanism object by parsing the string and
any options given.

=back

=head2 Class methods

The following class methods are provided:

=over

=item B<default_qualifier>

=item B<default_ipv4_prefix_length>

=item B<qualifier_pattern>

See L<Mail::SPF::Mech/Class methods>.

=item B<name>: returns I<string>

Returns B<'ip4'>.

=item B<name_pattern>: returns I<Regexp>

Returns a regular expression that matches a mechanism name of B<'ip4'>.

=back

See L<Mail::SPF::Mech> for other supported class methods.

=head2 Instance methods

The following instance methods are provided:

=over

=cut

sub parse_params {
    my ($self) = @_;
    $self->parse_ipv4_network(TRUE);
    return;
}

=item B<text>

=item B<qualifier>

=item B<params>

=cut

sub params {
    my ($self) = @_;
    my $params = ':' . $self->{ip_network}->addr;
    $params .= '/' . $self->{ip_network}->masklen
        if $self->{ip_network}->masklen != $self->default_ipv4_prefix_length;
    return $params;
}

=item B<stringify>

See L<Mail::SPF::Mech/Instance methods>.

=item B<ip_network>: returns I<NetAddr::IP>

Returns the IP address network parameter of the mechanism.

=cut

# Make read-only accessors:
__PACKAGE__->make_accessor($_, TRUE)
    foreach qw(ip_network ip_address ipv4_prefix_length);

=item B<match($server, $request)>: returns I<boolean>

Returns B<true> if the mechanism's C<ip_network> equals or contains the given
request's IP address, or B<false> otherwise.  See RFC 4408, 5.6, for details.

=cut

sub match {
    my ($self, $server, $request) = @_;
    my $ip_network_v6 =
        $self->ip_network->version == 4 ?
            Mail::SPF::Util->ipv4_address_to_ipv6($self->ip_network)
        :   $self->ip_network;
    return $ip_network_v6->contains($request->ip_address_v6);
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
