##@file
# CAS authentication backend file

##@class
# CAS authentication backend class
package Lemonldap::NG::Portal::AuthCAS;

use strict;
use Lemonldap::NG::Portal::Simple;
use URI::Escape;

our $VERSION = '1.9.1';
our $initDone;

BEGIN {
    eval {
        require threads::shared;
        threads::shared::share($initDone);
    };
}

## @apmethod int authInit()
# Try to load AuthCAS perl module
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;
    return PE_OK if ($initDone);

    # require Perl module
    eval { require AuthCAS };
    if ($@) {
        $self->lmLog( "CAS: Module AuthCAS not found in @INC", 'error' );
        return PE_ERROR;
    }

    $initDone = 1;
    PE_OK;
}

## @apmethod int extractFormInfo()
# Read username return by CAS authentication system.
# If user isn't authenticated, redirect it to CAS portal.
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;

    my $cas = new AuthCAS(
        casUrl => $self->{CAS_url},
        CAFile => $self->{CAS_CAFile},
    );

    # Local URL
    my $local_url = $self->url();

    # Add request state parameters
    if ( $self->{_url} ) {
        my $url_param = 'url=' . uri_escape( $self->{_url} );
        $local_url .= ( $local_url =~ /\?/ ? '&' : '?' ) . $url_param;
    }
    if ( $self->param( $self->{authChoiceParam} ) ) {
        my $url_param =
          $self->{authChoiceParam} . '='
          . uri_escape( $self->param( $self->{authChoiceParam} ) );
        $local_url .= ( $local_url =~ /\?/ ? '&' : '?' ) . $url_param;
    }

    # Forward hidden fields
    if ( exists $self->{portalHiddenFormValues} ) {

        $self->lmLog( "Add hidden values to CAS redirect URL\n", 'debug' );

        foreach ( keys %{ $self->{portalHiddenFormValues} } ) {
            $local_url .=
                ( $local_url =~ /\?/ ? '&' : '?' )
              . $_ . '='
              . uri_escape( $self->{portalHiddenFormValues}->{$_} );
        }
    }

    # Act as a proxy if proxied services configured
    my $proxy =
      ref( $self->{CAS_proxiedServices} ) eq 'HASH'
      ? ( %{ $self->{CAS_proxiedServices} } ? 1 : 0 )
      : 0;

    if ($proxy) {
        $self->lmLog( "CAS: Proxy mode activated", 'debug' );
        my $proxy_url = $self->url() . '?casProxy=1';

        if ( $self->param( $self->{authChoiceParam} ) ) {
            $proxy_url .= '&'
              . $self->{authChoiceParam} . '='
              . ( $self->param( $self->{authChoiceParam} ) );
        }

        $self->lmLog( "CAS Proxy URL: $proxy_url", 'debug' );

        $cas->proxyMode(
            pgtFile        => $self->{CAS_pgtFile},
            pgtCallbackUrl => $proxy_url
        );
    }

    # Catch proxy callback
    if ( $self->param('casProxy') ) {
        $self->lmLog( "CAS: Proxy callback detected", 'debug' );

        my $pgtIou = $self->param('pgtIou');
        my $pgtId  = $self->param('pgtId');

        if ( $pgtIou and $pgtId ) {

            # Store pgtId and pgtIou
            unless ( $cas->storePGT( $pgtIou, $pgtId ) ) {
                $self->lmLog( "CAS: error " . &AuthCAS::get_errors(), 'error' );
            }
            else {
                $self->lmLog( "CAS: Store pgtIou $pgtIou and pgtId $pgtId",
                    'debug' );
            }
        }

        # Exit
        print $self->header();
        $self->quit();
    }

    # Build login URL
    my $login_url = $cas->getServerLoginURL($local_url);
    $login_url .= '&renew=true'   if $self->{CAS_renew};
    $login_url .= '&gateway=true' if $self->{CAS_gateway};

    # Check Service Ticket
    my $ticket = $self->param('ticket');

    # Unless a ticket has been found, we redirect the user
    unless ($ticket) {
        $self->lmLog( "CAS: Redirect user to $login_url", 'debug' );
        $self->{urldc} = $login_url;
        return $self->_subProcess(qw(autoRedirect));
    }

    $self->lmLog( "CAS: Service Ticket received: $ticket", 'debug' );

    # Ticket found, try to validate it
    unless ( $self->{user} = $cas->validateST( $local_url, $ticket ) ) {
        $self->lmLog( "CAS: error " . &AuthCAS::get_errors(), 'error' );
        return PE_ERROR;
    }
    else {
        $self->lmLog( "CAS: User " . $self->{user} . " found", 'debug' );
    }

    # Request proxy tickets for proxied services
    if ($proxy) {

        # Check we received a PGT
        my $pgtId = $cas->{pgtId};

        unless ($pgtId) {
            $self->lmLog( "CAS: Proxy mode activated, but no PGT received",
                'error' );
            return PE_ERROR;
        }

        # Get a proxy ticket for each proxied service
        foreach ( keys %{ $self->{CAS_proxiedServices} } ) {
            my $service = $self->{CAS_proxiedServices}->{$_};
            my $pt      = $cas->retrievePT($service);

            unless ($pt) {
                $self->lmLog(
                    "CAS: No proxy ticket recevied for service $service",
                    'error' );
                return PE_ERROR;
            }

            $self->lmLog( "CAS: Received proxy ticket $pt for service $service",
                'debug' );

            # Store it in session
            $self->{sessionInfo}->{ '_casPT' . $_ } = $pt;
        }

    }

    PE_OK;
}

## @apmethod int setAuthSessionInfo()
# Set _user and authenticationLevel.
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    # Store user submitted login for basic rules
    $self->{sessionInfo}->{'_user'} = $self->{'user'};

    $self->{sessionInfo}->{authenticationLevel} = $self->{CAS_authnLevel};

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
# Call CAS server logout URL
# @return Lemonldap::NG::Portal constant
sub authLogout {
    my $self = shift;

    my $cas = new AuthCAS(
        casUrl => $self->{CAS_url},
        CAFile => $self->{CAS_CAFile},
    );

    # Build CAS logout URL
    my $logout_url = $cas->getServerLogoutURL( $self->url() );

    $self->lmLog( "Build CAS logout URL: $logout_url", 'debug' );

    # Register CAS logout URL in logoutServices
    $self->{logoutServices}->{CASserver} = $logout_url;

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

Lemonldap::NG::Portal::AuthCAS - Perl extension for building Lemonldap::NG
compatible portals with CAS authentication.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::Simple(
         configStorage     => {...}, # See Lemonldap::NG::Portal
         authentication    => 'CAS',
         CAS_url           => 'https://cas.myserver',
         CAS_CAFile        => '/etc/httpd/conf/ssl.crt/ca-bundle.crt',
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
    # If the user enters here, IT MEANS THAT CAS REDIRECTION DOES NOT WORK
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see CGI(3))
    print "<html><body><h1>Unable to work</h1>";
    print "This server isn't well configured. Contact your administrator.";
    print "</body></html>";
  }

=head1 DESCRIPTION

This library just overload few methods of Lemonldap::NG::Portal::Simple to use
CAS mechanism: we've just try to get CAS ticket.

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>,
L<http://lemonldap-ng.org/>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

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

=item Copyright (C) 2009-2016 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Copyright (C) 2009 by Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

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

