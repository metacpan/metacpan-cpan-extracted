## @file
# Get Issuer file
# Enable get parameters for specific applications

## @class
# Get Issuer class
package Lemonldap::NG::Portal::IssuerDBGet;

use strict;
use Lemonldap::NG::Portal::Simple;
use MIME::Base64;
use URI::Escape;
use base qw(Lemonldap::NG::Portal::_LibAccess);

our $VERSION = '1.9.3';

## @method void issuerDBInit()
# Nothing to do
# @return Lemonldap::NG::Portal error code
sub issuerDBInit {
    my $self = shift;

    return PE_OK;
}

## @apmethod int issuerForUnAuthUser()
# Manage Get request for unauthenticated user
# @return Lemonldap::NG::Portal error code
sub issuerForUnAuthUser {
    my $self = shift;

    # Get URLs
    my $issuerDBGetPath = $self->{issuerDBGetPath};
    my $get_login       = 'login';
    my $get_logout      = 'logout';

    # Called URL
    my $url = $self->url();
    my $url_path = $self->url( -absolute => 1 );
    $url_path =~ s#^//#/#;

    # 1. LOGIN
    if ( $url_path =~ m#${issuerDBGetPath}${get_login}#o ) {

        $self->lmLog( "URL $url detected as a Get LOGIN URL", 'debug' );

        # Keep values in hidden fields

    }

    # 2. LOGOUT
    if ( $url_path =~ m#${issuerDBGetPath}${get_logout}#o ) {

        $self->lmLog( "URL $url detected as an Get LOGOUT URL", 'debug' );

        # GET parameters
        my $logout_url = $self->param('url');

        if ($logout_url) {

            # Display a link to the provided URL
            $self->lmLog( "Logout URL $logout_url will be displayed", 'debug' );

            $self->info("<h3>Back to logout url</h3>");
            $self->info("<p><a href=\"$logout_url\">$logout_url</a></p>");
            $self->{activeTimer} = 0;

            return PE_CONFIRM;
        }

        return PE_LOGOUT_OK;

    }

    return PE_OK;
}

## @apmethod int issuerForAuthUser()
# Manage Get request for authenticated user
# @return Lemonldap::NG::Portal error code
sub issuerForAuthUser {
    my $self = shift;

    # Get URLs
    my $issuerDBGetPath = $self->{issuerDBGetPath};
    my $get_login       = 'login';
    my $get_logout      = 'logout';

    # Called URL
    my $url = $self->url();
    my $url_path = $self->url( -absolute => 1 );
    $url_path =~ s#^//#/#;

    # Session ID
    my $session_id = $self->{sessionInfo}->{_session_id} || $self->{id};

    # Session creation timestamp
    my $time = $self->{sessionInfo}->{_utime} || time();

    # 1. LOGIN
    if ( $url_path =~ m#${issuerDBGetPath}${get_login}#o ) {

        $self->lmLog( "URL $url detected as an Get LOGIN URL", 'debug' );

        # Compute GET parameters to send and build urldc accordingly
        &computeGetParams($self);

        $self->lmLog( "Redirect user to " . $self->{urldc}, 'debug' );

        return $self->_subProcess(qw(autoRedirect));
    }

    # 2. LOGOUT
    if ( $url_path =~ m#${issuerDBGetPath}${get_logout}#o ) {

        $self->lmLog( "URL $url detected as an Get LOGOUT URL", 'debug' );

        # GET parameters
        my $logout_url = $self->param('url');

        # Delete local session
        unless (
            $self->_deleteSession( $self->getApacheSession( $session_id, 1 ) ) )
        {
            $self->lmLog( "Fail to delete session $session_id ", 'error' );
        }

        if ($logout_url) {

            # Display a link to the provided URL
            $self->lmLog( "Logout URL $logout_url will be displayed", 'debug' );

            $self->info("<h3>back to logout url</h3>");
            $self->info("<p><a href=\"$logout_url\">$logout_url</a></p>");
            $self->{activeTimer} = 0;

            return PE_CONFIRM;
        }

        return PE_LOGOUT_OK;

    }

    return PE_OK;
}

## @apmethod int issuerLogout()
# Does nothing
# @return Lemonldap::NG::Portal error code
sub issuerLogout {
    my $self = shift;

    # Session ID
    my $session_id = $self->{sessionInfo}->{_session_id} || $self->{id};

    # Delete linked Get sessions

    return PE_OK;
}

## @apmethod string computeGetParams()
# compute GET parameters to send to application
# build urldc accordingly
# @return nothing
sub computeGetParams {
    my $self = shift;

    # Additional GET variables
    my $getVars = "";
    if ( exists $self->{issuerDBGetParameters} ) {
        my $issuerDBGetParameters = $self->{issuerDBGetParameters};
        foreach my $vhost ( keys %$issuerDBGetParameters ) {

            # if vhost is matching
            if ( index( $self->{urldc}, $vhost ) != -1 ) {
                my $params = $issuerDBGetParameters->{$vhost};
                foreach my $param ( keys %$params ) {
                    my $value = $self->{sessionInfo}->{ $params->{$param} };

                    # Chain GET parameters unless there are evaluation errors
                    $getVars .= "&" . $param . "=" . uri_escape($value)
                      unless $@;
                }
            }
        }
    }
    $getVars =~ s/^\&//;         # remove first &
    $getVars =~ s/[\r\n\t]//;    # remove invalid characters

    # If there are some GET variables to send
    # Add them to URL string
    if ( $getVars ne "" ) {
        my $urldc = $self->{urldc};

        $urldc .= ( $urldc =~ /\?\w/ )
          ?

          # there are already get variables
          "&" . $getVars
          :

          # there are no get variables
          "?" . $getVars;
        $self->{urldc} = $urldc;
    }

}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::IssuerDBGet - Get IssuerDB for LemonLDAP::NG

=head1 DESCRIPTION

Get Issuer implementation in LemonLDAP::NG

=head1 SEE ALSO

L<Lemonldap::NG::Portal>,

=head1 AUTHOR

=over

=item David Coutadeur, E<lt>dcoutadeur@linagora.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2016 by David Coutadeur, E<lt>dcoutadeur@linagora.comE<gt>

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

