#
# test in/out of structures
#
# Note that the get_struct_field_names/get_struct/set_struct
# methods are not explicitly tested here since they're implicitly
# tested when we convert a struct from Perl to S-Lang
#

use strict;

use Test::More tests => 71;

use Inline 'SLang' => Config => EXPORT => [ '!types' ];
use Inline 'SLang';

use Data::Dumper;

# check for approximately equal
# - for these operations an absolute tolerance is okay
#
# really want to be able to test arrays easily
#
use constant ABSTOL => 1.0e-10;
sub approx ($$$) {
    my ( $a, $b, $text ) = @_;
    my $delta = $a-$b;
    ok( abs($delta) < ABSTOL, "$text [delta=$delta]" );
}

## Tests

# for most of the tests we want arrays converted as array references
Inline::SLang::sl_array2perl(0);

my ( $ret1, $ret2, $ret3, @ret );

## 

## S-Lang 2 perl

$ret1 = struct1();

# Note: the dump method is not for public consumption (yet ?)
#
##print Dumper( $ret1 ), "\n";
print Dumper( tied(%$ret1) ), "\n";
print "And using the dump method:\n";
print $ret1->dump, "\n";

isa_ok( $ret1, "Struct_Type" );
isa_ok( $ret1, "Inline::SLang::_Type" );
ok( $ret1->is_struct_type, "and we are a structure" );

ok( eq_array( [ keys %$ret1 ],
	      [ "f1", "f2", "f4", "f3" ] ),
    "  contains the correct fields (in the right order)" );
is( $$ret1{f1},    1, "    f1 == 1" );
is( $$ret1{f2}, "f2", "    f2 == 'f2'" );
ok( eq_array( $$ret1{f4}, [1,2,3]),
    "    f4 == [1,2,3]" );
is( $$ret1{f3}, undef, "    f3 == undef" );

$$ret1{f1} = 2;
is( $$ret1{f1}, 2, "changed f1 to 2" );

@$ret1{qw(f2 f3) } = ( -1, -2.1 );
ok( eq_array( [@$ret1{qw(f2 f3)}], [-1,-2.1] ),
    "changed f2 to -1 & f3 to -2.1" );

# stringification is now an easy test
$ret1 = struct2();
is( "$ret1", "Struct_Type", "The stringification works" );
is( $ret1->typeof, Struct_Type(),   "as does the type checking" );

# check we play nicely with the stack
( $ret1, $ret2, $ret3 ) = ret_multi();
ok( $ret1 eq "more strings" && $ret3 eq -234.5,
  "multi return: non-struct vals okay" );
isa_ok( $ret2, "Struct_Type" );
ok( exists $$ret2{gonzo} && !defined($$ret2{gonzo}),
  "and structure field is NULL/undef" );

# test type-deffed structures
$ret1 = retbar();
isa_ok( $ret1, "Inline::SLang::_Type" );
isa_ok( $ret1, "Struct_Type" );
isa_ok( $ret1, "Bar_Type" );
is( $ret1->typeof, Bar_Type(), "checking type matches" );
is( $ret1->is_struct_type, 1, "typedef {}... returns a structure" );

print "And using the dump method, the type-deffed structure returns:\n";
print $ret1->dump, "\n";

ok( eq_array( [keys %$ret1], [ "foo", "bar" ] ),
    "  and contains the correct fields (in the right order)" );
is( $$ret1{foo},     2, "    foo == 2" );
is( $$ret1{bar}, "baz", "    bar == 'baz'" );
is( "$ret1", "Bar_Type", "  and the stringification works" );

## Perl objects

# have removed tests of the tie intreface since the user should
# never see this and it is implicitly tested by everything else here
#
# the object constructor
#
$ret1 = Struct_Type->new( ['a','x','a_space'] );
##print Dumper( $ret1 ), "\n";
isa_ok( $ret1, "Struct_Type" );
isa_ok( $ret1, "Inline::SLang::_Type" );
is( $ret1->typeof, Struct_Type(), "and type is okay" );
ok( $ret1->is_struct_type, "and we are a structure" );

ok( eq_array( [keys %$ret1], [ "a", "x", "a_space" ] ),
    "  and contains the correct fields (in the right order)" );

# - note leave 'a_space' as undef
my $label = "  able to set fields in created structure";
@$ret1{qw( x a )} = ( 'a string', [1,2,4] );
is( $$ret1{x}, "a string", $label );
is( $$ret1{a_space}, undef, $label );
ok( eq_array( $$ret1{a}, [1,2,4] ), $label );

