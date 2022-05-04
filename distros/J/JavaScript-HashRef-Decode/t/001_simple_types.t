use Test::More qw<no_plan>;
use strict;
use warnings;

# This uses the JavaScript::HashRef::Decode **INTERNALS**

use_ok('JavaScript::HashRef::Decode');

my $parser = do {
    no warnings 'once';
    Parse::RecDescent->new($JavaScript::HashRef::Decode::js_grammar)
      or die "Parse::RecDescent: Bad JS grammar!\n";
};

sub parse_ok {
    my ( $type, $source, $expected, $desc ) = @_;
    my $value = $parser->$type($source);
    like(
        ref($value),
        qr/\A JavaScript::HashRef::Decode::[A-Z]+ \z/xms,
        "parsed: $desc"
    ) and is_deeply( $value->out, $expected, "result: $desc" );
}

parse_ok( undefined => 'undefined', undef, 'simple undefined' );

parse_ok( true  => 'true',  !0, 'simple true' );
parse_ok( false => 'false', !1, 'simple false' );

parse_ok( string => '"foo"',    'foo',   'simple dquoted string' );
parse_ok( key    => 'foo',      'foo',   'simple unquoted key' );
parse_ok( key    => '"foo"',    'foo',   'simple dquoted key' );
parse_ok( key    => '"fo\"o"',  'fo"o',  'escaped dquoted key' );
parse_ok( key    => "'foo'",    'foo',   'simple squoted key' );
parse_ok( string => "'foo'",    'foo',   'simple squoted string' );
parse_ok( string => q!"f\"oo"!, 'f"oo',  'string with escaped double quote' );
parse_ok( string => q!"f\'oo"!, "f'oo",  'dquoted string with escaped squote' );
parse_ok( string => q!"f\noo"!, "f\noo", 'string with escaped newline' );

parse_ok(
    string => q!"f\noo\0\b\f\r\v\\\\"!,
    qq!f\noo\0\b\f\r\x0B\\!,
    'string with various escaped characters'
);
parse_ok(
    string => q!"\xa9\u263A"!,
    "\x{a9}\x{263a}",
    'string with \x and \u escapes'
);
parse_ok(
    string => q!"\u263a\ud804\uDC10\u263a"!,
    "\x{263a}\x{11010}\x{263a}",
    'string with astral-plane \u escapes'
);
parse_ok( string => q!"\&"!, '&', 'string with unknown pass-through escape' );

parse_ok( number => '123',        123,        'simple number' );
parse_ok( number => '123.45',     123.45,     'float number' );
parse_ok( number => '123.45e2',   12345,      'number: int, frac, exp' );
parse_ok( number => '123e2',      12300,      'number: int, exp' );
parse_ok( number => '.123e2',     12.3,       'number: frac, exp' );
parse_ok( number => '5e3',        5000,       'number: int, exp' );
parse_ok( number => '0x1',        1,          'number: hex' );
parse_ok( number => '0Xdeadbeef', 0xDEADBEEF, 'number: heX' );

parse_ok( arrayref => '[]',      [],          'empty arrayref' );
parse_ok( arrayref => '[1,2,3]', [ 1, 2, 3 ], 'simple arrayref' );
parse_ok(
    arrayref => '[1,"foo",3]',
    [ 1, 'foo', 3 ], 'mixed num/dquote arrayref'
);
parse_ok(
    arrayref => "[1,'foo',3]",
    [ 1, 'foo', 3 ], 'mixed num/squote arrayref'
);

parse_ok(
    arrayref => '[1,{foo:"bar",bar:6.66},3]',
    [ 1, { foo => 'bar', bar => 6.66 }, 3 ],
    'mixed num/object/dquote arrayref'
);

parse_ok(
    arrayref => "[1,{foo:'bar',bar:6.66},3]",
    [ 1, { foo => 'bar', bar => 6.66 }, 3 ],
    'mixed num/object/squote arrayref'
);

parse_ok( hashref => '{}', {}, 'empty hashref' );
parse_ok(
    hashref => '{k:"v",y:undefined}',
    { k => 'v', y => undef },
    'simple hashref'
);
parse_ok(
    hashref => '{k:[1,undefined,3],y:{k:"v",y:false}}',
    { k => [ 1, undef, 3 ], y => { k => 'v', y => !1 } },
    'complex hashref'
);
