## @file
# Remote authentication module

## @class
# Remote authentication module: It simply check the remote session using cross
# domain mechanism.
package Lemonldap::NG::Portal::AuthRemote;

use strict;
use Lemonldap::NG::Portal::_Remote;
use Lemonldap::NG::Portal::Simple;
use base qw(Lemonldap::NG::Portal::_Remote);

our $VERSION = '1.9.1';

*authInit = *Lemonldap::NG::Portal::_Remote::init;

## @apmethod int extractFormInfo()
# Call checkRemoteId() and set $self->{user} and $self->{password}
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;
    my $r    = $self->checkRemoteId();
    return $r unless ( $r == PE_OK );
    $self->{user} =
      $self->{rSessionInfo}->{ $self->{remoteUserField} || 'uid' };
    $self->{password} = $self->{rSessionInfo}->{'_password'};
    PE_OK;
}

## @apmethod int setAuthSessionInfo()
# Delete stored password if local policy does not accept stored passwords.
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    # Store user login for basic rules
    $self->{sessionInfo}->{'_user'} = $self->{'user'};

    # Store password (deleted in checkRemoteId() if local policy does not accept
    #stored passwords)
    $self->{sessionInfo}->{'_password'} = $self->{'password'};

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

Lemonldap::NG::Portal::AuthRemote - Authentication module for Lemonldap::NG
that delegates authentication to a remote Lemonldap::NG portal.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::Simple;
  my $portal = new Lemonldap::NG::Portal::Simple(
         
         # AUTHENTICATION PART
         authentication      => 'Remote', 
         remotePortal        => 'https://auth.remote.com/',
         # Example with SOAP access to remote session DB
         remoteGlobalStorage => 'Lemonldap::NG::Common::Apache::Session::SOAP',
         remoteGlobalStorageOptions => {
             proxy    => 'https://auth.remote.com/index.pl/sessions',
             ns => 'urn://auth.remote.com/Lemonldap/NG/Common/CGI/SOAPService',
             user     => 'myuser',
             password => 'mypass',
         }
         # Optional parameters if remote parameters are not the same.
         # Example with default values:
         remoteCookieName => 'lemonldap',
         remoteUserField  => 'uid',
         
         # USER DATABASE PART (not required if remote users exists in your DB)
         userDB              => 'Remote',
    );

=head1 DESCRIPTION

Authentication module for Lemonldap::NG portal that delegates authentication to
a remote portal.

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
