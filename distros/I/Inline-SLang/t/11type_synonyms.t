# -*-perl-*-
#
# test type synonyms. We have two sorts:
#   a) those with a fixed size (eg Int16_Type)
#   b) those without (e.g. Short_Type)
#
# We do NOT test for the 64-bit integer types (Int64_Type/UInt64_Type)
#
use strict;

use Test::More tests => 34;

use Data::Dumper;

## Tests (we don't actually have any S-Lang code to test ;)

use Inline 'SLang' => Config => EXPORT => [ '!types', "sl_eval" ];
use Inline 'SLang' => " ";

my ( $ret1, $ret2, $ret3, @ret );

# simple checks
is(  Int_Type(),  Integer_Type(), "Int_Type == Integer_Type" );
is( UInt_Type(), UInteger_Type(), "UInt_Type == UInteger_Type" );

## Fixed types and then others (although the 'others' may not actually
## be synonyms depending on your machine/S-Lang)

foreach my $type
  (
   qw(
      Int16_Type UInt16_Type Int32_Type UInt32_Type Float32_Type Float64_Type
      Short_Type Long_Type
      )
   ) {
    $ret1 = undef;
    eval "\$ret1 = $type();";
    is( $@, "", "Called $type();" );
    ok( defined $ret1, " and it returned a value" );
    isa_ok( $ret1, "DataType_Type" );
    $ret2 = sl_eval( "$type;" );
    is( $ret2, $ret1, "  and the value matches S-Lang's expectations" );
}

## End
#
