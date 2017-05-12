#
# Mail::SPF::v1::Record
# SPFv1 record class.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: Record.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::v1::Record;

=head1 NAME

Mail::SPF::v1::Record - SPFv1 record class

=cut

use warnings;
use strict;

use base 'Mail::SPF::Record';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant mech_classes => {
    all         => 'Mail::SPF::Mech::All',
    ip4         => 'Mail::SPF::Mech::IP4',
    ip6         => 'Mail::SPF::Mech::IP6',
    a           => 'Mail::SPF::Mech::A',
    mx          => 'Mail::SPF::Mech::MX',
    ptr         => 'Mail::SPF::Mech::PTR',
   'exists'     => 'Mail::SPF::Mech::Exists',
    include     => 'Mail::SPF::Mech::Include'
};

use constant mod_classes => {
    redirect    => 'Mail::SPF::Mod::Redirect',
   'exp'        => 'Mail::SPF::Mod::Exp'
};

eval("require $_")
    foreach values(%{mech_classes()}), values(%{mod_classes()});

use constant version_tag            => 'v=spf1';
use constant version_tag_pattern    => qr/ v=spf(1) (?= \x20 | $ ) /ix;

use constant scopes                 => ('helo', 'mfrom');

=head1 SYNOPSIS

See L<Mail::SPF::Record>.

=head1 DESCRIPTION

An object of class B<Mail::SPF::v1::Record> represents an B<SPFv1> (C<v=spf1>)
record.

=head2 Constructors

The following constructors are provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::v1::Record>

Creates a new SPFv1 record object.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<text>

=item B<terms>

=item B<global_mods>

See L<Mail::SPF::Record/new>.

=item B<scopes>

See L<Mail::SPF::Record/new>.  Since SPFv1 records always implicitly cover the
C<helo> and C<mfrom> scopes, this option must either be exactly B<['helo',
'mfrom']> (or B<['mfrom', 'helo']>) or be omitted.

=back

=cut

sub new {
    my ($self, %options) = @_;
    $self = $self->SUPER::new(%options);

    if (defined(my $scopes = $self->{scopes})) {
        @$scopes > 0
            or throw Mail::SPF::EInvalidScope('No scopes for v=spf1 record');
        @$scopes == 2 and
        (
            $scopes->[0] eq 'help'  and $scopes->[1] eq 'mfrom' or
            $scopes->[0] eq 'mfrom' and $scopes->[1] eq 'help'
        )
            or throw Mail::SPF::EInvalidScope(
                "Invalid set of scopes " . join(', ', map("'$_'", @$scopes)) . " for v=spf1 record");
    }

    return $self;
}

=item B<new_from_string($text, %options)>: returns I<Mail::SPF::v1::Record>;
throws I<Mail::SPF::ENothingToParse>, I<Mail::SPF::EInvalidRecordVersion>,
I<Mail::SPF::ESyntaxError>

Creates a new SPFv1 record object by parsing the string and any options given.

=back

=head2 Class methods

The following class methods are provided:

=over

=item B<version_tag_pattern>: returns I<Regexp>

Returns a regular expression that matches a version tag of B<'v=spf1'>.

=item B<default_qualifier>

=item B<results_by_qualifier>

See L<Mail::SPF::Record/Class methods>.

=back

=head2 Instance methods

The following instance methods are provided:

=over

=item B<text>

=item B<scopes>

=item B<terms>

=item B<global_mods>

=item B<global_mod>

=item B<stringify>

=item B<eval>

See L<Mail::SPF::Record/Instance methods>.

=item B<version_tag>: returns I<string>

Returns B<'v=spf1'>.

=back

=head1 SEE ALSO

L<Mail::SPF>, L<Mail::SPF::Record>, L<Mail::SPF::Term>, L<Mail::SPF::Mech>,
L<Mail::SPF::Mod>

L<http://tools.ietf.org/html/rfc4408>

For availability, support, and license information, see the README file
included with Mail::SPF.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>, Shevek <cpan@anarres.org>

=cut

TRUE;
