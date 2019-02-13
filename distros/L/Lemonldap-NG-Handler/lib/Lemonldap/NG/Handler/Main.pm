# Common class for all handlers
#
# See https://lemonldap-ng.org/documentation/latest/handlerarch
package Lemonldap::NG::Handler::Main;

use strict;
use Lemonldap::NG::Handler::Main::Init;
use Lemonldap::NG::Handler::Main::Reload;
use Lemonldap::NG::Handler::Main::Run;
use Lemonldap::NG::Handler::Main::SharedVariables;

our $VERSION = '2.0.0';

1;
