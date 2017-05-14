##@file
# Google authentication backend file

##@class
# Google authentication backend class.
package Lemonldap::NG::Portal::AuthGoogle;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Common::Regexp;
use Lemonldap::NG::Portal::_Browser;
use URI::Escape;

use constant AXSPECURL      => 'http://openid.net/srv/ax/1.0';
use constant GOOGLEENDPOINT => 'https://www.google.com/accounts/o8/id';

our @ISA     = (qw(Lemonldap::NG::Portal::_Browser));
our $VERSION = '1.9.1';
our $googleEndPoint;

BEGIN {
    eval {
        require threads::shared;
        threads::shared::share($googleEndPoint);
    };
}

## @method string googleEndPoint()
# Return the Google OpenID endpoint given by
# https://www.google.com/accounts/o8/id
# @return string
sub googleEndPoint {
    my $self = shift;

    # First time, get and store Google endpoint
    unless ($googleEndPoint) {
        my $response =
          $self->ua()->get( GOOGLEENDPOINT, Accept => 'application/xrds+xml' );
        if ( $response->is_success ) {

            # Dirty XML parse
            # (searching for <URI>https://www.google.com/accounts/o8/ud</URI>)
            my $tmp = $response->decoded_content;
            if ( $tmp =~ m#<URI.*?>\s*(\S+)\s*</URI>#mi ) {
                $googleEndPoint = $1;
            }
            else {
                $self->lmLog(
                    'Here is the Google response: '
                      . $response->decoded_content,
                    'error'
                );
                $self->abort('Can\'t find endpoint in Google response');
            }
        }
        else {
            $self->abort( 'Can\'t access to Google endpoint:',
                $response->status_line );
        }
    }
    return $googleEndPoint;
}

## @method boolean checkGoogleSession()
# Search for claimed_id in persistent sessions DB.
# @return true if sessions was recovered
sub checkGoogleSession {
    my $self = shift;

    # Find in Google response for AX attributes
    # See https://developers.google.com/accounts/docs/OpenID#Parameters
    # for more
    ( $self->{_AXNS} ) = map {
            ( /^openid\.ns\.(.*)/ and $self->param($_) eq AXSPECURL )
          ? ($1)
          : ()
    } $self->param();

    # Look at persistent database
    my $id       = $self->param('openid.claimed_id');
    my $pSession = $self->getPersistentSession($id);
    my $gs;

    # No AX response, if datas are already shared, store them
    unless ( $self->{_AXNS} ) {
        if ( $pSession->data ) {
            $self->{user} = $pSession->data->{email};
            foreach my $k ( keys %{ $pSession->data } ) {
                $gs->{$k} = $pSession->data->{$k};
            }
        }
    }
    else {    # Parse AX response

        # First store email as user key. Note that this is the returned value
        # so if it's empty, request is retried
        $self->{user} = $self->param("openid.$self->{_AXNS}.value.email");

        # Retrieve AX datas (and store them in persistent session)
        my $infos;
        foreach my $k ( $self->param() ) {
            if ( $k =~ /^openid\.$self->{_AXNS}\.value\.(\w+)$/ ) {
                $gs->{$1} = $infos->{$1} = $self->param($k);
            }
        }
        $pSession->update($infos);
    }

    # Now store datas in session
    my %vars = ( %{ $self->{exportedVars} }, %{ $self->{googleExportedVars} } );
    while ( my ( $k, $v ) = each %vars ) {
        my $attr = $k;
        $attr =~ s/^!//;

        # Value (ie AX attribute) must be one of:
        if ( $v =~ Lemonldap::NG::Common::Regexp::GOOGLEAXATTR() ) {

            # One value is missing:
            unless ( exists( $gs->{$v} ) ) {

                # Case 1: value was asked but not returned, set an empty value
                #         in persistent session (so that it's defined)
                if ( $self->{_AXNS} ) {
                    $self->_sub( 'userInfo',
"$v required attribute is missing in Google response, storing ''"
                    );
                    $gs->{$v} = '';
                    $pSession->update( { $v => '' } );
                }

                # Case 2: value is not stored, probably configuration has
                #         changed and this value was never asked
                else {
                    $self->_sub( 'userInfo',
"$v required attribute is missing in persistent session, let's ask it"
                    );
                    return 0;
                }
            }
            $self->{sessionInfo}->{$attr} = $gs->{$v};
        }

        # If an exported variable is not AX compliant, just warn
        else {
            $self->lmLog(
"Ignoring attribute $v which is not a valid Google OpenID AX attribute",
                'warn'
            );
        }
    }

    # Boolean value: ~false if no $user value
    return $self->{user};
}

