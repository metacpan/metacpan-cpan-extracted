# PSGI authentication package written for Nginx. It replace
# Lemonldap::NG::Handler::PSGI::Server to manage Nginx behaviour
package Lemonldap::NG::Handler::Nginx;

use strict;
use Mouse;
use Lemonldap::NG::Handler::SharedConf qw(:tsv);

extends 'Lemonldap::NG::Handler::PSGI';

our $VERSION = '1.9.6';

## @method void _run()
# Return a subroutine that call _authAndTrace() and tranform redirection
# response code from 302 to 401 (not authenticated) ones. This is required
# because Nginx "auth_request" parameter does not accept it. The Nginx
# configuration file should transform them back to 302 using:
#
#   auth_request_set $lmlocation $upstream_http_location;
#   error_page 401 $lmlocation;
#
#@return subroutine that will be called to manage FastCGI queries
sub _run {
    my $self = shift;
    return sub {
        my $req = $_[0];
        $self->lmLog( 'New request', 'debug' );
        my $res = $self->_authAndTrace(
            Lemonldap::NG::Common::PSGI::Request->new($req) );

        # Transform 302 responses in 401 since Nginx refuse it
        if ( $res->[0] == 302 or $res->[0] == 303 ) {
            $res->[0] = 401;
        }
        return $res;
    };
}

## @method PSGI-Response handler()
# Transform headers returned by handler main process:
# each "Name: value" is transformed to:
#  - Headername<i>: Name
#  - Headervalue<i>: value
# where <i> is an integer starting from 1
# It can be used in Nginx virtualhost configuration:
#
#    auth_request_set $headername1 $upstream_http_headername1;
#    auth_request_set $headervalue1 $upstream_http_headervalue1;
#    #proxy_set_header $headername1 $headervalue1;
#    # OR
#    #fastcgi_param $headername1 $headervalue1;
#
# LLNG::Handler::API::PSGI add also a header called Lm-Remote-User set to
# whatToTrace value that can be used in Nginx virtualhost configuration to
# insert user id in logs
#
#    auth_request_set $llremoteuser $upstream_http_lm_remote_user
#
#@param $req Lemonldap::NG::Common::PSGI::Request
sub handler {
    my ( $self, $req ) = @_;
    my $hdrs = $req->{respHeaders};
    $req->{respHeaders} = {};
    my @convertedHdrs =
      ( 'Content-Length' => 0, Cookie => ( $req->cookies // '' ) );
    my $i = 0;
    foreach my $k ( keys %$hdrs ) {
        if ( $k =~ /^(?:Lm-Remote-User|Cookie)$/ ) {
            push @convertedHdrs, $k, $hdrs->{$k};
        }
        else {
            $i++;
            push @convertedHdrs, "Headername$i", $k, "Headervalue$i",
              $hdrs->{$k}, $k, $hdrs->{$k};
        }
    }
    return [ 200, \@convertedHdrs, [] ];
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Lemonldap::NG::Handler::Nginx - Lemonldap::NG FastCGI handler for Nginx.

=head1 SYNOPSIS

FastCGI server:

  use Lemonldap::NG::Handler::Nginx;
  Lemonldap::NG::Handler::Nginx->run( {} );

Launch it with plackup:

  plackup -s FCGI --listen /tmp/llng.sock --no-default-middleware

Configure Nginx:

  http {
    log_format lm_combined '$remote_addr - $lmremote_user [$time_local] '
      '"$request" $status $body_bytes_sent '
      '"$http_referer" "$http_user_agent"';
    
    server {
      server_name test1.example.com;
      access_log /log/file lm_combined
      
      # Internal authentication request
      location = /lmauth {
        internal;
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:__FASTCGISOCKDIR__/llng-fastcgi.sock;
        
        # Drop post datas
        fastcgi_pass_request_body  off;
        fastcgi_param CONTENT_LENGTH "";
        
        # Keep original hostname
        fastcgi_param HOST $http_host;
        
        # Keep original request (LLNG server will received /llauth)
        fastcgi_param X_ORIGINAL_URI  $request_uri;
      }
      
      # Client requests
      location / {
        
        # Activate access control
        auth_request /lmauth;
        
        # Set logs
        auth_request_set $lmremote_user $upstream_http_lm_remote_user;
        auth_request_set $lmlocation $upstream_http_location;
        error_page 401 $lmlocation;
        try_files $uri $uri/ =404;
        
        # Add as many 3-lines block as max number of headers returned by
        # configuration
        auth_request_set $headername1 $upstream_http_headername1;
        auth_request_set $headervalue1 $upstream_http_headervalue1;
        #proxy_set_header $headername1 $headervalue1;
        # OR
        #fastcgi_param $fheadername1 $headervalue1;
        
        auth_request_set $headername2 $upstream_http_headername2;
        auth_request_set $headervalue2 $upstream_http_headervalue2;
        #proxy_set_header $headername2 $headervalue2;
        # OR
        #fastcgi_param $fheadername2 $headervalue2;
        
        auth_request_set $headername3 $upstream_http_headername3;
        auth_request_set $headervalue3 $upstream_http_headervalue3;
        #proxy_set_header $headername3 $headervalue3;
        # OR
        #fastcgi_param $fheadername3 $headervalue3;
    }
  }



=head1 DESCRIPTION

Lemonldap::NG is a modular Web-SSO based on Apache::Session modules. It
simplifies the build of a protected area with a few changes in the application.

It manages both authentication and authorization and provides headers for
accounting. So you can have a full AAA protection for your web space as
described below.

Lemonldap::NG::Handler::Nginx provides a FastCGI server that can be used by
Nginx as authentication server.

=head1 SEE ALSO

L<Lemonldap::NG::Handler>, L<http://lemonldap-ng.org/>,
L<http://nginx.org/en/docs/http/ngx_http_auth_request_module.html>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2016 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2012-2015 by François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Copyright (C) 2006-2012 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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
