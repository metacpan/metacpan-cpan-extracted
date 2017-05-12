#
# test conversion of scalars: S-Lang to Perl
#
# many of these tests shouldn't be direct equality
# since it's floating point
#

use strict;

use Test::More tests => 37;

use Data::Dumper;

# check for approximately equal
# - for these operations an absolute tolerance is okay
#
use constant ABSTOL => 1.0e-10;
sub approx ($$$) {
    my ( $a, $b, $text ) = @_;
    my $delta = $a-$b;
    ok( abs($delta) < ABSTOL, "$text [delta=$delta]" );
}

## Tests

use Inline 'SLang';

my ( $ret1, $ret2, $ret3, @ret );

## Integers
$ret1 = scalari2();
is( $ret1, 2, 'scalar int returned 2' );

( $ret1, $ret2 ) = scalari35();
is( $ret1, 3, 'scalar int returned 3' );
is( $ret2, 5, 'scalar int returned 5' );

$ret1 = scalari35();
is( $ret1, 3, 'scalar int returned 3 & ignored 5' );

# tests if the stack has been cleared
$ret1 = scalari2();
is( $ret1, 2, 'scalar int returned 2 [stack okay]' );

scalari35();
$ret1 = 0;
$ret1 = scalari2();
is( $ret1, 2, 'scalar int returned 2 [stack okay]' );

## Reals
$ret1 = scalarr2_1();
approx( $ret1, 2.1, 'scalar real returned 2.1' );

( $ret1, $ret2 ) = scalarr3_25_4();
approx( $ret1, 3.2, 'scalar real returned 3.2' );
approx( $ret2, 5.4, 'scalar real returned 5.4' );

$ret1 = scalarr3_25_4();
approx( $ret1 , 3.2, 'scalar real returned 3.2 & ignored 5.4' );

# tests if the stack has been cleared
$ret1 = scalarr2_1();
approx( $ret1, 2.1, 'scalar real returned 2.1 [stack okay]' );

scalarr3_25_4();
$ret1 = 0;
$ret1 = scalarr2_1();
approx( $ret1, 2.1, 'scalar real returned 2.1 [stack okay]' );

## Complex numbers
#
# complex support is implemented using Math::Complex,
# which is distributed with Perl 
#
$ret1 = scalarc3_4();

isa_ok( $ret1, "Math::Complex" );
is( $ret1->Re, 3, '   and real = 3' );
is( $ret1->Im, 4, '   and imag = 4' );

$ret1 = scalarc3_m45();
ok( $ret1->Re == 3 && $ret1->Im == -4.5, '3-4.5i is returned okay' );

( $ret1, $ret2 ) = scalarca();

ok( $ret1->Re ==  2.5 && $ret1->Im == 0,   '2.5+0i is returned okay' );
ok( $ret2->Re ==  0   && $ret2->Im == 4.7, '0+4.7i is returned okay' );

## Strings
$ret1 = scalarstest();
is( $ret1, "this is a scalar test", 'scalar string okay' );

scalarstest();
$ret1 = scalari2();
is( $ret1, 2, 'scalar string [stack only]' );

## Datatype objects

@ret = get_dtypes();
print Dumper($ret[0]), "\n";

is ( $#ret, 5, "num of datatypes is 6" );
isa_ok( $ret[0], "DataType_Type" );

# check them via stringification and via equality
is ( join( " ", map { "$_"; } @ret ),
  	"UChar_Type Short_Type Float_Type String_Type DataType_Type Null_Type",
	'DataType values are converted correctly' );

# test loading into main package somewhere in the 20's
my $sum = 0;
$sum += $ret[0] == Inline::SLang::UChar_Type();
$sum += $ret[1] eq Inline::SLang::Short_Type();
$sum += $ret[2] == Inline::SLang::Float_Type();
$sum += $ret[3] eq Inline::SLang::String_Type();
$sum += $ret[4] == Inline::SLang::DataType_Type();
$sum += $ret[5] eq Inline::SLang::Null_Type();
is ( $sum, 6, '  testing equality of data types' );
ok ( $ret[0] != $ret[1], '  and inequality of differnt types' );
ok ( $ret[0] ne $ret[2], '  and inequality of differnt types' );

## mixed types
# - mainly just to check out the stack-handling code

( $ret1, $ret2 ) = scalar_aa_45();
is( $ret1, "aa", 'mixed scalars okay' );
is( $ret2, 45, 'mixed scalars okay' );

@ret = scalar_aa_45();
is( $#ret, 1, 'num of mixed scalars == 2' );
is( $ret[0], "aa", 'mixed scalars okay' );
is( $ret[1], 45, 'mixed scalars okay' );

@ret = scalar_45_dtype_aa();
is( $#ret, 2, 'num of mixed scalars/datatypes == 3' );
is( $ret[0],   45,   'mixed scalars/datatypes okay' );
is( "$ret[1]", "DataType_Type",
    'mixed scalars/datatypes okay' );
is( $ret[2],   "aa", 'mixed scalars/datatypes okay' );


## Need to test the other types (many not yet supported)

$ret1 = retnull();
ok( !defined($ret1), 'NULL returned as undef' );

( $ret1, $ret2, $ret3 ) = retabc();
ok( defined($ret1) && defined($ret3) && !defined($ret2),
      "returning NULL's as undef doesn't mess up the stack" );

__END__

__SLang__

%% convert S-Lang to perl

% integers
define scalari2 () { return 2; }
define scalari35 () { return ( 3, 5 ); }

% reals
define scalarr2_1 () { return 2.1; }
define scalarr3_25_4 () { return ( 3.2, 5.4 ); }

% complex
define scalarc3_4 () { return 3 + 4i; }
define scalarc3_m45 () { return 3 - 4.5i; }
define scalarca () { return ( 2.5+0i, 0+4.7i ); }

% strings
define scalarstest() { return "this is a scalar test"; }

% datatypes
define get_dtypes () {
  return ( UChar_Type, Short_Type, Float_Type, String_Type, DataType_Type, Null_Type );
}

% mixed
define scalar_aa_45() { return ( "aa", 45 ); }

define scalar_45_dtype_aa() { return ( 45, DataType_Type, "aa" ); }

% NULL
define retnull() { return NULL; }
define retabc()  { return ( "a string", NULL, 22.4 ); }

