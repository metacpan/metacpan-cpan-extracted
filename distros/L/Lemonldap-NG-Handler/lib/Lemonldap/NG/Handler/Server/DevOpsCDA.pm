# LLNG wrapper class to enable DevOps+CDA handler with FastCGI handler
#
# See https://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::Server::DevOpsCDA;

use strict;

use base 'Lemonldap::NG::Handler::Lib::DevOps',
  'Lemonldap::NG::Handler::Lib::CDA',
  'Lemonldap::NG::Handler::Server::Main';

our $VERSION = '2.0.0';

1;