## @apmethod int authInit()
# @return Lemonldap::NG::Portal constant
sub authInit {
    PE_OK;
}

## @apmethod int extractFormInfo()
# Read username return by Google authentication system.
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;
    my $ax   = '';

    # 1. Check Google responses
    if ( $self->param('openid.mode') ) {

        # 1.1 First, verify that the response isn't forged

        # Build verification request
        my $check_url = $self->googleEndPoint() . "?" . join(
            '&',
            map {
                my $val = $self->param($_);
                $val = 'check_authentication' if $_ eq 'openid.mode';
                sprintf '%s=%s', uri_escape_utf8($_), uri_escape_utf8($val);
            } $self->param()
        );

        # Launch request
        my $response = $self->ua()->get( $check_url, Accept => 'text/plain' );
        unless ( $response->is_success ) {
            $self->abort( 'Can\'t verify Google authentication',
                $response->status_line );
        }
        else {
            my %tmp =
              map { my ( $key, $value ) = split /:/, $_, 2; $key => $value }
              split /\n/, $response->decoded_content;

            # Reject invalid requests
            unless ( $tmp{is_valid} eq 'true' ) {
                return PE_BADCREDENTIALS;
            }

            # 1.2 Check if datas are already shared with Google
            unless ( $self->checkGoogleSession() ) {

                # Datas are missing, prepare AX query which will be added to
                # the request to Google

                # a) email is required, will be used as 'user' field
                $ax =
                    '&openid.ns.ax='
                  . AXSPECURL
                  . '&openid.ax.mode=fetch_request'
                  . '&openid.ax.type.email=http://axschema.org/contact/email'
                  . '&openid.ax.required=email';

                # b) if UserDB is Google, ask for exported variables
                if ( $self->get_module('user') eq 'Google' ) {
                    my $u;
                    foreach my $k ( values %{ $self->{exportedVars} } ) {
                        next if ( $k eq 'email' );

                        # Check if wanted attribute is known by Google
                        if ( $k =~
                            /^(?:(?:la(?:nguag|stnam)|firstnam)e|country)$/ )
                        {
                            $ax .= ",$k";

                            # Note: AX type seems to be required by Google
                            $u .= "&openid.ax.type.$k="
                              . {
                                country =>
                                  "http://axschema.org/contact/country/home",
                                firstname =>
                                  "http://axschema.org/namePerson/first",
                                lastname =>
                                  "http://axschema.org/namePerson/last",
                                language => "http://axschema.org/pref/language"
                              }->{$k};
                        }
                        else {
                            $self->lmLog(
                                "Field name: $k is not exported by Google",
                                'warn' );
                        }
                    }
                    $ax .= $u;
                }
            }

            # 1.3 Datas are recovered, user is authenticated
            else {
                $self->lmLog( 'Good Google authentication', 'debug' );

                # Force redirection to avoid displaying OpenID datas
                $self->{mustRedirect} = 1;
                return PE_OK;
            }
        }
    }

    # 2. Redirect user to Google login page:
    #    => no OpenID response or missing datas

    # Build request to Google
    my $check_url =
        $self->googleEndPoint()
      . '?openid.mode=checkid_setup'
      . '&openid.ns=http://specs.openid.net/auth/2.0'
      . '&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select'
      . '&openid.identity=http://specs.openid.net/auth/2.0/identifier_select'
      . $ax;    # Requested attributes if set

    # Build portal URI...
    my $sep      = '?';
    my $returnTo = $self->{portal};
    foreach my $v (
        [ $self->{_url},                            "url" ],
        [ $self->param( $self->{authChoiceParam} ), $self->{authChoiceParam} ]
      )
    {
        if ( $v->[0] ) {
            $returnTo .= "$sep$v->[1]=$v->[0]";
            $sep = '&';
        }
    }

    # ... and add it
    $check_url .= '&openid.return_to=' . uri_escape_utf8($returnTo);

    # Now redirect user
    print $self->redirect($check_url);
    $self->quit();
}

## @apmethod int setAuthSessionInfo()
# Set _user and authenticationLevel.
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    $self->{sessionInfo}->{'_user'} = $self->{user};

    $self->{sessionInfo}->{authenticationLevel} = $self->{googleAuthnLevel};

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

Lemonldap::NG::Portal::AuthGoogle - Perl extension for building Lemonldap::NG
compatible portals with Google authentication.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::Simple(
         configStorage     => {...}, # See Lemonldap::NG::Portal
         authentication    => 'Google',
    );

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see CGI(3))
    print "...";
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
Google authentication mechanism.

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>,
L<http://lemonldap-ng.org/>,
L<https://developers.google.com/accounts/docs/OpenID>

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

=item Copyright (C) 2013 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2013 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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

