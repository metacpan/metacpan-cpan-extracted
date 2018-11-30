# Base package for LLNG portal plugins. It adds somme wrapper to
# Lemonldap::NG::Handler::PSGI::Try (base of portal)
package Lemonldap::NG::Portal::Main::Plugin;

use strict;
use Mouse;
use HTML::Template;

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Common::Module';

sub sendError {
    my $self = shift;
    return $self->p->sendError(@_);
}

sub sendJSONresponse {
    my $self = shift;
    return $self->p->sendJSONresponse(@_);
}

sub addAuthRoute {
    my $self = shift;
    return $self->_addRoute( 'addAuthRoute', @_ );
}

sub addUnauthRoute {
    my $self = shift;
    return $self->_addRoute( 'addUnauthRoute', @_ );
}

sub _addRoute {
    my ( $self, $type, $word, $subName, $methods, $transform ) = @_;
    $transform //= sub {
        my ($sub) = @_;
        if ( ref $sub ) {
            return sub {
                shift;
                return $sub->( $self, @_ );
              }
        }
        else {
            return sub {
                shift;
                return $self->$sub(@_);
              }
        }
    };
    $self->p->$type( $word, $subName, $methods, $transform );
    return $self;
}

sub loadTemplate {
    my $self = shift;
    return $self->p->loadTemplate(@_);
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Lemonldap::NG::Portal::Main::Plugin - Base class for
L<Lemonldap::NG::Portal> modules I<(plugins, authentication modules,...)>.

=head1 SYNOPSIS

  package Lemonldap::NG::Portal::My::Plugin;
  use Mouse;
  extends 'Lemonldap::NG::Portal::Main::Plugin';
  
  use constant beforeAuth => 'verifyIP';
  
  sub init {
      my ($self) = @_;
      $self->addUnauthRoute( mypath => 'hello', [ 'GET', 'PUT' ] );
      $self->addAuthRoute( mypath => 'welcome', [ 'GET', 'PUT' ] );
      return 1;
  }
  sub verifyIP {
      my ($self, $req) = @_;
      return PE_ERROR if($req->address !~ /^10/);
      return PE_OK;
  }
  sub hello {
      my ($self, $req) = @_;
      ...
      return $self->p->sendJSONresponse($req, { hello => 1 });
  }
  sub welcome {
      my ($self, $req) = @_;
      ...
      return $self->p->sendHtml($req, 'template', params => { WELCOME => 1 });
  }

=head1 DESCRIPTION

Lemonldap::NG::Portal::Main::Plugin provides many methods to easily write 
Lemonldap::NG addons.

init() is called for each plugin. If a plugin initialization fails (init()
returns 0), the portal responds a 500 status code for each request.

=head1 Writing plugins

Custom plugins can be inserted in portal by declaring them in
C<lemonldap-ng.ini> file, section C<[portal]>, key C<customPlugins>:

  [portal]
  customPlugins = My::Plugin1, My::Plugin2

Plugins must be valid packages well found in C<@INC>.

=head2 Plugin entry points

=head3 Entry point based on PATH_INFO

Plugins can declare unauthRoutes/authRoutes during initialization (=
/path/info). Methods declared in this way must be declared in the plugin class.
They will be called with $req argument. $req is the HTTP request.
(See L<Lemonldap::NG::Portal::Main::Request>). These methods must return a valid
L<PSGI> response. You can also use sendJSONresponse() or sendHtml() methods
(see L<Lemonldap::NG::Common::PSGI>).

Example:

  sub init {
      my ($self) = @_;
      $self->addUnauthRoute( mypath => 'hello', [ 'GET', 'PUT' ] );
      $self->addAuthRoute( mypath => 'welcome', [ 'GET', 'PUT' ] );
      return 1;
  }
  sub hello {
      my ($self, $req) = @_;
      ...
      return $self->p->sendJSONresponse($req, { hello => 1 });
  }
  sub welcome {
      my ($self, $req) = @_;
      ...
      return $self->p->sendHtml($req, 'template', params => { WELLCOME => 1 });
  }

=head3 Entry point in auth process

A plugin which wants to be inserted in authentication process has to declare
constants set with method name to run. Following entry points are available.

=over

=item C<beforeAuth>: method called before authentication process

=item C<betweenAuthAndData>: method called after authentication and before
setting C<sessionInfo> provisionning

=item C<afterData>: method called after C<sessionInfo> provisionning
I<(macros, groups,...)>

=item C<endAuth>: method called when session is validated (after cookie build)

=item C<authCancel>: method called when user click on "cancel" during auth
process

=item C<forAuthUser>: method called for already authenticated users

=item C<beforeLogout>: method called before logout

=back

B<Note>: methods inserted so must return a PE_* constant. See
Lemonldap::NG::Portal::Main::Constants.

=head1 SEE ALSO

L<http://lemonldap-ng.org>

=head2 OTHER POD FILES

=over

=item Writing an authentication module: L<Lemonldap::NG::Portal::Auth>

=item Writing a UserDB module: L<Lemonldap::NG::Portal::UserDB>

=item Writing a second factor module: L<Lemonldap::NG::Portal::Main::SecondFactor>

=item Writing an issuer module: L<Lemonldap::NG::Portal::Main::Issuer>

=item Writing another plugin: L<Lemonldap::NG::Portal::Main::Plugin>

=item Request object: L<Lemonldap::NG::Portal::Main::Request>

=item Adding parameters in the manager: L<Lemonldap::NG::Manager::Build>

=back

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

See COPYING file for details.

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
