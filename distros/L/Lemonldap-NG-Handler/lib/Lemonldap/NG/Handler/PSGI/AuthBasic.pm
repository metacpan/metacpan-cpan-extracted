# LLNG wrapper class to enable AuthBasic handler with auto-protected PSGI
#
# See http://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::Server::AuthBasic;

use strict;

use base 'Lemonldap::NG::Handler::Lib::AuthBasic',
  'Lemonldap::NG::Handler::PSGI::Main';

our $VERSION = '2.0.0';

1;
