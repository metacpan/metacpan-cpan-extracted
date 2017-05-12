#
# Mail::SPF::Mod::Exp
# SPF record "exp" modifier class.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: Exp.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::Mod::Exp;

=head1 NAME

Mail::SPF::Mod::Exp - SPF record C<exp> modifier class

=cut

use warnings;
use strict;

use Mail::SPF::Mod;
use base 'Mail::SPF::GlobalMod';

use Error ':try';

use Mail::SPF::MacroString;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant name           => 'exp';
use constant name_pattern   => qr/${\name}/i;

use constant precedence     => 0.2;

=head1 DESCRIPTION

An object of class B<Mail::SPF::Mod::Exp> represents an SPF record modifier of
type C<exp>.

=head2 Constructors

The following constructors are provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::Mod::Exp>

Creates a new SPF record C<exp> modifier object.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<domain_spec>

See L<Mail::SPF::Mod/new>.

=back

=item B<new_from_string($text, %options)>: returns I<Mail::SPF::Mod::Exp>;
throws I<Mail::SPF::ENothingToParse>, I<Mail::SPF::EInvalidMod>

Creates a new SPF record C<exp> modifier object by parsing the string and
any options given.

=back

=head2 Class methods

The following class methods are provided:

=over

=item B<name>: returns I<string>

Returns B<'exp'>.

=item B<name_pattern>: returns I<Regexp>

Returns a regular expression that matches a modifier name of B<'exp'>.

=item B<precedence>: returns I<real>

Returns a precedence value of B<0.2>.  See L<Mail::SPF::Mod/precedence>.

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

=item B<params>

See L<Mail::SPF::Mod/params>.

=cut

sub params {
    my ($self) = @_;
    return $self->{domain_spec};
}

=item B<domain_spec>: returns I<Mail::SPF::MacroString>

Returns the C<domain-spec> parameter of the modifier.

=cut

# Make read-only accessor:
__PACKAGE__->make_accessor('domain_spec', TRUE);

=item B<process($server, $request, $result)>

If the given SPF result is a C<fail> result, retrieves the authority domain's
explanation string from the modifier's target domain and attaches it to the SPF
result.  If an error occurs during the retrieval of the explanation string,
does nothing, as if the modifier was not present.  See RFC 4408, 6.2, for
details.

=cut

sub process {
    my ($self, $server, $request, $result) = @_;

    try {
        my $exp_domain = $self->{domain_spec}->new(server => $server, request => $request);
        my $txt_packet = $server->dns_lookup($exp_domain, 'TXT');
        my @txt_rrs = grep($_->type eq 'TXT', $txt_packet->answer);
        @txt_rrs > 0
            or $server->throw_result('permerror', $request,
                "No authority explanation string available at domain '$exp_domain'");  # RFC 4408, 6.2/4
        @txt_rrs == 1
            or $server->throw_result('permerror', $request,
                "Redundant authority explanation strings found at domain '$exp_domain'");  # RFC 4408, 6.2/4
        my $explanation = Mail::SPF::MacroString->new(
            text            => join('', $txt_rrs[0]->char_str_list),
            server          => $server,
            request         => $request,
            is_explanation  => TRUE
        );
        $request->state('authority_explanation', $explanation);
    }
    # Ignore DNS and other errors:
    catch Mail::SPF::EDNSError with {}
    catch Mail::SPF::Result::Error with {};

    return;
}

=back

See L<Mail::SPF::Mod> for other supported instance methods.

=head1 SEE ALSO

L<Mail::SPF>, L<Mail::SPF::Mod>, L<Mail::SPF::Term>, L<Mail::SPF::Record>

L<http://tools.ietf.org/html/rfc4408>

For availability, support, and license information, see the README file
included with Mail::SPF.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>, Shevek <cpan@anarres.org>

=cut

TRUE;
