#
# Mail::SPF::v2::Record
# Sender ID ("spf2.0") record class.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: Record.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::v2::Record;

=head1 NAME

Mail::SPF::v2::Record - Sender ID ("spf2.0") record class

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

use constant valid_scope            => qr/^(?: mfrom | pra )$/x;
use constant version_tag_pattern    => qr{
    spf(2\.0)
    /
    ( (?: mfrom | pra ) (?: , (?: mfrom | pra ) )* )
    (?= \x20 | $ )
}ix;

=head1 SYNOPSIS

See L<Mail::SPF::Record>.

=head1 DESCRIPTION

An object of class B<Mail::SPF::v2::Record> represents a B<Sender ID>
(C<spf2.0>) record.

=head2 Constructors

The following constructors are provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::v2::Record>

Creates a new Sender ID ("spf2.0") record object.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<text>

=item B<terms>

=item B<global_mods>

See L<Mail::SPF::Record/new>.

=item B<scopes>

I<Required>.  See L<Mail::SPF::Record/new>.  The B<'mfrom'> and B<'pra'> scopes
are supported.  There is no default.

=back

=cut

sub new {
    my ($self, %options) = @_;
    $self = $self->SUPER::new(%options);

    if (not defined($self->{parse_text})) {
        # No parsing is intended, so scopes should have been specified:
        my $scopes = $self->{scopes} || [];
        @$scopes > 0
            or throw Mail::SPF::EInvalidScope('No scopes for spf2.0 record');
        foreach my $scope (@$scopes) {
            $scope =~ $self->valid_scope
                or throw Mail::SPF::EInvalidScope("Invalid scope '$scope' for spf2.0 record");
        }
    }

    return $self;
}

=item B<new_from_string($text, %options)>: returns I<Mail::SPF::v2::Record>;
throws I<Mail::SPF::ENothingToParse>, I<Mail::SPF::EInvalidRecordVersion>,
I<Mail::SPF::ESyntaxError>

Creates a new Sender ID ("spf2.0") record object by parsing the string and
any options given.

=back

=head2 Class methods

The following class methods are provided:

=over

=item B<version_tag_pattern>: returns I<Regexp>

Returns a regular expression that matches a version tag of B<'spf2.0/'> plus a
comma-separated list of any of the B<'mfrom'> and B<'pra'> scopes.  The
following are valid version tags:

    spf2.0/mfrom
    spf2.0/pra
    spf2.0/mfrom,pra
    spf2.0/pra,mfrom

=item B<default_qualifier>

=item B<results_by_qualifier>

See L<Mail::SPF::Record/Class methods>.

=back

=head2 Instance methods

The following instance methods are provided:

=over

=cut

sub parse_version_tag {
    my ($self) = @_;
    if ($self->{parse_text} =~ s/^${\$self->version_tag_pattern}(?:\x20+|$)//) {
        my $scopes = $self->{scopes} = [ split(/,/, $2) ];
        @$scopes > 0
            or throw Mail::SPF::EInvalidScope('No scopes for spf2.0 record');
        foreach my $scope (@$scopes) {
            $scope =~ $self->valid_scope
                or throw Mail::SPF::EInvalidScope("Invalid scope '$scope' for spf2.0 record");
        }
    }
    else {
        throw Mail::SPF::EInvalidRecordVersion(
            "Not a 'spf2.0' record: '" . $self->text . "'");
    }
    return;
}

=item B<text>

=item B<scopes>

=item B<terms>

=item B<global_mods>

=item B<global_mod>

=item B<stringify>

=item B<eval>

See L<Mail::SPF::Record/Instance methods>.

=item B<version_tag>: returns I<string>

Returns B<'spf2.0/'> plus a comma-separated list of the scopes of the record.
See L</version_tag_pattern> for a list of possible return values.

=cut

sub version_tag {
    my ($self) = @_;
    return 'spf2.0'
        if not ref($self)                # called as class method
        or not defined($self->{scopes})  # no scopes parsed
        or not @{$self->{scopes}};       # no scopes specified in record
    return 'spf2.0/' . join(',', @{$self->{scopes}});
}

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
