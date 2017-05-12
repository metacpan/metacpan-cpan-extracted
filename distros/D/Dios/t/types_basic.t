use strict;
use warnings;

use Test::More;
use Dios::Types 'validate' => 'type_check';

sub type_okay {
    my ($value, $type) = @_;

    my $result = eval { type_check($type, $value) };
    ok $result => Dios::Types::_perl($value)." --> $type";
    diag "         ...Diagnostic was: " . $result->msg
        if ref($result) && !$result;
}

sub type_fail {
    my ($value, $type) = @_;

    my $result = eval { type_check($type, $value, 'the test value ('.Dios::Types::_perl($value).')') };
    chomp( my $error = $@ );
    ok !$result => Dios::Types::_perl($value)." -/-> $type";
    like $error, qr{The test value (.*) is not of type \Q$type\E}s, "...Exception was correct" if $error;
}

my $var = 123;
type_okay( \$var         , 'Scalar'      );
type_okay( []            , 'Array'       );
type_okay( []            , 'Array[Str]'  );
type_okay( ['foo']       , 'Array[Str]'  );
type_okay( +{}           , 'Hash'        );
type_okay( sub {0}       , 'Code'        );
type_okay( \*STDOUT      , 'Glob'        );
type_okay( \*STDOUT      , 'IO'          );
type_okay( \(\"Hello")   , 'Ref'         );
type_okay( qr{x}         , 'Regex'       );
type_okay( 1             , 'Str'         );
type_okay( 1             , 'Num'         );
type_okay( 1             , 'Int'         );
type_okay( 1             , 'Def'         );
type_okay( 1             , 'Value'       );
type_okay( undef         , 'Undef'       );
type_okay( undef         , 'Any'         );
type_okay( 'Dios::Types' , 'Class'       );
type_okay( undef         , 'Bool'        );
type_okay( ''            , 'Bool'        );
type_okay( 0             , 'Bool'        );
type_okay( 1             , 'Bool'        );
type_okay( 7             , 'Bool'        );
type_okay( \"Hello"      , 'Ref[Scalar]' );
type_okay( \(\"Hello")   , 'Ref[Ref[Scalar]]' );
type_fail( []            , 'Str'         );
type_fail( []            , 'Num'         );
type_fail( []            , 'Int'         );
type_okay( "4x4"         , 'Str'         );
type_fail( "4x4"         , 'Num'         );
type_fail( "4.2"         , 'Int'         );
type_fail( undef         , 'Str'         );
type_fail( undef         , 'Num'         );
type_fail( undef         , 'Int'         );
type_fail( undef         , 'Def'         );
type_okay( undef         , 'Undef'       );
type_okay( ""            , 'Empty'       );
type_okay( []            , 'Empty'       );
type_okay( {}            , 'Empty'       );
type_fail( \[]           , 'Empty'       );
type_fail( \{}           , 'Empty'       );
type_fail( \""           , 'Empty'       );
type_fail( 1             , 'Empty'       );
type_fail( "a"           , 'Empty'       );
type_fail( [1]           , 'Empty'       );
type_fail( {a=>1}        , 'Empty'       );

{
        package Local::Class1;
        use strict;
}

{
        no warnings 'once';
        $Local::Class2::VERSION = 0.001;
        @Local::Class3::ISA     = qw(UNIVERSAL);
        @Local::Dummy1::FOO     = qw(UNIVERSAL);
}

{
        package Local::Class4;
        sub XYZ () { 1 }
}

type_fail( undef            , 'Class'             );
type_fail( []               , 'Class'             );
type_okay( "Local::Class$_" , 'Class'             ) for 2..4;
type_fail( "Local::Dummy1"  , 'Class'             );
type_okay( []               , 'Array[Int]'        );
type_okay( [1,2,3]          , 'Array[Int]'        );
type_fail( [1.1, 2,3]       , 'Array[Int]'        );
type_fail( [1,2,3.1]        , 'Array[Int]'        );
type_fail( [[]]             , 'Array[Int]'        );
type_okay( [[3]]            , 'Array[Array[Int]]' );
type_fail( [["A"]]          , 'Array[Array[Int]]' );

my $deep = 'Array[Hash[Array[Hash[Int]]]]';

type_okay( [{foo1=>[{bar=>1}]},{foo2=>[{baz=>2}]}], $deep );
type_okay( [{foo1=>[{bar=>1}]},{foo2=>[]}],         $deep );
type_fail( [{foo1=>[{bar=>1}]},{foo2=>[2]}],        $deep );

type_okay(  undef, 'Int|Undef');
type_okay(  123,   'Int|Undef');
type_fail(  1.3,   'Int|Undef');

my $i = 1;
my $f = 1.1;
my $s = "Hello";
type_okay( \$s, 'Ref[Value]' );
type_okay( \$f, 'Ref[Value]' );
type_okay( \$i, 'Ref[Value]' );
type_okay( \$s, 'Ref[Str]' );
type_okay( \$f, 'Ref[Str]' );
type_okay( \$i, 'Ref[Str]' );
type_fail( \$s, 'Ref[Num]' );
type_okay( \$f, 'Ref[Num]' );
type_okay( \$i, 'Ref[Num]' );
type_fail( \$s, 'Ref[Int]' );
type_fail( \$f, 'Ref[Int]' );
type_okay( \$i, 'Ref[Int]' );

SKIP: {
        skip "requires Perl 5.8", 3 if $] < 5.008;

        type_okay( "Inf",  'Num');
        type_okay( "-Inf", 'Num');
        type_fail( "NaN",  'Num');

        type_okay( "Inf",  'Int');
        type_okay( "-Inf", 'Int');
        type_fail( "NaN",  'Int');
}

my @VALID_NUMS = qw(
      0      0e123        0e+123        0e-123
     +0     +0e123       +0e+123       +0e-123
     -0     -0e123       -0e+123       -0e-123

      0.12   0.12e123     0.12e+123     0.12e-123
     +0.12  +0.12e123    +0.12e+123    +0.12e-123
     -0.12  -0.12e123    -0.12e+123    -0.12e-123

      0.     0.e123       0.e+123       0.e-123
     +0.    +0.e123      +0.e+123      +0.e-123
     -0.    -0.e123      -0.e+123      -0.e-123

     .0     .0e123       .0e+123       .0e-123
    +.0    +.0e123      +.0e+123      +.0e-123
    -.0    -.0e123      -.0e+123      -.0e-123

     1234567890123456789012345678901234567890
    +1234567890123456789012345678901234567890
    -1234567890123456789012345678901234567890
);

for my $num (@VALID_NUMS) {
    type_okay( $num,      'Num' );
    type_fail( "a$num",   'Num' );
    type_fail( "${num}a", 'Num' );
}


done_testing;
