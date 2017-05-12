##@file
# Auth-basic authentication with Lemonldap::NG rights management

##@class
# Auth-basic authentication with Lemonldap::NG rights management

# This specific handler is intended to be called directly by Apache

package Lemonldap::NG::Handler::Specific::AuthBasic;

use Lemonldap::NG::Handler::SharedConf qw(:all);
use Lemonldap::NG::Handler::API qw(:httpCodes);
use Digest::MD5;
use MIME::Base64;
use HTTP::Headers;
use SOAP::Lite;    # link protected portalRequest
use Lemonldap::NG::Common::Session;

use base qw(Lemonldap::NG::Handler::SharedConf);

our $VERSION = '1.9.1';

sub handler {
    my ( $class, $request ) = ( __PACKAGE__, shift );
    Lemonldap::NG::Handler::API->newRequest($request);
    $class->run($request);
}

## @rmethod Apache2::Const run(Apache2::RequestRec r)
# Overload main run method
# @param r Current request
# @return Apache2::Const value (OK, FORBIDDEN, REDIRECT or SERVER_ERROR)
sub run {
    my $class = shift;
    my $r     = $_[0];
    return $class->SUPER::run();
}

## @rmethod protected fetchId
# Get user session id from Authorization header
# Unlike usual processing, session id is computed from user creds,
# so that it remains secret but handler can easily get it.
# It is still changed from time to time - once a day - to prevent from
# using indefinitely a session id disclosed accidentally or maliciously.
# @return session id
sub fetchId {
    my $class = shift;
    if ( my $creds = Lemonldap::NG::Handler::API->header_in('Authorization') ) {
        $creds =~ s/^Basic\s+//;
        my @date = localtime;
        my $day  = $date[5] * 366 + $date[7];
        return Digest::MD5::md5_hex( $creds . $day );
    }
    else {
        return 0;
    }
}

## @rmethod protected boolean retrieveSession(id)
# Tries to retrieve the session whose index is id,
# and if needed, ask portal to create it through a SOAP request
# @return true if the session was found, false else
sub retrieveSession {
    my ( $class, $id ) = @_;

    # First check if session already exists
    return 1 if ( $class->SUPER::retrieveSession($id) );

    # Then ask portal to create it
    if ( $class->createSession($id) ) {
        return $class->SUPER::retrieveSession($id);
    }
    else {
        return 0;
    }
}

## @rmethod protected boolean retrieveSession(id)
# Ask portal to create it through a SOAP request
# @return true if the session is created, else false
sub createSession {
    my ( $class, $id ) = @_;

    # Add client IP as X-Forwarded-For IP in SOAP request
    my $xheader = Lemonldap::NG::Handler::API->header_in('X-Forwarded-For');
    $xheader .= ", " if ($xheader);
    $xheader .= Lemonldap::NG::Handler::API->remote_ip;
    my $soapHeaders = HTTP::Headers->new( "X-Forwarded-For" => $xheader );

    my $soapClient =
      SOAP::Lite->proxy( $tsv->{portal}->(), default_headers => $soapHeaders )
      ->uri('urn:Lemonldap::NG::Common::CGI::SOAPService');

    my $creds = Lemonldap::NG::Handler::API->header_in('Authorization');
    $creds =~ s/^Basic\s+//;
    my ( $user, $pwd ) = ( decode_base64($creds) =~ /^(.*?):(.*)$/ );
    Lemonldap::NG::Handler::Main::Logger->lmLog(
        "AuthBasic authentication for user: $user", 'debug' );
    my $soapRequest = $soapClient->getCookies( $user, $pwd, $id );

    # Catch SOAP errors
    if ( $soapRequest->fault ) {
        $class->abort( "SOAP request to the portal failed: "
              . $soapRequest->fault->{faultstring} );
    }
    else {
        my $res = $soapRequest->result();

        # If authentication failed, display error
        if ( $res->{errorCode} ) {
            Lemonldap::NG::Handler::Main::Logger->lmLog(
                "Authentication failed for $user: "
                  . $soapClient->error( $res->{errorCode}, 'en' )->result(),
                'notice'
            );
            return 0;
        }
        else {
            return 1;
        }
    }
}

## @rmethod protected void hideCookie()
# Hide user credentials to the protected application
sub hideCookie {
    my $class = shift;
    Lemonldap::NG::Handler::Main::Logger->lmLog(
        "removing Authorization header", 'debug' );
    Lemonldap::NG::Handler::API->unset_header_in('Authorization');
}

## @rmethod protected int goToPortal(string url, string arg)
# If user is asked to authenticate, return AUTH_REQUIRED,
# else redirect him to the portal to display some message defined by $arg
# @param $url Url requested
# @param $arg optionnal GET parameters
# @return Apache2::Const::REDIRECT or Apache2::Const::AUTH_REQUIRED
sub goToPortal {
    my ( $class, $url, $arg ) = @_;
    if ($arg) {
        return $class->SUPER::goToPortal( $url, $arg );
    }
    else {
        Lemonldap::NG::Handler::API->set_header_out(
            'WWW-Authenticate' => 'Basic realm="LemonLDAP::NG"' );
        return AUTH_REQUIRED;
    }
}

__PACKAGE__->init();

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Handler::AuthBasic - Perl extension to be able to authenticate
users by basic web system but to use Lemonldap::NG to control authorizations.

=head1 SYNOPSIS

Create your own package:

  package My::Package;
  use Lemonldap::NG::Handler::AuthBasic;
  
  # IMPORTANT ORDER
  our @ISA = qw (Lemonldap::NG::Handler::AuthBasic);
  
  __PACKAGE__->init ( {
    # Local storage used for sessions and configuration
    localStorage        => "Cache::DBFile",
    localStorageOptions => {...},
    # How to get my configuration
    configStorage       => {
        type                => "DBI",
        dbiChain            => "DBI:mysql:database=lemondb;host=$hostname",
        dbiUser             => "lemonldap",
        dbiPassword         => "password",
    }
    # Uncomment this to activate status module
    # status                => 1,
  } );

Call your package in <apache-directory>/conf/httpd.conf

  PerlRequire MyFile
  PerlHeaderParserHandler My::Package

=head1 DESCRIPTION

This library provides a way to use Lemonldap::NG to manage authorizations
without using Lemonldap::NG for authentications. This can be used in conjunction
with a normal Lemonldap::NG installation but to manage non-browser clients.

=head1 SEE ALSO

L<Lemonldap::NG::Handler(3)>,
L<http://lemonldap-ng.org/>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

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

=item Copyright (C) 2008-2010 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2012-2013 by François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

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
