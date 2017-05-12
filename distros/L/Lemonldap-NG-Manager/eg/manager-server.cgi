#!/usr/bin/env perl

use Lemonldap::NG::Manager;
use Plack::Handler::CGI;

Plack::Handler::CGI->new->run( Lemonldap::NG::Manager->run( {} ) );

