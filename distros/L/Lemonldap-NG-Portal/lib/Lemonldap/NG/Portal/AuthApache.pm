##@file
# Apache authentication backend file

##@class
# Apache authentication backend class
package Lemonldap::NG::Portal::AuthApache;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.9.1';

## @apmethod int authInit()
# @return Lemonldap::NG::Portal constant
sub authInit {
    PE_OK;
}

## @apmethod int extractFormInfo()
# Read username return by Apache authentication system.
# By default, authentication is valid if REMOTE_USER environment
# variable is set.
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;
    unless ( $self->{user} = $ENV{REMOTE_USER} ) {
        $self->lmLog( 'Apache is not configured to authenticate users!',
            'error' );
        return PE_ERROR;
    }

    # This is needed for Kerberos authentication
    $self->{user} =~ s/^(.*)@.*$/$1/g;
    PE_OK;
}

## @apmethod int setAuthSessionInfo()
# Set _user and authenticationLevel.
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    # Store user submitted login for basic rules
    $self->{sessionInfo}->{'_user'} = $self->{'user'};

    $self->{sessionInfo}->{authenticationLevel} = $self->{apacheAuthnLevel};

    PE_OK;
}

## @apmethod int authenticate()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authenticate {
    PE_OK;
}

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
    return "logo";
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::AuthApache - Perl extension for building Lemonldap::NG
compatible portals with Apache authentication.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::Simple(
         configStorage     => {...}, # See Lemonldap::NG::Portal
         authentication    => 'Apache',
    );

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see CGI(3))
    print "...";

    # or redirect the user to the menu
    print $portal->redirect( -uri => 'https://portal/menu');
  }
  else {
    # If the user enters here, IT MEANS THAT APACHE AUTHENTICATION DOES NOT WORK
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see CGI(3))
    print "<html><body><h1>Unable to work</h1>";
    print "This server isn't well configured. Contact your administrator.";
    print "</body></html>";
  }

and of course, configure Apache to protect the portal.

=head1 DESCRIPTION

This library just overload few methods of Lemonldap::NG::Portal::Simple to use
Apache authentication mechanism: we've just try to get REMOTE_USER environment
variable.

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>,
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

=item Copyright (C) 2007-2010 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

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

