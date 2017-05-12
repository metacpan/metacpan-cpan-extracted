#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 12;

use IPC::Shm;

# VERIFY SCALARS

our $pkgvar : Shm;
my ( $tmp );

is( $pkgvar->{foo}, 'bar',		"\$pkgvar->{foo} == 'bar'" );

ok( $tmp = $pkgvar->{bar},		"\$tmp = \$pkgvar->{bar}" );


is( $$tmp, 43,				"\$\$tmp == 43" );

ok( $tmp = $pkgvar,			"\$tmp = \$pkgvar" );
is( $tmp, $pkgvar,			"\$tmp == \$pkgvar" );

is( $tmp->{foo}, 'bar',			"\$tmp->{foo} == 'bar'" );

undef $pkgvar;
ok( 1,					"undef \$pkgvar" );
is( $pkgvar, undef,			"\$pkgvar == undef" );

is( $tmp->{foo}, 'bar',			"\$tmp->{foo} == 'bar'" );

undef $tmp;
ok( 1,					"undef \$tmp" );
is( $tmp, undef,			"\$tmp == undef" );

# VERIFY LEXICALS

my $lexvar : Shm;

is( $lexvar, undef,			"\$lexvar == undef" );

