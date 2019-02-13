# LLNG wrapper class to enable DevOps+ServiceToken handler with Apache-2/ModPerl-2
#
# See https://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::ApacheMP2::DevOpsST;

use strict;

use base 'Lemonldap::NG::Handler::Lib::DevOps',
  'Lemonldap::NG::Handler::Lib::ServiceToken',
  'Lemonldap::NG::Handler::ApacheMP2::Main';

our $VERSION = '2.0.0';

1;
