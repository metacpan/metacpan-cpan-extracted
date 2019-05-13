# LLNG wrapper class to enable OAuth2 handler with Apache-2/ModPerl-2
#
# See https://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::ApacheMP2::OAuth2;

use strict;

use base 'Lemonldap::NG::Handler::Lib::OAuth2',
  'Lemonldap::NG::Handler::ApacheMP2::Main';

our $VERSION = '2.0.4';

1;
