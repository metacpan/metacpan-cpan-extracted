#!/usr/bin/perl -w

use t::lib::QuickBundle::Test tests => 3;
use Capture::Tiny qw(capture);

create_bundle( <<EOI, 'Missing' );
[application]
name=Missing
version=0.01
dependencies=basic_dependencies
main=t/bin/missing.pl

[basic_dependencies]
scandeps=basic_scandeps

[basic_scandeps]
script=t/bin/missing.pl
EOI

my( $stdout, $stderr ) = capture {
    system( 't/outdir/Missing.app/Contents/MacOS/Missing' );
};
like( $stdout, qr{^Can't locate strict\.pm in}m );
like( $stdout, qr{^Can't locate Cwd\.pm in}m );
is( $stderr, "" );
