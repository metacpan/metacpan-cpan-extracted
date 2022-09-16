# Apache2 FastCGI client to query remote LL::NG FastCGI server
#
package Lemonldap::NG::SSOaaS::Apache::Client;

use strict;
use Apache2::Connection;
use Apache2::RequestUtil;
use Apache2::RequestRec;
use Apache2::Const -compile =>
  qw(FORBIDDEN HTTP_UNAUTHORIZED REDIRECT OK DECLINED DONE SERVER_ERROR AUTH_REQUIRED HTTP_SERVICE_UNAVAILABLE);
use Apache2::Log;
use APR::Table;
use IO::Socket::INET;
use FCGI::Client;
use URI;
use URI::Escape qw(uri_unescape);

use constant FORBIDDEN         => Apache2::Const::FORBIDDEN;
use constant HTTP_UNAUTHORIZED => Apache2::Const::HTTP_UNAUTHORIZED;
use constant REDIRECT          => Apache2::Const::REDIRECT;
use constant DECLINED          => Apache2::Const::DECLINED;
use constant SERVER_ERROR      => Apache2::Const::SERVER_ERROR;

our $VERSION = '2.0.15';

sub handler {
    my ( $class, $r ) = @_;
    $r ||= $class;
    my ( $uri, $args ) = ( $r->uri, $r->args );
    my $uri_full = $uri . ( $args ? "?$args" : '' );
    my $env      = {

        #%ENV,
        HTTP_HOST   => $r->hostname,
        REMOTE_ADDR => (
              $r->connection->can('remote_ip')
            ? $r->connection->remote_ip
            : $r->connection->client_ip
        ),
        QUERY_STRING   => $args,
        REQUEST_URI    => $uri_full,
        PATH_INFO      => '',
        SERVER_PORT    => $r->get_server_port,
        REQUEST_METHOD => $r->method,
    };

    foreach (qw(VHOSTTYPE RULES_URL HTTPS_REDIRECT PORT_REDIRECT)) {
        if ( my $t = $r->dir_config($_) ) {
            $env->{$_} = $t;
        }
    }

    $r->headers_in->do(
        sub {
            my $h = shift;
            my $k = uc($h);
            if ( $k ne 'HOST' ) {
                $k =~ s/-/_/g;
                $env->{"HTTP_$k"} = $r->headers_in->{$h};
            }
            return 1;
        }
    );
    $uri = URI->new( "http://" . $r->hostname . $r->unparsed_uri );
    $env->{PATH_INFO} = uri_unescape( $uri->path );
    my ( $host, $port ) = ( $r->dir_config('LLNG_SERVER') =~ /^(.*):(\d+)$/ );
    unless ( $host and $port ) {
        print STDERR 'Missing or bad LLNG_SERVER';
        return SERVER_ERROR;
    }
    my $sock = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
    ) or die $!;
    foreach ( keys %$env ) {
        delete $env->{$_} unless ( length $env->{$_} );
    }
    my ( $stdout, $stderr, $status ) =
      FCGI::Client::Connection->new( sock => $sock )->request($env);
    my %hdrs =
      map { s/\r//g; m/(.*?):\s*(.*)/; $_ ? ( $1, $2 ) : () } split /\n+/,
      $stdout;
    unless ( $hdrs{Status} =~ /^(\d+)\s+(.*?)$/ ) {
        print STDERR "Bad status line $hdrs{Status}\n";
        return SERVER_ERROR;
    }
    $status = $1;

    if ( ( $status == 302 or $status == 401 ) and $hdrs{Location} ) {
        $r->err_headers_out->set( Location => $hdrs{Location} );
        return REDIRECT;
    }

    $r->user( $hdrs{'Lm-Remote-User'} ) if $hdrs{'Lm-Remote-User'};
    $r->subprocess_env( REMOTE_CUSTOM => $hdrs{'Lm-Remote-Custom'} )
      if $hdrs{'Lm-Remote-Custom'};

    my $i = 1;
    while ( $hdrs{"Headername$i"} ) {
        $r->headers_in->set( $hdrs{"Headername$i"} => $hdrs{"Headervalue$i"} )
          if $hdrs{"Headervalue$i"};
        $i++;
    }
    $status = DECLINED if ( $status < 300 );

    return $status;
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Lemonldap::NG::SSOaaS::Apache::Client - Apache client for Lemonldap::NG
FastCGI server.

=head1 SYNOPSIS

In apache2.conf:

  <VirtualHost ...>
    PerlHeaderParserHandler Lemonldap::NG::SSOaaS::Apache::Client
    PerlSetVar LLNG_SERVER 127.0.0.1:9090
    PerlSetVar VHOSTTYPE DevOps
    # or PerlSetVar VHOSTTYPE DevOpsST
    PerlSetVar RULES_URL http://app.tld/rules.json
    PerlSetVar HOST HTTP_HOST
    PerlSetVar PORT_REDIRECT SERVER_PORT
    PerlSetVar HTTPS_REDIRECT HTTPS
    ...
  </VirtualHost>

=head1 DESCRIPTION

Lemonldap::NG::SSOaaS::Apache::Client is an alternative to
L<Lemonldap::NG::Handler::ApacheMP2> that replace inside handler. It calls a
remote Lemonldap::NG FastCGI server to get authentication, authorization and
headers.

=head1 SEE ALSO

L<Lemonldap::NG::Handler::ApacheMP2>,
L<https://lemonldap-ng.org/documentation/latest/ssoaas>

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<https://lemonldap-ng.org/team.html>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<https://lemonldap-ng.org/download.html>

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
