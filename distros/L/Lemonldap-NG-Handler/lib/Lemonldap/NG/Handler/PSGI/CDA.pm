# LLNG wrapper class to enable CDA handler with auto-protected PSGI
#
# See http://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::Server::CDA;

use strict;

use base 'Lemonldap::NG::Handler::Lib::CDA',
  'Lemonldap::NG::Handler::PSGI::Main';

our $VERSION = '2.0.0';

1;
