use Test::More qw<no_plan>;
use strict;
use warnings;
use JavaScript::HashRef::Decode qw<decode_js>;

my $str;
my $res;
my $err;

# https://github.com/mfontani/JavaScript-HashRef-Decode/issues/1
$str = "{id:1,oops:,foo:'bar'}";
$res = eval { decode_js($str) };
$err = $@;
ok( $err, "Dies for invalid input" );
like( $err, qr/cannot parse/i, "User-friendly error message when unparsable" );
like( $err, qr/\Q$str/i,       "User-friendly error message contains input" );

$str = '{ "foo" : -1 }';
$res = eval { decode_js($str) };
$err = $@;
ok( !$err, "can parse negative decimals" );

$str = '{ 1234: 2 }';
$res = eval { decode_js($str) };
$err = $@;
ok( !$err, "can parse keys made of numbers" );

$str = '[ 1, 2, 3 ]';
$res = eval { decode_js($str) };
$err = $@;
ok( !$err, "can parse a top-level arrayref" );
is_deeply( $res, [qw<1 2 3>], 'top-level arrayref has right contents' );

$str = '1';
$res = eval { decode_js($str) };
$err = $@;
ok( !$err, "can parse a top-level number" );
is( $res, '1', 'parsing top-level number returns right number' );

$str = '"1!"';
$res = eval { decode_js($str) };
$err = $@;
ok( !$err, "can parse a top-level string" );
is( $res, '1!', 'parsing top-level string returns right string' );
