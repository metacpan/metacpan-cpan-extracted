#!/usr/bin/perl -w

use strict;

use Test::More tests => 8;

use IPC::PerlSSH;

my $ips = IPC::PerlSSH->new( Command => "$^X" );

$ips->use_library( "Run", qw( system system_in system_out system_inout system_outerr ) );

ok( 1, 'library loaded' );

my $result = $ips->call( "system", "$^X", "-e", "exit 5" );
is( $result, 5<<8, 'system result' );

$result = $ips->call( "system_in", "Here is an input string\n", "$^X", "-e", "exit length <STDIN>" );
is( $result, length("Here is an input string\n")<<8, 'system_in result' );

( $result, my $stdout ) = $ips->call( "system_out", "$^X", "-e", "print qq{Hello world\\n}; exit 3" );
is( $result, 3<<8,            'system_out result' );
is( $stdout, "Hello world\n", 'system_out stdout' );

( $result, $stdout ) = $ips->call( "system_inout", "Another input string\n", "$^X", "-pe", '$_ = uc' );
is( $stdout, "ANOTHER INPUT STRING\n", 'system_inout stdout' );

( $result, $stdout, my $stderr ) = $ips->call( "system_outerr", "$^X", "-e", 'print STDOUT "OUT\n"; print STDERR "ERR\n"' );
is( $stdout, "OUT\n", 'system_outerr stdout' );
is( $stderr, "ERR\n", 'system_errerr stderr' );
