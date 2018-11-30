#!/usr/bin/perl

use Plack::Handler::FCGI;
use Lemonldap::NG::Portal::Main;

# Roll your own
my $server = Plack::Handler::FCGI->new();
$server->run( Lemonldap::NG::Portal::Main->run( {} ) );
