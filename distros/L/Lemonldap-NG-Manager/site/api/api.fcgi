#!/usr/bin/perl

use Plack::Handler::FCGI;
use Lemonldap::NG::Manager;

# Roll your own
my $server = Plack::Handler::FCGI->new();
$server->run(
    Lemonldap::NG::Manager->run(
        { enabledModules => "api", protection => "none" }
    )
);
