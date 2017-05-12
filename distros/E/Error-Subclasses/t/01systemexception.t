#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

use Error qw( :try );

use_ok( "Error::SystemException", () );

# First off, find what error 1 is. It doesn't really matter what it is, that
# will just be our standard test value
$! = 1;
my $perror_one = "$!";

my $line;

$line = __LINE__;
my $e = Error::SystemException->new( "A failure" );

ok( defined $e, 'defined $e' );
ok( ref $e && $e->isa( "Error::SystemException" ), 'ref $e' );
ok( $e->isa( "Error" ), '$e->isa( "Error" )' );

is( $e->perror, $perror_one, '$e->perror' );
is( $e->value, 1,            '$e->value' );

is( $e->stringify, "A failure - $perror_one", '$e->stringify' );
is( "$e",          "A failure - $perror_one", '"$e"' );

is( $e->file, $0,      '$e->file' );
is( $e->line, $line+1, '$e->line' );
