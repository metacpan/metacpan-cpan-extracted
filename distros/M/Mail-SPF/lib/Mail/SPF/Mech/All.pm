#
# Mail::SPF::Mech::All
# SPF record "all" mechanism class.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: All.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::Mech::All;

=head1 NAME

Mail::SPF::Mech::All - SPF record C<all> mechanism class

=cut

use warnings;
use strict;

use base 'Mail::SPF::Mech';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant name           => 'all';
use constant name_pattern   => qr/${\name}/i;

use constant explanation_templates_by_result_code => {
    %{__PACKAGE__->SUPER::explanation_templates_by_result_code},
    pass        => "Sender is authorized by default to use '%{s}' in '%{_scope}' identity",
    fail        => "Sender is not authorized by default to use '%{s}' in '%{_scope}' identity",
    softfail    => "Sender is not authorized by default to use '%{s}' in '%{_scope}' identity, however domain is not currently prepared for false failures",
};

=head1 DESCRIPTION

An object of class B<Mail::SPF::Mech::All> represents an SPF record mechanism
of type C<all>.

=head2 Constructors

The following constructors are provided:

=over

=item B<new>: returns I<Mail::SPF::Mech::All>

Creates a new SPF record C<all> mechanism object.

%options is a list of key/value pairs representing any of the following options:

=over

=item B<qualifier>

See L<Mail::SPF::Mech/new>.

=back

=item B<new_from_string($text, %options)>: returns I<Mail::SPF::Mech::All>;
throws I<Mail::SPF::ENothingToParse>, I<Mail::SPF::EInvalidMech>

Creates a new SPF record C<all> mechanism object by parsing the string and
any options given.

=back

=head2 Class methods

The following class methods are provided:

=over

=item B<default_qualifier>

=item B<qualifier_pattern>

See L<Mail::SPF::Mech/Class methods>.

=item B<name>: returns I<string>

Returns B<'all'>.

=item B<name_pattern>: returns I<Regexp>

Returns a regular expression that matches a mechanism name of B<'all'>.

=back

=head2 Instance methods

The following instance methods are provided:

=over

=cut

sub parse_params {
    my ($self) = @_;
    # No parameters.
    return;
}

=item B<text>

=item B<qualifier>

=item B<name>

=item B<stringify>

See L<Mail::SPF::Mech/Instance methods>.

=item B<match($server, $request)>: returns I<boolean>

Returns B<true> because the C<all> mechanism always matches.  See RFC 4408,
5.1, for details.

=cut

sub match {
    my ($self, $server, $request) = @_;
    return TRUE;
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
