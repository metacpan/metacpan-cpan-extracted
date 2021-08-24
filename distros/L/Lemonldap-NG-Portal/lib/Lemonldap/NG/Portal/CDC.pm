## @file
# Module for SAML Common Domain Cookie Support

## @class Lemonldap::NG::Portal::CDC
# Class for SAML Common Domain Cookie Support
package Lemonldap::NG::Portal::CDC;

use strict;
use Mouse;
use MIME::Base64;
use Lemonldap::NG::Common::FormEncode;

our $VERSION = '2.0.6';

extends 'Lemonldap::NG::Common::PSGI';

# PROPERTIES

has cdc_name         => ( is => 'rw' );
has cdc_domain       => ( is => 'rw' );
has httpOnly         => ( is => 'rw' );
has cookieExpiration => ( is => 'rw' );
has oldStyleUrl      => ( is => 'rw' );
has cdc_values       => ( is => 'rw' );

# INITIALIZATION

sub init {
    my ( $self, $args ) = @_;
    my $tmp = Lemonldap::NG::Common::Conf->new( $args->{configStorage} );
    unless ($tmp) {
        $self->error(
            "Unable to access configuration: $Lemonldap::NG::Common::Conf::msg"
        );
        return 0;
    }
    my $lconf = $tmp->getLocalConf('portal') // {};
    my $conf  = $tmp->getConf();
    unless ( ref($conf) ) {
        $self->error(
            "Unable to load configuration: $Lemonldap::NG::Common::Conf::msg");
        return 0;
    }
    $lconf->{$_} = $args->{$_}  foreach ( keys %$args );
    $conf->{$_}  = $lconf->{$_} foreach ( keys %$lconf );
    $self->SUPER::init($lconf) or return 0;
    $self->cdc_name( $conf->{samlCommonDomainCookieName} || '_saml_idp' );
    $self->cdc_domain( $conf->{samlCommonDomainCookieDomain} );
    $self->logger->debug( "[CDC] Cookie name: " . $self->cdc_name );
    $self->logger->debug( "[CDC] Domain name: "
          . ( $self->cdc_domain ? $self->cdc_domain : '<host name>' ) );

    foreach (qw(httpOnly cookieExpiration oldStyleUrl)) {
        $self->$_( $conf->{$_} );
    }
    return 1;
}

## @method int process()
# Main method to process CDC requests
# @return portal error code
sub handler {
    my ( $self, $req ) = @_;
    my $cdc_idp    = "";
    my $cdc_cookie = "";

    # Default values
    my $cdc_domain = $self->cdc_domain || $req->hostname;

    # Request parameter
    my $action = $req->param('action') || "";    # What we do
    my $idp    = $req->param('idp');             # IDP ID in write mode

    # TODO: Control URL
    #my $control_url = $self->_sub('controlUrlOrigin');
    #unless ( $control_url == PE_OK ) {
    #    $self->logger->error( "[CDC] Bad URL");
    #    return $control_url;
    #}

    # Get cookie
    $cdc_cookie = $req->cookies->{ $self->cdc_name };

    if ($cdc_cookie) {
        $self->logger->debug("[CDC] Cookie found with value $cdc_cookie");
    }

    # Write request
    # Called in an iFrame
    # Get or build common domain cookie
    # Append IDP to common domain cookie
    if ( $action eq 'write' ) {

        $self->logger->debug("[CDC] Write request detected");

        # Check IDP value
        unless ($idp) {
            return $self->sendError( $req, "[CDC] No IDP given", 400 );
        }

        # Add IDP value
        $self->logger->debug("[CDC] Will add IDP $idp to IDP list");

        my $encoded_idp = encode_base64( $idp, '' );

        # Remove IDP value if already present
        $cdc_cookie =~ s/$encoded_idp(\s+)?//g if ($cdc_cookie);

        # Add a space separator
        $cdc_cookie .= ( $cdc_cookie ? " " : "" );
        $cdc_cookie .= $encoded_idp;

        $self->logger->debug(
            "[CDC] Build cookie $self->{cdc_name} with value $cdc_cookie");

        # Build cookie
        push @{ $req->respHeaders },
            'Set-Cookie' => $self->cdc_name . '='
          . $cdc_cookie
          . "; domain=$cdc_domain; secure=1";
    }

    # Read request
    # Get last IDP from domain cookie
    # Return on SP with idp as parameter

    elsif ( $action eq 'read' ) {

        $self->logger->debug("[CDC] Read request detected");

        # Get last IDP from cookie
        if ($cdc_cookie) {
            $cdc_idp = decode_base64( ( split /\s+/, $cdc_cookie )[-1] );
            $self->logger->debug("[CDC] Get value $cdc_idp");
        }
        else {
            $self->logger->debug("[CDC] No cookie, set a default value");
            $cdc_idp = 'notfound';
        }
    }

    # Redirect if needed
    if ( my $url = $req->param('url') ) {

        # Decode URL
        if ( $url =~ m#[^A-Za-z0-9\+/=]# ) {
            return $self->sendError( $req, "Bad URL", 400 );
        }
        my $urldc = decode_base64($url);

        # Add CDC IDP in return URL if needed
        # olStyleUrl can be set to 1 to use & instead of ;
        $urldc .= (
            $cdc_idp
            ? ( (
                    $urldc =~ /\?/
                    ? ( $self->{oldStyleUrl} ? '&' : ';' )
                    : '?'
                )
                . build_urlencoded( idp => $cdc_idp )
              )
            : ''
        );

        # Redirect
        return [ 302, [ Location => $urldc, $req->spliceHdrs ], [] ];

    }

    if ($cdc_cookie) {

        # Parse cookie to display it if not redirected
        my @cdc_values =
          map( decode_base64($_), ( split( /\s+/, $cdc_cookie ) ) );
        $self->{cdc_values} = \@cdc_values;
    }

    return [
        200,
        [
            'Content-Type'   => 'text/plain',
            'Content-Length' => 2,
            $req->spliceHdrs,
        ],
        ['OK']
    ];
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::CDC - Manage SAML Common Domain Cookie

=head1 SYNOPSIS

Choose any L<Plack> method. CGI example:

  #!/usr/bin/env plackup
  
  use Lemonldap::NG::Portal::CDC;
  
  # This must be the last instruction ! See PSGI for more
  Lemonldap::NG::Portal::CDC->run($opts);

=head1 DESCRIPTION

Lemonldap::NG::Portal::CDC - Manage SAML Common Domain Cookie

See L<http://lemonldap-ng.org> for more.

=head1 SEE ALSO

L<http://lemonldap-ng.org/>

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<https://lemonldap-ng.org/download>

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
