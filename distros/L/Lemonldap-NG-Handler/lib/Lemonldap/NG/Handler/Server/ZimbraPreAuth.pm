# LLNG wrapper class to enable ZimbraPreAuth handler with FastCGI handler
#
# See https://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::Server::ZimbraPreAuth;

use strict;

use base 'Lemonldap::NG::Handler::Lib::ZimbraPreAuth',
  'Lemonldap::NG::Handler::Server::Main';

our $VERSION = '2.0.0';

1;
