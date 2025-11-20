#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Dump::Krumo;

$Dump::Krumo::return_string = 1;
$Dump::Krumo::use_color     = 0;

is(kx(undef)      , 'undef'          );
is(kx(1.5)        , '1.5'            );
is(kx("a\nb")     , '"a\nb"'         );
is(kx(\*STDOUT)   , '\*main::STDOUT' );
is(kx("Doolis")   , "'Doolis'"       );
is(kx(12345)      , "12345"          );
is(kx("")         , "''"             );
is(kx("a'b")      , "\"a'b\""        );
is(kx(0)          , "0"              );
is(kx('0')        , "0"              );
is(kx("1\x{0}2")  , '"1\x{00}2"'     ); # Null byte in the middle of a string

# Regexps
is(kx(qr((foo)?(bar))), 'qr(?^:(foo)?(bar))' );
is(kx(qr(^(foo)))     , 'qr(?^:^(foo))'      );
is(kx(qr(foo$))       , 'qr(?^:foo$)'        );

# Array references
is(kx([1,2,3])       , '[1, 2, 3]'     );
is(kx(["one","two"]) , "['one', 'two']");
is(kx( [ '' ] )      , "['']"          );
is(kx( [ 0 ] )       , "[0]"           );
is(kx( [ \0 ] )      , "[\\'0']"       ); # Scalar ref
is(kx( [ undef ] )   , "[undef]"       );

# Booleans
is(kx(!!1) , 'true' );
is(kx(!!0) , 'false');

# Raw array
is(kx(1,2,3)        , '(1, 2, 3)');
is(kx("cat", "dog") , "('cat', 'dog')");

# This is really an error???
is(kx() , "()");

# Empty hash/array
is(kx( [ ] ) , '[]');
is(kx( { } ) , '{}');

# Scalar ref
my $str = "foobar";
is(kx(\$str)    , "\\'foobar'");
is(kx(\"scott") , "\\'scott'");

# Hashes
is(kx("{a => 1, b=>2}") , '"{a => 1, b=>2}"');
is(kx("{one => 1}")     , '"{one => 1}"');
is(kx("{'a b' => 1}")   , '"{\'a b\' => 1}"');
is(kx("{'a\"b' => 1}")  , '"{\'a"b\' => 1}"');

# Code reference
is(kx(\&done_testing) , 'sub { ... }');

done_testing();
