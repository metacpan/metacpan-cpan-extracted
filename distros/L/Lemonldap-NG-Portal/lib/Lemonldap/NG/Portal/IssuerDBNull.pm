## @file
# Null Issuer file

## @class
# Null Issuer class
package Lemonldap::NG::Portal::IssuerDBNull;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.9.1';

## @method void issuerDBInit()
# Do nothing
# @return Lemonldap::NG::Portal error code
sub issuerDBInit {
    return PE_OK;
}

## @apmethod int issuerForUnAuthUser()
# Do nothing
# @return Lemonldap::NG::Portal error code
sub issuerForUnAuthUser {
    PE_OK;
}

## @apmethod int issuerForAuthUser()
# Do nothing
# @return Lemonldap::NG::Portal error code
sub issuerForAuthUser {
    PE_OK;
}

## @apmethod int issuerLogout()
# Do nothing
# @return Lemonldap::NG::Portal error code
sub issuerLogout {
    PE_OK;
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::IssuerDBNull - Fake IssuerDB for Lemonldap::NG

=head1 DESCRIPTION

This is a fake module for Issuer implementation in LemonLDAP::NG

=head1 SEE ALSO

L<Lemonldap::NG::Portal>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2009-2010 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2009-2012 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
