#
# Mail::SPF::Mech::Include
# SPF record "include" mechanism class.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: Include.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::Mech::Include;

=head1 NAME

Mail::SPF::Mech::Include - SPF record C<include> mechanism class

=cut

use warnings;
use strict;

use base 'Mail::SPF::Mech';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant name           => 'include';
use constant name_pattern   => qr/${\name}/i;

=head1 DESCRIPTION

An object of class B<Mail::SPF::Mech::Include> represents an SPF record
mechanism of type C<include>.

=head2 Constructors

The following constructors are provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::Mech::Include>

Creates a new SPF record C<include> mechanism object.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<qualifier>

=item B<domain_spec>

See L<Mail::SPF::Mech/new>.

=back

=item B<new_from_string($text, %options)>: returns I<Mail::SPF::Mech::Include>;
throws I<Mail::SPF::ENothingToParse>, I<Mail::SPF::EInvalidMech>

Creates a new SPF record C<include> mechanism object by parsing the string and
any options given.

=back

=head2 Class methods

The following class methods are provided:

=over

=item B<default_qualifier>

=item B<qualifier_pattern>

See L<Mail::SPF::Mech/Class methods>.

=item B<name>: returns I<string>

Returns B<'include'>.

=item B<name_pattern>: returns I<Regexp>

Returns a regular expression that matches a mechanism name of B<'include'>.

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

Performs a recursive SPF check using the given SPF server and request objects
and substituting the mechanism's target domain name for the request's authority
domain.  The result of the recursive SPF check is translated as follows:

     Recursive result | Effect
    ------------------+-----------------
     pass             | return true
     fail             | return false
     softfail         | return false
     neutral          | return false
     none             | throw PermError
     permerror        | throw PermError
     temperror        | throw TempError

See RFC 4408, 5.2, for the exact algorithm used.

=cut

sub match {
    my ($self, $server, $request) = @_;

    $server->count_dns_interactive_term($request);

    # Create sub-request with mutated authority domain:
    my $authority_domain = $self->domain($server, $request);
    my $sub_request = $request->new_sub_request(authority_domain => $authority_domain);

    # Process sub-request:
    my $result = $server->process($sub_request);

    # Translate result of sub-request (RFC 4408, 5/9):

    return TRUE
        if $result->isa('Mail::SPF::Result::Pass');

    return FALSE
        if $result->isa('Mail::SPF::Result::Fail')
        or $result->isa('Mail::SPF::Result::SoftFail')
        or $result->isa('Mail::SPF::Result::Neutral');

    $server->throw_result('permerror', $request,
        "Included domain '$authority_domain' has no applicable sender policy")
        if $result->isa('Mail::SPF::Result::None');

    # Propagate any other results (including {Perm,Temp}Error) as-is:
    $result->throw();
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
