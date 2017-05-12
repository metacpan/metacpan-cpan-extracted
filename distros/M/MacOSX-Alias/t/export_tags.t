#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 7;

my $class = 'MacOSX::Alias';

require_ok( $class );

foreach my $function ( qw(read_alias make_alias) )
	{
	can_ok( $class, $function );
	no strict 'refs';
	ok( ! defined &{$function}, "main::${function} not defined yet (good)" );
	}
	
$class->import( ':all' );
foreach my $function ( qw(read_alias make_alias) )
	{
	ok( defined &{$function}, "main::${function} now defined (good)" );
	}