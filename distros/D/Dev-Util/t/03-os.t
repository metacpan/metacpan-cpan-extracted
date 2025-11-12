#!/usr/bin/env perl

use Test2::V0;
use lib 'lib';

use Dev::Util::Syntax;
use Dev::Util qw(::OS);

plan tests => 17;

#======================================#
#             get_hostname             #
#======================================#

my $expected_host = qx(hostname);
chomp($expected_host);
my $host = get_hostname();
is( $host, $expected_host, "get_hostname - matches hostname" );

$expected_host = qx(uname -n);
chomp($expected_host);
is( $host, $expected_host, "get_hostname - matches uname -n" );

#======================================#
#                get_os                #
#======================================#

my $expected_os = qx(uname -s);
chomp($expected_os);
my $os = get_os();
is( $os, $expected_os, "get_os - matches os" );

#======================================#
#               is_linux               #
#======================================#

if ( $expected_os eq "Linux" ) {
    is( is_linux, 1, "is_linux - true if linux" );
}
else {
    is( is_linux, 0, "is_linux - false if not linux" );
}

#======================================#
#                is_mac                #
#======================================#

if ( $expected_os eq "Darwin" ) {
    is( is_mac, 1, "is_mac - true if macOS" );
}
else {
    is( is_mac, 0, "is_mac - false if not macOS" );
}

#======================================#
#               is_sunos               #
#======================================#

if ( $expected_os eq "SunOS" ) {
    is( is_sunos, 1, "is_sunos - true if sunos" );
}
else {
    is( is_sunos, 0, "is_sunos - false if not sunos" );
}

#======================================#
#              ipc_run_c               #
#======================================#

my $hw_expected = "hello world";
my @hw
    = ipc_run_c( { cmd => 'echo hello world', verbose => 1, timeout => 8 } );
my $hw_result = join "\n", @hw;
is( $hw_result, $hw_expected, 'ipc_run_c - echo hello world' );

my $hw_ref = ipc_run_c( { cmd => 'exho hello world' } );
is( $hw_ref, undef, 'ipc_run_c - fail bad cmd: exho hello world' );

my @expected_seq = qw(1 2 3 4 5 6 7 8 9 10);
my @seq          = ipc_run_c( { cmd => 'seq 1 10', } );
is( @seq, @expected_seq, 'ipc_run_c - multiline output' );

#======================================#
#              ipc_run_e               #
#======================================#

my $buf = qw{};
ok( ipc_run_e( { cmd => 'echo hello world', buf => \$buf, } ) );
is( $buf, $hw_expected . "\n", 'ipc_run_e - hello world' );

# $buf = qw{};
# ok( ipc_run_e( { cmd => 'echo hello world', buf => \$buf, debug => 1 } ) );
# is( $buf, $hw_expected . "\n", 'ipc_run_e - hello world' );

$buf = qw{};
ok( ipc_run_e( { cmd => 'echo hello world', buf => \$buf, verbose => 1 } ) );
is( $buf, $hw_expected . "\n", 'ipc_run_e - hello world' );

$buf = qw{};
ok( ipc_run_e( { cmd => 'echo hello world', buf => \$buf, timeout => 5 } ) );
is( $buf, $hw_expected . "\n", 'ipc_run_e - hello world' );

ok( !ipc_run_e( { cmd => 'exho hello world', buf => \$buf } ) );

$buf = qw{};
ok( ipc_run_e( { cmd => 'seq 1 10', buf => \$buf } ) );

done_testing;
