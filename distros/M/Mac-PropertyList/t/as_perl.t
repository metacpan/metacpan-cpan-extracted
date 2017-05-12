use strict;
use warnings;

use Test::More tests => 7;

use File::Spec::Functions;

my $class = 'Mac::PropertyList';
my @methods = qw( as_perl );

use_ok( $class );

my $test_file = catfile( qw( plists the_perl_review.abcdp ) );
ok( -e $test_file, "Test file for binary plist is there" );

{

my $plist = Mac::PropertyList::parse_plist_file( $test_file );
isa_ok( $plist, 'Mac::PropertyList::dict' );
can_ok( $plist, @methods );

my $perl = $plist->as_perl;
is(
	$perl->{ 'Organization' },
	'The Perl Review',
	'Organization returns the right value'
	);

is(
	$perl->{ 'Organization' },
	'The Perl Review',
	'Shallow access returns the right value'
	);

is(
	$perl->{'Address'}{'values'}[0]{'City'},
	'Chicago',
	'Deep access returns the right value'
	);
}

