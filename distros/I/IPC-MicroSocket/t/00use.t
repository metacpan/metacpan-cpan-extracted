#!/usr/bin/perl

use v5.36;

use Test2::V0;

require IPC::MicroSocket;
require IPC::MicroSocket::Client;
require IPC::MicroSocket::Server;

pass( 'Modules loaded' );
done_testing;
