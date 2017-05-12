# -*-perl-*-
#
# test exporting functions - note the coverage of the
# tests is rather poor at the moment. Some of these
# are implicitly tested in later tests (in the 1* series)
#

use strict;

use Test::More tests => 11;

## Tests

use Inline 'SLang' => Config =>
  EXPORT => [ qw( sl_array sl_eval sl_typeof !types ) ];
use Inline 'SLang' => <<'EOS1';

typedef struct { agh, bob } Foo_Struct;

% currently have to define a function; should perhaps drop this?
define dummy() { }

EOS1

# part test we can call the functions, part test of
# their functionality
#
my $ret1 = Inline::SLang::Assoc_Type();
isa_ok( $ret1, "DataType_Type" );
is( "$ret1", "Assoc_Type", "Repeated data type tests" );

$ret1 = Assoc_Type();
isa_ok( $ret1, "DataType_Type" );
is( "$ret1", "Assoc_Type", "Repeated data type tests" );

is( "".Assoc_Type()->typeof, "DataType_Type", "Repeated data type tests" );

is( sl_eval("typeof(23.4);"), Double_Type(), "sl_eval test" );

is( "" . Inline::SLang::sl_typeof( Assoc_Type() ), "DataType_Type",
    "sl_typeof test" );
is( "" . sl_typeof( Assoc_Type() ), "DataType_Type",
    "sl_typeof test [repeat]" );

is( sl_typeof(23),     Integer_Type(), "sl_typeof(23) test" );
is( sl_typeof(23.0),   Double_Type(), "sl_typeof(23.0) test" );
is( sl_typeof("23.0"), String_Type(), "sl_typeof(\"23.0\") test" );


## End

