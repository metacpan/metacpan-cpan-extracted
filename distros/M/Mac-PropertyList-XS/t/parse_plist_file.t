#!/usr/bin/perl
# Stolen from Mac::PropertyList (by comdog) for use in Mac::PropertyList::XS (by kulp)
use strict;
use warnings;

use Test::More 'no_plan';

my $Class = 'Mac::PropertyList::XS';
my $suborned = 'Mac::PropertyList::SAX';
use_ok( $Class );

$Class->import( 'parse_plist_file' );

my $File = "plists/com.apple.systempreferences.plist";

ok( -e $File, "Sample plist file exists" );

########################################################################
{
ok(
	open( my( $fh ), $File ),
	"Opened $File"
	);

my $plist = parse_plist_file( $fh );

ok( $plist, "return value is not false" );
isa_ok( $plist, "${suborned}::dict" );
is( $plist->type, 'dict', 'type key has right value for nested dict' );
test_plist( $plist );
}

########################################################################

{
ok(
	open( FILE, $File ),
	"Opened $File"
	);

my $plist = parse_plist_file( \*FILE );

ok( $plist, "return value is not false" );
isa_ok( $plist,"${suborned}::dict" );
is( $plist->type, 'dict', 'type key has right value for nested dict' );
test_plist( $plist );
}



########################################################################

{

my $plist = parse_plist_file( $File );

ok( $plist, "return value is not false" );
isa_ok( $plist,"${suborned}::dict" );
is( $plist->type, 'dict', 'type key has right value for nested dict' );
test_plist( $plist );
}



########################################################################

{
my $filename;
1 while ($filename = 1 + rand(100000) and -e $filename);

my $plist = parse_plist_file( $filename );

ok( !$plist, "return value is false for missing file" );
}



########################################################################

sub test_plist
	{
	my $plist = shift;
	
	my $value = eval { $plist->value->{NSColorPanelMode}->value };
	print STDERR $@ if $@;
	is( $value, 5, "NSColorPanelMode has the right value" );
	}
