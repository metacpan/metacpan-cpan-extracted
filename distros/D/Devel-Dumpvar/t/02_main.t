#!/usr/bin/perl

# Formal testing for Devel::Dumpvar

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 10;
use File::Spec::Functions qw{:ALL};
use Devel::Dumpvar ();

my $RE_MEMORY_HEX = qr/(?<=\()0x[0-9a-f]+(?=\))/i;

# Create a test for deep structure dumps, which ignores memory locations
sub dump_is {
	my $got = shift;
	my $expected = shift;

	# Remove any hex memory locations
	$got      =~ s/$RE_MEMORY_HEX/0x???????/go;
	$expected =~ s/$RE_MEMORY_HEX/0x???????/go;

	# Compare normally now
	is( $got, $expected, @_ ? shift : () );
}

# Create a dumper for testing
my $dump = Devel::Dumpvar->new( to => 'return' );
isa_ok( $dump, 'Devel::Dumpvar' );






#####################################################################
# Basic Tests

# Do the basic series of dumps
my @tests = (
	[],        "   empty array\n",
	[ 1 ],     "0  1\n",
	[ 'foo' ], "0  'foo'\n",
	);
while ( @tests ) {
	my $test = shift @tests;
	my $expected  = shift @tests;
	is( $dump->dump( @$test ), $expected, "Simple dump matches expected" );
}





#####################################################################
# Detailed Tests

# Basic nested arrays
dump_is( $dump->dump( [ [ [] ] ] ), <<'END_DUMP', 'Array in array in array works' );
0  ARRAY(0x8301124)
   0  ARRAY(0x82ed9e4)
      0  ARRAY(0x804c1b4)
           empty array
END_DUMP



# Dump a new dumper as a single class and hash test
dump_is( $dump->dump( Devel::Dumpvar->new( to => 'return' ) ), <<'END_DUMP', 'Dumping a dumper' );
0  Devel::Dumpvar=HASH(0x83b440c)
   to => 'return'
END_DUMP




# A basic REF dump checker
dump_is( $dump->dump( \\"foo" ), <<'END_DUMP', 'Testing REF and read-only scalar' );
0  REF(0x8300f98)
   -> SCALAR(0x8300fa4)
      -> 'foo'
END_DUMP



# A reasonably large, combination object
my $User = bless( {
	HideDescriptions => bless( do{\(my $o = 1)}, 'Foo::Data::Boolean' ),
	Passwd => bless( do{\(my $o = 'phlegm1!')}, 'Foo::Data::ShortString' ),
	Id => bless( do{\(my $o = '1')}, 'Foo::Data::Integer' ),
	_ID => '1',
	RealName => bless( do{\(my $o = 'Adam Kennedy')}, 'Foo::Data::LongString' ),
	OutputPath => bless( do{\(my $o = undef)}, 'Foo::Data::LongString' ),
	OutputURL => bless( do{\(my $o = undef)}, 'Foo::Data::LongString' ),
	Username => bless( do{\(my $o = 'adam')}, 'Foo::Data::ShortString' ),
	Created => bless( do{\(my $o = bless( [
		37, 32, 4, 19, 7, 103, 2, 230, 0, 1061231557, 1
		], 'Foo::Time' ))}, 'Foo::Data::DateTime' ),
	Email => bless( do{\(my $o = 'adam@ali.as')}, 'Foo::Data::LongString' ),
	Modified => bless( do{\(my $o = bless( [
		35, 42, 17, 18, 10, 103, 2, 321, 1, 1069137755, 1
		], 'Foo::Time' ))}, 'Foo::Data::DateTime' )
	}, 'Foo::Entity::User' );
dump_is( $dump->dump( $User ), <<'END_DUMP', "More complex dump worked" );
0  Foo::Entity::User=HASH(0x9e82358)
   Created => Foo::Data::DateTime=REF(0x9e8a0d4)
      -> Foo::Time=ARRAY(0x9ee62c4)
         0  37
         1  32
         2  4
         3  19
         4  7
         5  103
         6  2
         7  230
         8  0
         9  1061231557
         10  1
   Email => Foo::Data::LongString=SCALAR(0x9e8a098)
      -> 'adam@ali.as'
   HideDescriptions => Foo::Data::Boolean=SCALAR(0x9e8a0a4)
      -> 1
   Id => Foo::Data::Integer=SCALAR(0x88a52c4)
      -> 1
   Modified => Foo::Data::DateTime=REF(0x9e8c3b4)
      -> Foo::Time=ARRAY(0x9e8c408)
         0  35
         1  42
         2  17
         3  18
         4  10
         5  103
         6  2
         7  321
         8  1
         9  1069137755
         10  1
   OutputPath => Foo::Data::LongString=SCALAR(0x9e89ffc)
      -> undef
   OutputURL => Foo::Data::LongString=SCALAR(0x9e8a0b0)
      -> undef
   Passwd => Foo::Data::ShortString=SCALAR(0x9e8a008)
      -> 'phlegm1!'
   RealName => Foo::Data::LongString=SCALAR(0x9e89f60)
      -> 'Adam Kennedy'
   Username => Foo::Data::ShortString=SCALAR(0x9e89df8)
      -> 'adam'
   _ID => 1
END_DUMP



# Circular references
my $c = [ 'foo', 'bar' ];
my $d = { 'a' => 1, 'b' => 'c' };
$c->[2] = $d;
$d->{d} = $c;
dump_is( $dump->dump( $c ), <<'END_DUMP', 'Circular references work' );
0  ARRAY(0x82ed9cc)
   0  'foo'
   1  'bar'
   2  HASH(0x804c1b4)
      a => 1
      b => 'c'
      d => ARRAY(0x82ed9cc)
         -> REUSED_ADDRESS
END_DUMP
dump_is( $dump->dump( $d ), <<'END_DUMP', 'Circular references work' );
0  HASH(0x804c1b4)
   a => 1
   b => 'c'
   d => ARRAY(0x82ed9cc)
      0  'foo'
      1  'bar'
      2  HASH(0x804c1b4)
         -> REUSED_ADDRESS
END_DUMP
