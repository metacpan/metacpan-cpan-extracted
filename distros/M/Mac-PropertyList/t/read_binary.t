use strict;
use warnings;
use utf8;

use Test::More tests => 41;

use File::Spec::Functions;

my $class = 'Mac::PropertyList::ReadBinary';
my @methods = qw( new plist );

use_ok( $class );
can_ok( $class, @methods );

my $test_file = catfile( qw( plists the_perl_review.abcdp ) );
ok( -e $test_file, "Test file for binary plist is there" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Use it directly
{
my $parser = $class->new( $test_file );
isa_ok( $parser, $class );

my $plist = $parser->plist;
isa_ok( $plist, 'Mac::PropertyList::dict' );

my %keys_hash = map { $_, 1 } $plist->keys;

foreach my $key ( qw(UID URLs Address Organization) )
	{
	ok( exists $keys_hash{$key}, "$key exists" );
	}

is(
	$plist->value( 'Organization' ),
	'The Perl Review',
	'Organization returns the right value'
	);

isa_ok( $plist->{'Creation'}, 'Mac::PropertyList::date' );
is( $plist->{'Creation'}->value, '2007-11-14T02:19:03Z', 'Creation date has the right value' );

is_deeply(
	$plist->{'Phone'}->as_perl,
	{
		'identifiers' => [
                    'DCBE4C18-EC2E-457F-A594-99A10257AB37',
                    'CBE21CFF-0EF2-4975-98E6-84FCA75202BA'
                ],
                'labels' => [
                    '_$!<Mobile>!$_',
                    '_$!<WorkFAX>!$_'
                ],
                'primary' => 'DCBE4C18-EC2E-457F-A594-99A10257AB37',
                'values' => [
                    '(312) 492-4632',
                    '866 750-7099'
                ]
        },
	'nested arrays and dicts return the right value'
	);

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Use it indirectly
{
use Mac::PropertyList qw(parse_plist_file);

my $plist = parse_plist_file( $test_file );
isa_ok( $plist, 'Mac::PropertyList::dict' );

my %keys_hash = map { $_, 1 } $plist->keys;

foreach my $key ( qw(UID URLs Address Organization) )
	{
	ok( exists $keys_hash{$key}, "$key exists" );
	}

is(
	$plist->value( 'Organization' ),
	'The Perl Review',
	'Organization returns the right value'
	);

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with real and data
{
use Mac::PropertyList qw(parse_plist_file);
my $test_file = catfile( qw( plists binary.plist ) );
my $plist = parse_plist_file( $test_file );
isa_ok( $plist, 'Mac::PropertyList::dict' );

is(
	$plist->value( 'PositiveInteger' ),
	'135',
	'PositiveInteger returns the right value'
	);

is(
	$plist->value( 'NegativeInteger' ),
	'-246',
	'NegativeInteger returns the right value'
	);

my $π = $plist->value( 'Pi' );
my $Δ = abs( 3.14159 - $π ); # possible floating point error
my $ε = 1e-4;

ok(
	$Δ < $ε,
	'π returns the right value, within ε'
	);

isa_ok( $plist->{'Data'}, 'Mac::PropertyList::data' );
is( $plist->value( 'Data' ), "\x01\x50\x01\x15", "Data returns the right value" );

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with various width integers, booleans, unusual strings
{
my $test_file_2 = catfile( qw( plists binary2.plist ) );
my $plist = parse_plist_file( $test_file_2 );

isa_ok( $plist, 'Mac::PropertyList::array' );
my(@values) = $plist->value;
is( scalar @values, 8, 'right number of elements in array' );

my(@types) = qw( integer integer integer true false string ustring ustring );
my(@expect) = ( 1280, 2752512, 2147483649, 1, 0,
                'Entities: & and &amp;',
                'Unicode: π≠2 Entities: & and &amp;',
                "Unicode Supplementary: \x{1203C}, \x{1F06B}." );

# The characters in the Supplementary string are CUNEIFORM SIGN ASH
# OVER ASH OVER ASH and DOMINO TILE VERICAL 1 1.  They were entered
# in utf8 into an xml plist, then converted to bplist format by plutil
# on MacOSX10.6.8.

for my $index (0 .. 7) {
    isa_ok( $values[$index], 'Mac::PropertyList::' . $types[$index] );
    is( scalar $values[$index]->value, $expect[$index],
        "$types[$index] at index $index has right value" )
        unless ( $index == 3 || $index == 4 );
}

}
