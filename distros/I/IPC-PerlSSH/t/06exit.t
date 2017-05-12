#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;
use Test::Fatal;

use IPC::PerlSSH;

my $ips = IPC::PerlSSH->new( Command => "$^X" );

my $exception = exception { $ips->eval( 'exit 1' ) };

like( $exception, qr/^Remote connection closed/, 'exit(1) throws exception' );
