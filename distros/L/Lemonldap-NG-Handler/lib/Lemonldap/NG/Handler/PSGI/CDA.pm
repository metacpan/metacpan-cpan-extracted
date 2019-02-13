# LLNG wrapper class to enable CDA handler with auto-protected PSGI
#
# See https://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::PSGI::CDA;

use strict;

use base 'Lemonldap::NG::Handler::Lib::CDA',
  'Lemonldap::NG::Handler::PSGI::Main';

our $VERSION = '2.0.2';

1;