# now, can we convert it to a S-Lang Struct_Type?
is( is_a_struct($ret1), 1,
    "Can convert Perl Struct_Type to S-Lang Struct_Type" );
is( check_struct_fields($ret1,"a","x","a_space"), 1,
	"  and the field names/order are correct" );
is( check_struct_valuesa($ret1), 1,
	"  and the field values are okay" );

# check we don't mess up the stack
ok( send3a("a string",$ret1,Float_Type()),
   "Inline::SLang::Struct_Type 2 S-Lang plays okay w/ stack" );

# how about some illegal operations
#
# looks like delete doesn't even want to work on this object anyway

eval 'delete $$ret1{"x"};';
like( $@, qr/^Error: unable to delete a field from a Struct_Type structure/,
	"can not delete the 'x' field [get an error]" );
ok( eq_array( [keys %$ret1], [ "a", "x", "a_space" ] ),
    "can not delete the 'x' field [it still exists]" );

eval '$$ret1{"foobar"};';
like( $@, qr/^Error: field 'foobar' does not exist in this Struct_Type structure/, 
	"can not add a field [get an error]" );
eval '$$ret1{"foobar"} = 23;';
like( $@, qr/^Error: field 'foobar' does not exist in this Struct_Type structure/, 
	"can not add a field [get an error]" );
ok( eq_array( [keys %$ret1], [ "a", "x", "a_space" ] ),
    "  and it hasn't been added to the hash keys" );

# test type-deffed structures

$ret1 = Bar_Type->new();
isa_ok( $ret1, "Inline::SLang::_Type" );
isa_ok( $ret1, "Struct_Type" );
isa_ok( $ret1, "Bar_Type" );
is( $ret1->typeof, Bar_Type(), "  type agrees" );
is( $ret1->is_struct_type, 1, "typedef {}... returns a structure" );

$label = "  able to set fields in type-deffed structure";
@$ret1{qw( bar foo ) } = ( 3, "bar" );
is( $$ret1{foo}, "bar", $label );
is( $$ret1{bar}, 3, $label );

ok( check_bar($ret1), "  and can convert to S-Lang" );

is( check_struct_valuesb($ret1), 1,
	"  and the field values are okay" );

# check we don't mess up the stack
ok( send3b("a string",$ret1,Float_Type()),
   "Bar_Type 2 S-Lang plays okay w/ stack" );

# test some more features of the tied hash interface:
#   each [note that we have implicitly tested keys above
#     so it's probably a wasted check; also with only
#     2 items we're not really stressing things!]
#
my @names;
my @values;
while ( my ( $key, $value ) = each %$ret1 ) {
  push @names, $key;
  push @values, $value;
  $$ret1{$key} = $#names;
}
ok( eq_array( \@names,  ["foo", "bar"] ), "each returned fields in order" );
ok( eq_array( \@values, ["bar", 3] ), "  and correct values" );
ok( eq_array( [@$ret1{qw(bar foo)}], [1,0] ), "  and could change values" );

# create a structure contaiing a structure: "stress" test the
# conversion code
#
$ret1 = Struct_Type->new( [ "goo", "x3", "_bob" ] );
$$ret1{goo}    = Struct_Type->new( [ "a1", "x1", "q1" ] );
$$ret1{"x3"}   = Bar_Type->new();
$$ret1{"_bob"} = Struct_Type->new( [ "a1", "x1", "q1" ] );

$$ret1{goo}{a1} = "a a1";
$$ret1{goo}{x1} = "a x1";
$$ret1{goo}{q1} = "a q1";
$$ret1{"x3"}->set_field( "foo", 23 );
$$ret1{"x3"}{bar} = 47.3;
$$ret1{"_bob"}{a1} = 0;
$$ret1{"_bob"}{x1} = DataType_Type();
$$ret1{"_bob"}{q1} = Math::Complex->make(-4,2);

print "And using the dump method, the 'deep-nested' struct is:\n";
print $ret1->dump, "\n";

$ret2 = Bar_Type->new();
$ret3 = Bar_Type->new();
$$ret2{foo} = 1;
$$ret2{bar} = 3;
$$ret3{foo} = "xfpp";
$$ret3{bar} = [ [2], [4], [3] ];

ok ( check_silly_obj($ret2,$ret1,$ret3),
     "Looks like stack isn't messed up [Perl to S-Lang]" );

