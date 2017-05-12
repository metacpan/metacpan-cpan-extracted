#
# Mail::SPF::SenderIPAddrMech
# Abstract base class for SPF record mechanisms that operate on the SMTP
# sender's IP address.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
# $Id: SenderIPAddrMech.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::SenderIPAddrMech;

=head1 NAME

Mail::SPF::SenderIPAddrMech - Abstract base class for SPF record mechanisms
that operate on the SMTP sender's IP address

=cut

use warnings;
use strict;

use base 'Mail::SPF::Mech';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant explanation_templates_by_result_code => {
    %{__PACKAGE__->SUPER::explanation_templates_by_result_code},
    pass        => "%{c} is authorized to use '%{s}' in '%{_scope}' identity",
    fail        => "%{c} is not authorized to use '%{s}' in '%{_scope}' identity",
    softfail    => "%{c} is not authorized to use '%{s}' in '%{_scope}' identity, however domain is not currently prepared for false failures",
    neutral     => "Domain does not state whether %{c} is authorized to use '%{s}' in '%{_scope}' identity"
};

=head1 DESCRIPTION

B<Mail::SPF::SenderIPAddrMech> is an abstract base class for SPF record
mechanisms that operate on the SMTP sender's IP address.  It cannot be
instantiated directly.  Create an instance of a concrete sub-class instead.

=head2 Constructors

See L<Mail::SPF::Mech/Constructors>.

=head2 Class methods

See L<Mail::SPF::Mech/Class methods>.

=head2 Instance methods

See L<Mail::SPF::Mech/Instance methods>.

=head1 SEE ALSO

L<Mail::SPF>, L<Mail::SPF::Record>, L<Mail::SPF::Mech>

L<Mail::SPF::Mech::IP4>,
L<Mail::SPF::Mech::IP6>,
L<Mail::SPF::Mech::A>,
L<Mail::SPF::Mech::MX>,
L<Mail::SPF::Mech::PTR>

L<http://tools.ietf.org/html/rfc4408>

For availability, support, and license information, see the README file
included with Mail::SPF.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
