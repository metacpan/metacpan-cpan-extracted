## @file
# Proxy authentication module

## @class
# Proxy authentication module: It simply call another Lemonldap::NG portal by
# SOAP using credentials
package Lemonldap::NG::Portal::AuthProxy;

use strict;
use Lemonldap::NG::Portal::_Proxy;
use Lemonldap::NG::Portal::_WebForm;
use Lemonldap::NG::Portal::Simple;
use base qw(Lemonldap::NG::Portal::_WebForm Lemonldap::NG::Portal::_Proxy);

our $VERSION = '1.9.1';

## @apmethod int authInit()
# Call Lemonldap::NG::Portal::_Proxy::proxyInit();
# @return Lemonldap::NG::Portal constant
*authInit = *Lemonldap::NG::Portal::_Proxy::proxyInit;

## @apmethod int authenticate()
# Call Lemonldap::NG::Portal::_Proxy::proxyQuery()
# @return Lemonldap::NG::Portal constant
*authenticate = *Lemonldap::NG::Portal::_Proxy::proxyQuery;

## @apmethod int setAuthSessionInfo()
# Call Lemonldap::NG::Portal::_Proxy::setSessionInfo()
# @return Lemonldap::NG::Portal constant
*setAuthSessionInfo = *Lemonldap::NG::Portal::_Proxy::setSessionInfo;

## @apmethod int authFinish()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authFinish {
    PE_OK;
}

## @apmethod int authLogout()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub authLogout {
    PE_OK;
}

## @apmethod boolean authForce()
# Does nothing
# @return result
sub authForce {
    return 0;
}

## @method string getDisplayType
# @return display type
sub getDisplayType {
    return "standardform";
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::AuthProxy - Authentication module for Lemonldap::NG
that delegates authentication to a remote Lemonldap::NG portal.

The difference with Remote authentication module is that the client will never
be redirected to the main Lemonldap::NG portal. This configuration is usable if
you want to expose your internal SSO to another network (DMZ).

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::SharedConf(
         
         # REQUIRED PARAMETERS
         authentication      => 'Proxy', 
         userDB          => 'Proxy',
         soapAuthService => 'https://auth.internal.network/',
  
         # OTHER PARAMETERS
         # remoteCookieName (default: same name)
         remoteCookieName => 'lemonldap',
         # soapSessionService (default ${soapAuthService}index.pl/sessions)
         soapSessionService =>
            'https://auth2.internal.network/index.pl/sessions',
    );

=head1 DESCRIPTION

Authentication module for Lemonldap::NG portal that forward credentials to a
remote Lemonldap::NGportal using SOAP request. Note that the remote portal must
accept SOAP requests ("Soap=>1").

=head1 SEE ALSO

L<http://lemonldap-ng.org/>

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

=item Copyright (C) 2010-2012 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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
