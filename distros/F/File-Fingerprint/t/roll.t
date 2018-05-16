#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More tests => 10;

use File::Spec::Functions;
use Test::Output;

my $class  = 'File::Fingerprint';
my $method = 'roll';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# File exists
{
my $file = catfile( qw(t test_manifest) );
ok( -e $file, "File $file exists" );

my $print = $class->$method( $file );
isa_ok( $print, $class );

# methods that should exist
is( $print->lines,             4, "Right line count for $file" );
is( $print->mmagic, 'text/plain', "Right MIME type for $file" );

# methods that do not exist
stderr_like
	{ eval{ $print->foo } }
	qr/method/,
	"Method foo makes AUTOLOAD cry"
	;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# File does not exist
{
my $file = catfile( qw(t foo) );
ok( ! -e $file, "File $file does not exist" );

stderr_like
	{ eval{ $class->$method() } }
	qr/does not exist/,
	"Fails for missing file"
	;

stderr_like
	{ eval{ $class->$method($file) } }
	qr/does not exist/,
	"File $file does not exist"
	;
}
