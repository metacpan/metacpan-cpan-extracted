#!/usr/bin/perl -w

use t::lib::QuickBundle::Test tests => 2;
use Capture::Tiny qw(capture);

create_bundle( <<EOI, 'Modules' );
[application]
name=Modules
version=0.01
dependencies=basic_dependencies
main=t/bin/modules.pl

[basic_dependencies]
scandeps=basic_scandeps

[basic_scandeps]
script=t/bin/modules.pl
EOI

my( $stdout, $stderr ) = capture {
    system( 't/outdir/Modules.app/Contents/MacOS/Modules' );
};
like( $stdout, qr{/t/outdir/Modules.app$} );
is( $stderr, "" );
