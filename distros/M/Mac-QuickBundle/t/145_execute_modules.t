#!/usr/bin/perl -w

use t::lib::QuickBundle::Test tests => 5;

create_bundle( <<EOI, 'ExecuteMod' );
[application]
name=ExecuteMod
version=0.01
dependencies=basic_dependencies
main=t/bin/foo.pl

[basic_dependencies]
scandeps=basic_scandeps

[basic_scandeps]
script=t/bin/bar.pl
inc=t/inc
execute=1
modules=<<EOT
Foo
Bar
Baz
EOT
EOI

ok( -f 't/outdir/ExecuteMod.app/Contents/Resources/Perl-Libraries/Foo.pm' );
ok( -f 't/outdir/ExecuteMod.app/Contents/Resources/Perl-Libraries/Bar.pm' );
ok( -f 't/outdir/ExecuteMod.app/Contents/Resources/Perl-Libraries/Baz.pm' );
ok( -f 't/outdir/ExecuteMod.app/Contents/Resources/Perl-Libraries/Moo.pm' );
ok( -f 't/outdir/ExecuteMod.app/Contents/Resources/Perl-Libraries/Boo.pm' );
