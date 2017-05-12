#!/usr/bin/perl

# Primary testing for File::Find::Rule::PPI

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use File::Find::Rule      ();
use File::Find::Rule::PPI ();

# Find perl files with whitespace in them
my $Rule = File::Find::Rule->file
	->name('*.pm')
	->ppi_find_any('Token::Whitespace')
	->relative;
isa_ok( $Rule, 'File::Find::Rule' );

# They all should
my @files = $Rule->in( catdir('t', 'data') );
@files = sort @files;
is_deeply( \@files, [ 'Bar.pm', 'Foo.pm', 'dir/Baz.pm' ],
	'Whitespace search returns expected file list' );

# Not find files with comments in them
$Rule = File::Find::Rule->file
	->name('*.pm')
	->ppi_find_any('Token::Comment')
	->relative;
isa_ok( $Rule, 'File::Find::Rule' );

# They all should
@files = $Rule->in( catdir('t', 'data') );
@files = sort @files;
is_deeply( \@files, [ 'Bar.pm', 'dir/Baz.pm' ],
	'Comment search returns expected file list' );
