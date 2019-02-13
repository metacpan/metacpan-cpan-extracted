# LLNG wrapper class to enable ZimbraPreAuth handler with Apache-2/ModPerl-2
#
# See https://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::ApacheMP2::ZimbraPreAuth;

use strict;

use base 'Lemonldap::NG::Handler::Lib::ZimbraPreAuth',
  'Lemonldap::NG::Handler::ApacheMP2::Main';

our $VERSION = '2.0.0';

1;
