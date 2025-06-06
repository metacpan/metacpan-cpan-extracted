# LLNG wrapper class to enable ServiceToken handler with auto-protected PSGI
#
# See https://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::PSGI::ServiceToken;

use strict;

use base 'Lemonldap::NG::Handler::Lib::ServiceToken',
  'Lemonldap::NG::Handler::PSGI::Main';

our $VERSION = '2.21.0';

1;