# and see if can convert to S-Lang and then back into 
my ( $a, $b, $c ) = ret_silly_obj( $ret2, $ret1, $ret3 );

$label = "Checking Perl>S-Lang>Perl: ";
ok(
   UNIVERSAL::isa($a,"Bar_Type") &&
   UNIVERSAL::isa($b,"Struct_Type") &&
   UNIVERSAL::isa($c,"Bar_Type"),
   $label . "correct objs returned" );
ok( $$a{foo} == 1 && $$a{bar} == 3, $label . "Bar_Type[2] contents okay" );
ok( $$c{foo} eq "xfpp" && eq_array( $$c{bar}, [ [2], [4], [3] ] ),
	$label . "Bar_Type[3] contents okay" );
ok( eq_array( [keys %$b], ["goo","x3","_bob"] ),
    $label . "Struct_Type[1] has correct keys" );
ok(
   UNIVERSAL::isa($$b{goo}, "Struct_Type") &&
   UNIVERSAL::isa($$b{x3},  "Bar_Type") &&
   UNIVERSAL::isa($$b{_bob},"Struct_Type"),
   $label . "Struct_Type[1] values are structs" );
ok( eq_array( [@{ $$b{goo} }{qw(a1 x1 q1)}], ["a a1","a x1","a q1"] ),
    $label . "Struct_Type[1] field=goo values okay" );
ok( eq_array( [@{ $$b{x3} }{qw(foo bar)}], [23,47.3] ),
    $label . "Struct_Type[1] field=x3 values okay" );
ok(
   $$b{_bob}{a1} == 0 &&
   UNIVERSAL::isa($$b{_bob}{x1},"DataType_Type") &&
   $$b{_bob}{x1} eq DataType_Type() &&
   UNIVERSAL::isa($$b{_bob}{q1},"Math::Complex") &&
   $$b{_bob}{q1}->Re == -4 &&
   $$b{_bob}{q1}->Im == 2,
   $label . "Struct_Type[1] field=_bob values okay" );

# test the silly object above with a different array mapping
#
# note there's only 1 array in it but we check everything
# (to ensure there's no hidden surprises in the conversion
#  code)
#
Inline::SLang::sl_array2perl(1);

$a = $b = $c = undef;
( $a, $b, $c ) = ret_silly_obj( $ret2, $ret1, $ret3 );

$label = "Checking Perl>S-Lang>Perl [arrays -> Array_Type]: ";
ok(
   UNIVERSAL::isa($a,"Bar_Type") &&
   UNIVERSAL::isa($b,"Struct_Type") &&
   UNIVERSAL::isa($c,"Bar_Type"),
   $label . "correct objs returned" );
ok( $$a{foo} == 1 && $$a{bar} == 3, $label . "Bar_Type[2] contents okay" );
ok( $$c{foo} eq "xfpp" &&
    UNIVERSAL::isa( $$c{bar}, "Array_Type" ) &&
    eq_array( $$c{bar}->toPerl, [ [2], [4], [3] ] ),
	$label . "Bar_Type[3] contents okay" );
ok( eq_array( [keys %$b], ["goo","x3","_bob"] ),
    $label . "Struct_Type[1] has correct keys" );
ok(
   UNIVERSAL::isa($$b{goo}, "Struct_Type") &&
   UNIVERSAL::isa($$b{x3},  "Bar_Type") &&
   UNIVERSAL::isa($$b{_bob},"Struct_Type"),
   $label . "Struct_Type[1] values are structs" );
ok( eq_array( [@{ $$b{goo} }{qw(a1 x1 q1)}], ["a a1","a x1","a q1"] ),
    $label . "Struct_Type[1] field=goo values okay" );
ok( eq_array( [@{ $$b{x3} }{qw(foo bar)}], [23,47.3] ),
    $label . "Struct_Type[1] field=x3 values okay" );
ok(
   $$b{_bob}{a1} == 0 &&
   UNIVERSAL::isa($$b{_bob}{x1},"DataType_Type") &&
   $$b{_bob}{x1} eq DataType_Type() &&
   UNIVERSAL::isa($$b{_bob}{q1},"Math::Complex") &&
   $$b{_bob}{q1}->Re == -4 &&
   $$b{_bob}{q1}->Im == 2,
   $label . "Struct_Type[1] field=_bob values okay" );


__END__
__SLang__

