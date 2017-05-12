package Lemonldap::NG::Handler::API::PSGI::Server;

use strict;

use base 'Lemonldap::NG::Handler::API::PSGI';

*cgiName       = *Lemonldap::NG::Handler::API::PSGI::cgiName;
*uri_with_args = *Lemonldap::NG::Handler::API::PSGI::uri_with_args;

# In server mode, headers are not passed to a PSGI application but returned
# to the server

## @method void set_header_in(hash headers)
# sets or modifies request headers
# @param headers hash containing header names => header value
sub set_header_in {
    my ( $class, %headers ) = @_;
    for my $k ( keys %headers ) {
        $Lemonldap::NG::Handler::API::PSGI::request->{ cgiName($k) } =
          $Lemonldap::NG::Handler::API::PSGI::request->{respHeaders}->{$k} =
          $headers{$k};
    }
}

sub unset_header_in {
    my ( $class, $header ) = @_;
    delete $Lemonldap::NG::Handler::API::PSGI::request->{respHeaders}
      ->{$header};
    $header =~ s/-/_/g;
    delete $Lemonldap::NG::Handler::API::PSGI::request->{ cgiName($header) };
}

1;
