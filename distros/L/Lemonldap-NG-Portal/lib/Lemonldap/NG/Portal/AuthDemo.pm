##@file
# Demo authentication backend file

##@class
# Demo authentication backend class
package Lemonldap::NG::Portal::AuthDemo;

use strict;
use Lemonldap::NG::Portal::Simple;
use base qw(Lemonldap::NG::Portal::_WebForm);

our $VERSION = '1.9.1';

## @apmethod int authInit()
# Initialize demo accounts
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;

    # Sample accounts from Doctor Who characters
    $self->{_demoAccounts} = {
        'rtyler' => {
            'uid'  => 'rtyler',
            'cn'   => 'Rose Tyler',
            'mail' => 'rtyler@badwolf.org',
        },
        'msmith' => {
            'uid'  => 'msmith',
            'cn'   => 'Mickey Smith',
            'mail' => 'msmith@badwolf.org',
        },
        'dwho' => {
            'uid'  => 'dwho',
            'cn'   => 'Doctor Who',
            'mail' => 'dwho@badwolf.org',
        },
    };

    $self->{_authnLevel} = 0;

    # Add warning in log
    $self->lmLog(
        "Using demonstration mode, go in Manager to edit the configuration",
        'warn' );

    PE_OK;
}

## @apmethod int authenticate()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authenticate {
    my $self = shift;

    return PE_BADCREDENTIALS unless ( $self->{user} eq $self->{password} );

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
    return "standardform";
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::AuthDemo - Perl extension for building Lemonldap::NG
compatible portals with built-in authentication.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::Simple(
         configStorage     => {...}, # See Lemonldap::NG::Portal
         authentication    => 'Demo',
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
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see CGI(3))
    print "<html><body><h1>Unable to work</h1>";
    print "This server isn't well configured. Contact your administrator.";
    print "</body></html>";
  }

=head1 DESCRIPTION

This library just overload few methods of Lemonldap::NG::Portal::Simple to 
create sessions for sample users.

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>,
L<http://lemonldap-ng.org/>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2012 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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

