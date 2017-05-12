#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 8;
use File::Spec;
use File::Temp;
use File::Copy;
use File::Path;
use Locale::Msgfmt;

sub slurp {
	my $file = shift;
	local *FILE;
	open FILE, '<', $file or die "Could not open ($file) $!";
	binmode FILE;
	my $string = "";
	while ( <FILE> ) {
		$string .= $_;
	}
	close FILE;
	return $string;
}

my $dir = File::Temp::tempdir( CLEANUP => 0 );
copy( File::Spec->catfile( "t", "samples", "basic.po" ), File::Spec->catfile( $dir, "basic.po" ) );
msgfmt( File::Spec->catfile( $dir, "basic.po" ) );
ok( -f File::Spec->catfile( $dir, "basic.mo" ) );
unlink File::Spec->catfile( $dir, "basic.mo" );

msgfmt( { in => File::Spec->catfile( $dir, "basic.po" ) } );
ok( -f File::Spec->catfile( $dir, "basic.mo" ) );
unlink File::Spec->catfile( $dir, "basic.mo" );

msgfmt( { in => File::Spec->catfile( $dir, "basic.po" ), out => File::Spec->catfile( $dir, "mo" ) } );
ok( -f File::Spec->catfile( $dir, "mo" ) );
unlink( File::Spec->catfile( $dir, "mo" ) );

mkdir( File::Spec->catdir( $dir, "a" ) );
mkdir( File::Spec->catdir( $dir, "b" ) );
move( File::Spec->catfile( $dir, "basic.po" ), File::Spec->catfile( $dir, "a", "basic.po" ) );
msgfmt( File::Spec->catdir( $dir, "a" ) );
ok( -f File::Spec->catfile( $dir, "a", "basic.mo" ) );
unlink File::Spec->catfile( $dir, "a", "basic.mo" );

msgfmt( { in => File::Spec->catdir( $dir, "a" ) } );
ok( -f File::Spec->catfile( $dir, "a", "basic.mo" ) );
unlink File::Spec->catfile( $dir, "a", "basic.mo" );

msgfmt( { in => File::Spec->catdir( $dir, "a" ), out => File::Spec->catdir( $dir, "b" ), } );
ok( -f File::Spec->catfile( $dir, "b", "basic.mo" ) );
unlink( File::Spec->catfile( $dir, "b", "basic.mo" ) );

move( File::Spec->catfile( $dir, "a", "basic.po" ), File::Spec->catfile( $dir, "basic.po" ) );
msgfmt( { in => File::Spec->catfile( $dir, "basic.po" ), fuzzy => 1, out => File::Spec->catfile( $dir, "fuzzy" ) } );
msgfmt( { in => File::Spec->catfile( $dir, "basic.po" ), out => File::Spec->catfile( $dir, "not_fuzzy" ) } );
ok( !( slurp( File::Spec->catfile( $dir, "not_fuzzy" ) ) eq slurp( File::Spec->catfile( $dir, "fuzzy" ) ) ) );
unlink( File::Spec->catfile( $dir, "not_fuzzy" ) );
unlink( File::Spec->catfile( $dir, "fuzzy" ) );

move( File::Spec->catfile( $dir, "basic.po" ), File::Spec->catfile( $dir, "a", "basic.po" ) );
msgfmt( { in => File::Spec->catfile( $dir, "a" ), fuzzy => 1, out => File::Spec->catfile( $dir, "b" ) } );
msgfmt( { in => File::Spec->catfile( $dir, "a" ), out => File::Spec->catfile( $dir, "c" ) } );
ok( !( slurp( File::Spec->catfile( $dir, "b", "basic.mo" ) ) eq slurp( File::Spec->catfile( $dir, "c", "basic.mo" ) ) ) );
unlink( File::Spec->catfile( $dir, "c", "basic.mo" ) );
unlink( File::Spec->catfile( $dir, "b", "basic.mo" ) );
