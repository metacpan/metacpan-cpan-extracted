#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 28;

use IPC::Shm;

# EXERCISE SCALARS

our $pkgvar : Shm;
my ( $tmp );

is( $pkgvar, undef,			"\$pkgvar == undef" );

# test strings
ok( $pkgvar = 'onetwothree',		"\$pkgvar = 'onetwothree'" );
is( $pkgvar, 'onetwothree',		"\$pkgvar == 'onetwothree'" );
ok( $pkgvar .= '456',			"\$pkgvar .= '456'" );
is( $pkgvar, 'onetwothree456',		"\$pkgvar == 'onetwothree456'" );

# test numbers
ok( $pkgvar = 9,			"\$pkgvar = 9" );
is( $pkgvar, 9,				"\$pkgvar == 9" );
ok( $pkgvar--,				"\$pkgvar--" );
is( $pkgvar, 8,				"\$pkgvar == 8" );

# test hashref
ok( $pkgvar = { foo => 'bar' },		"\$pkgvar = { foo => 'bar' }" );
is( $pkgvar->{foo}, "bar",		"\$pkgvar->{foo} == 'bar'" );

# test moving anonymous hash to shm
ok( $tmp = { foo => 'bam' },		"\$tmp = { foo => 'bam' }" );
ok( $pkgvar = $tmp,			"\$pkgvar = \$tmp" );
is( $pkgvar->{foo}, 'bam',		"\$pkgvar->{foo} == 'bam'" );

# test altering via old reference
ok( $tmp->{foo} = 'bat',		"\$tmp->{foo} = 'bat'" );
is( $pkgvar->{foo}, 'bat',		"\$pkgvar->{foo} == 'bat'" );

# test altering via new reference
ok( $pkgvar->{foo} = 'bar',		"\$pkgvar->{foo} = 'bar'" );
is( $tmp->{foo}, 'bar',			"\$tmp->{foo} == 'bar'" );

# EXERCISE LEXICAL SCALARS

my $lexvar : Shm;

is( $lexvar, undef,			"\$lexvar == undef" );

# test strings
ok( $lexvar = 'fourfivesix',		"\$lexvar = 'fourfivesix'" );
is( $lexvar, 'fourfivesix',		"\$lexvar == 'fourfivesix'" );
ok( $lexvar .= '789',			"\$lexvar .= '789'" );
is( $lexvar, 'fourfivesix789',		"\$lexvar == 'fourfivesix789'" );

# test numbers
ok( $lexvar = 42,			"\$lexvar = 42" );
is( $lexvar, 42,			"\$lexvar == 42" );
ok( $lexvar++,				"\$lexvar++" );
is( $lexvar, 43,			"\$lexvar == 43" );

# store reference to lexvar
ok( $pkgvar->{bar} = \$lexvar, 		"\$pkgvar->{bar} = \\\$lexvar" );

