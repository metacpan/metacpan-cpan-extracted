#!/usr/bin/perl

use Lemonldap::NG::Manager;

Lemonldap::NG::Manager->run(
    { enabledModules => "api", protection => "none" } );
