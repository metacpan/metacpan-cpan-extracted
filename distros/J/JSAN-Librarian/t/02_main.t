#!/usr/bin/perl

# Compile testing for JSAN::Librarian

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 15;
use URI                   ();
use Config::Tiny          ();
use File::Remove          'remove';
use JSAN::Librarian       ();
use JavaScript::Librarian ();
use File::Spec::Functions ':ALL';

# Set paths
my $lib_path      = catdir(  't', 'data' );
my $default_index = catfile( 't', 'data', 'openjsan.deps' );

# Build the example copnfig to compare things to
my $expected = Config::Tiny->new;
$expected->{'Foo.js'} = {};
$expected->{'Bar.js'} = { 'Foo.js' => 1 };
$expected->{'Foo/Bar.js'} = { 'Foo.js' => 1, 'Bar.js' => 1 };





#####################################################################
# JSAN::Librarian Tests

# Check paths and remove as needed
ok( -d $lib_path, 'Lib directory exists' );
remove($default_index) if -e $default_index;
END {
	remove($default_index) if -e $default_index;
}

# Build first to check the scanning logic
my $new = JSAN::Librarian->new( $lib_path );
isa_ok( $new, 'JSAN::Librarian' );
my $config = $new->build_index( $lib_path );
isa_ok( $config, 'Config::Tiny' );
is_deeply(
	$config,
	$expected,
	'->build_index returns Config::Tiny that matches expected',
);

# Check that make_index writes as expected
ok( $new->make_index( $lib_path ), '->make_index returns true' );
ok( -e $default_index, '->make_index created index file' );
$config = Config::Tiny->read( $default_index );
isa_ok( $config, 'Config::Tiny' );
is_deeply( $config, $expected,
	'->make_index returns Config::Tiny that matches expected' );





#####################################################################
# JSAN::Librarian::Library Tests

# Create the Library
my $library = JSAN::Librarian::Library->new( $config );
isa_ok( $library, 'JSAN::Librarian::Library' );
ok( $library->load, 'Library loads ok' );

# Fetch a Book
my $book = $library->item('Foo.js');
isa_ok( $book, 'JSAN::Librarian::Book' );





#####################################################################
# Full test of JavaScript::Librarian

my $uri = URI->new( '/jsan' );
my $librarian = JavaScript::Librarian->new(
	base    => $uri,
	library => $library,
	);
isa_ok( $librarian, 'JavaScript::Librarian' );

# Generate script tags for something
ok( $librarian->add( 'Foo/Bar.js' ), '->add(Foo/Bar.js) returned true' );
my $script = $librarian->html;
ok( defined $script, '->html returns defined' );
is( $script . "\n", <<'END_HTML', '->html returns expected' );
<script language="JavaScript" src="/jsan/Foo.js" type="text/javascript"></script>
<script language="JavaScript" src="/jsan/Bar.js" type="text/javascript"></script>
<script language="JavaScript" src="/jsan/Foo/Bar.js" type="text/javascript"></script>
END_HTML
