#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;

use IPC::PerlSSH;

my $ips = IPC::PerlSSH->new( Command => "$^X" );

use lib ".";
$ips->use_library( "t::Stash" );

$ips->call( "put", somekey => "myvalue" );
my $value = $ips->call( "get", "somekey" );

is( $value, "myvalue", 'Remote pad works' );
