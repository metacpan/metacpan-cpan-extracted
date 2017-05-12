#!/usr/bin/perl -w

use t::lib::QuickBundle::Test tests => 2;
use Capture::Tiny qw(capture);

create_bundle( <<EOI, 'ExtPerl' );
[application]
name=ExtPerl
version=0.01
dependencies=basic_dependencies
main=t/bin/perl.pl
script=t/bin/basic.pl

[basic_dependencies]
scandeps=basic_scandeps

[basic_scandeps]
script=t/bin/perl.pl
EOI

my( $stdout, $stderr ) = capture {
    system( 't/outdir/ExtPerl.app/Contents/MacOS/ExtPerl' );
};
is( $stdout, "Hello, world!\n" );
like( $stderr, qr{^# .*/perl$}, $stderr );
