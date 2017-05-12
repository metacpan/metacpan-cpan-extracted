#!/usr/bin/perl -w

use t::lib::QuickBundle::Test tests => 2;
use Capture::Tiny qw(capture);

create_bundle( <<EOI, 'Basic' );
[application]
name=Basic
version=0.01
dependencies=basic_dependencies
main=t/bin/basic.pl

[basic_dependencies]
scandeps=basic_scandeps

[basic_scandeps]
script=t/bin/basic.pl
EOI

my( $stdout, $stderr ) = capture {
    system( 't/outdir/Basic.app/Contents/MacOS/Basic' );
};
is( $stdout, "Hello, world!\n" );
is( $stderr, "" );
