# Main FastCGI handler adapter for LLNG handler
#
# See https://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::Server::Main;

use strict;

our $VERSION = '2.0.15';

use base 'Lemonldap::NG::Handler::PSGI::Main';

use constant defaultLogger => 'Lemonldap::NG::Common::Logger::Syslog';

$ENV{LLNG_DEFAULTLOGGER} ||= defaultLogger;

# In server mode, headers are not passed to a PSGI application but returned
# to the server

## @method void set_header_in(hash headers)
# sets or modifies request headers
# @param headers hash containing header names => header value
sub set_header_in {
    my ( $class, $req, %headers ) = @_;
    for my $k ( keys %headers ) {
        $req->{env}->{ cgiName($k) } = $headers{$k};
    }
    push @{ $req->{respHeaders} }, %headers;
}

## @method void unset_header_in(array headers)
# deletes request headers and push headers that will be removed by LUA
# @param headers array containing header names
sub unset_header_in {
    my ( $class, $req, @headers ) = @_;
    $req->data->{deleteIndex} //= 1;
    my $i = $req->data->{deleteIndex};
    foreach my $header (@headers) {
        $class->logger->debug("Delete header $header");
        $req->{respHeaders} =
          [ grep { $_ ne $header and $_ ne cgiName($header) }
              @{ $req->{respHeaders} } ];
        delete $req->{env}->{ cgiName($header) };
        push @{ $req->{respHeaders} }, "Deleteheader$i", $header;
        $i++;
        push @{ $req->{respHeaders} }, "Deleteheader$i", cgiName($header);
        $header =~ s/-/_/g;
        delete $req->{env}->{$header};
        $i++;
    }
    $req->data->{deleteIndex} = $i;
}

# Inheritence is broken in this case with Debian >= jessie
*checkType          = *Lemonldap::NG::Handler::PSGI::Main::checkType;
*setServerSignature = *Lemonldap::NG::Handler::PSGI::Main::setServerSignature;
*thread_share       = *Lemonldap::NG::Handler::PSGI::Main::thread_share;
*set_user           = *Lemonldap::NG::Handler::PSGI::Main::set_user;
*set_custom         = *Lemonldap::NG::Handler::PSGI::Main::set_custom;
*set_header_out     = *Lemonldap::NG::Handler::PSGI::Main::set_header_out;
*is_initial_req     = *Lemonldap::NG::Handler::PSGI::Main::is_initial_req;
*print              = *Lemonldap::NG::Handler::PSGI::Main::print;
*addToHtmlHead      = *Lemonldap::NG::Handler::PSGI::Main::addToHtmlHead;
*cgiName            = *Lemonldap::NG::Handler::PSGI::Main::cgiName;

1;
