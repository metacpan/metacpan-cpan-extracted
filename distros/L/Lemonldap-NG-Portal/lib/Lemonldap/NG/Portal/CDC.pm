## @file
# Module for SAML Common Domain Cookie Support

## @class Lemonldap::NG::Portal::CDC
# Class for SAML Common Domain Cookie Support
package Lemonldap::NG::Portal::CDC;

use strict;
use Mouse;
use MIME::Base64;
use Regexp::Assemble;
use Lemonldap::NG::Common::FormEncode;
use URI;

our $VERSION = '2.23.1';

extends 'Lemonldap::NG::Common::PSGI';

# PROPERTIES

has cdc_name         => ( is => 'rw' );
has cdc_domain       => ( is => 'rw' );
has httpOnly         => ( is => 'rw' );
has cookieExpiration => ( is => 'rw' );
has oldStyleUrl      => ( is => 'rw' );
has cdc_values       => ( is => 'rw' );
has trustedDomainsRe => ( is => 'rw' );

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

    # Build the trusted domains regexp used to control redirection URLs
    # (see _isTrustedRedirectUrl()). This prevents the CDC endpoint from being
    # used as an open redirector (CWE-601).
    $self->_buildTrustedDomainsRe($conf);

    return 1;
}

## @method void _buildTrustedDomainsRe($conf)
# Build the regexp of allowed redirection hosts from the configuration.
# @param $conf full configuration hashref
sub _buildTrustedDomainsRe {
    my ( $self, $conf ) = @_;

    # Wildcard trustedDomains: trust any http(s) destination
    if (    $conf->{trustedDomains}
        and $conf->{trustedDomains} =~ /^\s*\*\s*$/ )
    {
        $self->trustedDomainsRe(qr#^https?://#);
        return;
    }

    my $re    = Regexp::Assemble->new();
    my $count = 0;

    # 1. Hosts of every registered SAML federation member (SP and IdP).
    #    We extract them from the raw metadata (entityID and endpoint
    #    Location URLs) with a simple scan, avoiding a full XML/Lasso parse.
    foreach my $key (qw(samlSPMetaDataXML samlIDPMetaDataXML)) {
        my $branch = $conf->{$key};
        next unless ref($branch) eq 'HASH';
        foreach my $entry ( values %$branch ) {
            my $xml =
              ref($entry) eq 'HASH' ? ( $entry->{$key} // '' ) : ( $entry // '' );
            next unless $xml;
            while (
                $xml =~ /\b(?:Location|entityID)\s*=\s*"https?:\/\/([^"\/:]+)/gi )
            {
                $re->add( quotemeta($1) );
                $count++;
            }
        }
    }

    # 2. Explicitly trusted domains
    if ( my $td = $conf->{trustedDomains} ) {
        $td =~ s/^\s*(.*?)\s*$/$1/;
        foreach ( split( /\s+/, $td ) ) {
            next unless ($_);
            s#^\.#([^/]+\.)?#;
            s/\./\\./g;
            s/\*\\\./(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9]\\.)*/g;
            $re->add($_);
            $count++;
        }
    }

    # 3. The portal hosting this CDC
    if ( my $portal = $conf->{portal} ) {
        $portal =~ s#https?://([^/]*).*$#$1#;
        if ($portal) {
            $re->add( quotemeta($portal) );
            $count++;
        }
    }

    unless ($count) {

        # Nothing is trusted: only local relative paths will be allowed
        $self->trustedDomainsRe(undef);
        return;
    }

    my $tmp = '^https?://' . $re->as_string . '(?::\d+)?(?:/|$)';
    $self->trustedDomainsRe(qr/$tmp/);
    return;
}

## @method boolean _isTrustedRedirectUrl($url)
# @param $url decoded (and CRLF-stripped) destination URL
# @return boolean
sub _isTrustedRedirectUrl {
    my ( $self, $url ) = @_;
    return 0 unless defined $url and length $url;
    my $re = $self->trustedDomainsRe;
    return 0 unless $re;
    return $url =~ $re ? 1 : 0;
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

        # Strip CR/LF to prevent HTTP response splitting in the Location header
        $urldc =~ s/[\r\n]//g;

        # Control URL origin to avoid being used as an open redirector
        # (CWE-601). Only local paths and trusted hosts are allowed.
        unless ( $self->_isTrustedRedirectUrl($urldc) ) {
            $self->logger->error(
                "[CDC] Refusing redirection to untrusted URL: $urldc");
            return $self->sendError( $req, "Bad URL", 400 );
        }

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
        return $self->sendRedirection( $req, URI->new($urldc)->as_string, );
    }

    if ($cdc_cookie) {

        # Parse cookie to display it if not redirected
        my @cdc_values =
          map( decode_base64($_), ( split( /\s+/, $cdc_cookie ) ) );
        $self->{cdc_values} = \@cdc_values;
    }

    return $self->sendTextResponse( $req, 'OK', type => 'text/plain' );
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
