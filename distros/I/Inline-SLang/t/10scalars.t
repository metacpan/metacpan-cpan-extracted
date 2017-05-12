# -*-perl-*-
#
# test scalars
# . from Perl to S-Lang and vice-versa
# . this is mainly testing the stack-handling since the 
#   tests of the individual datatypes are done in
#   01scalars2perl.t and 01scalars2slang.t
# . also tests references (since need to test both conversions
#   at once [or at least it makes things easier]
#
# Really this should be run after the individual scalar
# tests (ie 01scalars2*.t) since the tests assume that
# the basic conversions work
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

## variable args

$ret1 = nvarargs();
is( $ret1, 0, "varargs: 0 supplied" );

$ret1 = nvarargs( "a", 2, 3.0 );
is( $ret1, 3, "varargs: 3 supplied" );

@ret = nvarargs( -5, -6 );
is( $#ret, 0, "varargs: 2 supplied" );
is( $ret[0], 2, "varargs: 2 supplied" );

$ret1 = sumup( 2, 3.4 );
approx( $ret1, 5.4, "varargs: sumup=5.4" );

$ret1 = sumup( 2, 3.4, 90 );
approx( $ret1, 95.4, "varargs: sumup=95.4" );

$ret1 = sumup( 2, 3.4, -100, 90 );
approx( $ret1, -4.6, "varargs: sumup=-4.6" );

$ret1 = concatall( "a", " ", "b" );
is( $ret1, "a b", "a + ' ' + b = 'a b'" );

$ret1 = concatall( " ", "2 " );
is( $ret1, " 2 ", "' ' + '2 ' = ' 2 '" );

# References
# - note: checking both 2 perl and 2 slang
#
my %_hacked = ( "normal" => -23.2, "static" => 4, "private" => undef );
foreach my $linkage ( qw( normal static private ) ) {
  $ret1 = retref($linkage);
  isa_ok( $ret1, "Inline::SLang::_Type" );
  isa_ok( $ret1, "Ref_Type" );
  is( unref($ret1), "a $linkage string", "  can deref $linkage linkage" );
  hackref($linkage);
  is( unref($ret1), $_hacked{$linkage}, "  and can change" );
}

# stack tests
$ret1 = undef;
( $ret1, $ret2, $ret3 ) = retref_multi();
print "Stack test: ret1=[$ret1] ret2=[$ret2] ret3=[$ret3]\n";
ok( $ret1 == 12 && $ret3 eq "foo bar",
  "Ref_Type handling okay with the stack" );
isa_ok( $ret2, "Ref_Type" );
is( unref($ret2), $_hacked{"normal"}, "  de-reffed correctly" );

# anytype tests
#
foreach my $i ( 0, 1, 2 ) {
  $ret1 = getanytype5($i);
  isa_ok( $ret1, "Inline::SLang::_Type" );
  isa_ok( $ret1, "Any_Type" );
  is( "$ret1", "Any_Type", "  Any_Type stringifies correctly" );
  is( $ret1->is_struct_type, 0, "  and isn't a structure" );
}
$ret1 = getanytype5(3);
ok( !defined $ret1, "a Null_Type [in Any_Type] has been converted to undef" );

__END__
__SLang__

%% check the stack (variable args)

% if we don't clear the stack via _pop_n() we really mess up
define nvarargs () {
  variable n = _NARGS;
  () = printf( "varargs was sent %d arguments\n", n );
%%  _print_stack();
  _pop_n(n);
  return n;
}

define sumup () {
  variable sum = 0.0;
  foreach ( __pop_args(_NARGS) ) {
    variable arg = ();
    sum += arg.value;
  }
  return sum;
}

define concatall () {
  variable str = "";
  foreach ( __pop_args(_NARGS) ) {
    variable arg = ();
    str += arg.value;
  }
  return str;
}

% references
variable _a_normal_string          = "a normal string";
static  variable _a_static_string  = "a static string";
private variable _a_private_string = "a private string";
define retref(id) {
  switch (id)
  { case "normal":  return &_a_normal_string; }
  { case "static":  return &_a_static_string; }
  { case "private": return &_a_private_string; }
  { verror("Test error: retref sent '%s'\n", id ); }
}
define hackref(id) {
  switch (id)
  { case "normal":  _a_normal_string = -23.2; }
  { case "static":  _a_static_string = 4; }
  { case "private": _a_private_string = NULL; }
  { verror("Test error: hackref sent '%s'\n", id ); }
}
define unref(x) { return @x; }

define retref_multi() { return ( 12, &_a_normal_string, "foo bar" ); }

%% AnyType tests
variable _anytype5 = Any_Type [5];
_anytype5[0] = 1;
_anytype5[1] = "a string";
_anytype5[2] = &_anytype5;

define getanytype5(i) { return _anytype5[i]; }

