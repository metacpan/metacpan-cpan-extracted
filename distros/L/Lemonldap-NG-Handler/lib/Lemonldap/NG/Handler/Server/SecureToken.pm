# LLNG wrapper class to enable SecureToken handler with FastCGI handler
#
# See https://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::Server::SecureToken;

use strict;

use base 'Lemonldap::NG::Handler::Lib::SecureToken',
  'Lemonldap::NG::Handler::Server::Main';

our $VERSION = '2.0.0';

1;