%
% As of version 0.26 of Inline::SLang we guarantee that
% sum is part of the S-Lang tun-time library
%
define all(x) { return sum(typecast(x,Int_Type)!=0) == length(x); }
define any(x) { return sum(typecast(x,Int_Type)!=0) != 0; }

%%define dbg(x) { vmessage(">>> [%s]", x); }
define dbg(x) { }

define struct1 () {
  variable a = struct { f1, f2, f4, f3 };
  a.f1 = 1.0;
  a.f2 = "f2";
  a.f4 = [1,2,3];
  a.f3 = NULL;
  return a;
}

define struct2 () {
  variable a = struct { x1, y2 };
  a.x1 = "a string";
  a.y2 = "another string";
  return a;
}

% also see how we handle NULL value types
define ret_multi () {
  return "more strings", struct { gonzo }, -234.5;
}

% test
typedef struct { foo, bar } Bar_Type;

define retbar() {
  variable bar = @Bar_Type;
  bar.foo = 2;
  bar.bar = "baz";
  return bar;
} % retbar()

%% Perl 2 S-Lang

define is_a_struct (x) { return is_struct_type(x); } 

define check_struct_fields () {
  %%_print_stack();
  if ( _NARGS < 2 )
    verror( "Usage: Int_Type = %s(Struct_Type,String_Type,...);\n", _function_name );

  % grab the variables from the stack
  variable fields = __pop_args( _NARGS-1 );
  variable s = ();

  variable names = get_struct_field_names(s);
  if ( length(names)  != length(fields) ) return 0;

  % want names and fields to be equal
  _for ( 0, length(names)-1, 1 ) {
    variable i = ();
    if ( names[i] != fields[i].value ) return 0;
  }
  return 1;
} % check_struct_fields

define check_struct_valuesa (x) {
  return x.x == "a string" and x.a_space == NULL and all(x.a == [1,2,4]);
}

define check_struct_valuesb (x) {
  return x.foo == "bar" and x.bar == 3;
}

define send3a (x,y,z) {
  if ( andelse
       { x == "a string" }
       { is_struct_type(y) }
       { check_struct_fields(y,"a","x","a_space") }
       { check_struct_valuesa(y) }
       { z == Float_Type } )
    return 1;
  else
    return 0;
}

define send3b (x,y,z) {
  if ( andelse
       { x == "a string" }
       { is_struct_type(y) }
       { check_struct_fields(y,"foo","bar") }
       { check_struct_valuesb(y) }
       { z == Float_Type } )
    return 1;
  else
    return 0;
}

define check_bar(in) {
  if (
    andelse
    { typeof(in) == Bar_Type }
    { in.foo == "bar" }
    { in.bar == 3 } )
    return 1;
  else
    return 0;
} % check_bar()

define check_silly_obj (x,y,z) {

  if ( orelse
       { typeof(x) != Bar_Type }
       { x.foo != 1 }
       { x.bar != 3 }
     ) return 0;
  variable aval = [ 2,4,3 ];
  reshape( aval, [3,1] );
  if ( orelse
       { typeof(z) != Bar_Type }
       { z.foo != "xfpp" }
       { typeof(z.bar) != Array_Type }
       { _typeof(z.bar) != Int_Type }
       { any( z.bar != aval ) }
     ) return 0;

  % break down the check of y into pieces
  if ( orelse
       { typeof(y) != Struct_Type }
       { any( get_struct_field_names(y) != ["goo","x3","_bob"] ) }
     ) return 0;
  if ( orelse
       { typeof(y.goo)  != Struct_Type }
       { typeof(y.x3)   != Bar_Type }
       { typeof(y._bob) != Struct_Type } ) return 0;

  if ( orelse
       { any( get_struct_field_names(y.goo) != ["a1","x1","q1"] ) }
       { y.goo.a1 != "a a1" } { y.goo.x1 != "a x1" } { y.goo.q1 != "a q1" }
     ) return 0;
  if ( orelse
       { y.x3.foo != 23 } { y.x3.bar != 47.3 }
     ) return 0;
  if ( orelse
       { any( get_struct_field_names(y._bob) != ["a1","x1","q1"] ) }
       { y._bob.a1 != 0 } { y._bob.x1 != DataType_Type } { y._bob.q1 != -4+2i }
     ) return 0;

 return 1;
} % check_silly_obj

% checks conversion perl to S-Lang to perl is okay
define ret_silly_obj (x,y,z) { return x, y, z; }
