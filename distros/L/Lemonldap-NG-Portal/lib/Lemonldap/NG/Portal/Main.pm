package Lemonldap::NG::Portal::Main;

use strict;
use Mouse;

use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Portal::Main::Constants ':all';
use Lemonldap::NG::Portal::Main::Request;
use Lemonldap::NG::Portal::Main::Plugins;
use Lemonldap::NG::Portal::Main::Init;
use Lemonldap::NG::Portal::Main::Run;
use Lemonldap::NG::Portal::Main::Process;
use Lemonldap::NG::Portal::Main::Display;
use Lemonldap::NG::Portal::Main::Menu;

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Handler::PSGI::Try';

1;
