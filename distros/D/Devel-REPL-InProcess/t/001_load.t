#!/usr/bin/perl

use Test::More tests => 5;

use_ok('Devel::REPL::InProcess');
use_ok('Devel::REPL::Plugin::InProcess');
use_ok('Devel::REPL::Server::Select');
use_ok('Devel::REPL::Client::Select');
use_ok('Devel::REPL::Client::AnyEvent');
