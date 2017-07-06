use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use ok 'Devel::PartialDump';

our $d = Devel::PartialDump->new;

is( $d->dump("foo"), '"foo"', "simple value" );

is( $d->dump(undef), "undef", "undef" );

is( $d->dump("foo" => "bar"), 'foo: "bar"', "named params" );

is( $d->dump( \"foo" => "bar" ), '\\"foo", "bar"', "not named params" );

is( $d->dump("foo\nbar"), '"foo\nbar"', "newline" );

is( $d->dump("foo" . chr(1)), '"foo\x{1}"', "non printable" );

my $foo = "foo";
is( $d->dump(\substr($foo, 0)), '\\"foo"', "reference to lvalue");

is( $d->dump(\\"foo"), '\\\\"foo"', "reference to reference" );

subtest 'max_length' => sub {
    my @list = 1 .. 10;
    local $d = Devel::PartialDump->new(
        pairs        => 0,
        max_elements => undef,
    );

    $d->max_length(undef);
    is( $d->dump(@list), '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', 'undefined');

    $d->max_length(100);
    is( $d->dump(@list), '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', 'high');

    $d->max_length(10);
    is( $d->dump(@list), '1, 2, 3...', 'low' );

    $d->max_length(0);
    is( $d->dump(@list), '...', 'zero' );
};

subtest 'max_elements for lists' => sub {
    my @list = 1 .. 10;
    local $d = Devel::PartialDump->new( pairs => 0 );

    $d->max_elements(undef);
    is( $d->dump(@list), '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', 'undefined' );

    $d->max_elements(100);
    is( $d->dump(@list), '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', 'high' );

    $d->max_elements(6);
    is( $d->dump(@list), '1, 2, 3, 4, 5, 6, ...', 'low' );

    $d->max_elements(0);
    is( $d->dump(@list), '...', 'zero' );
};

subtest 'max_elements for pairs' => sub {
    my @list = 1 .. 10;
    local $d = Devel::PartialDump->new( pairs => 1 );

    $d->max_elements(undef);
    is( $d->dump(@list), '1: 2, 3: 4, 5: 6, 7: 8, 9: 10', 'undefined' );

    $d->max_elements(100);
    is( $d->dump(@list), '1: 2, 3: 4, 5: 6, 7: 8, 9: 10', 'high' );

    $d->max_elements(3);
    is( $d->dump(@list), '1: 2, 3: 4, 5: 6, ...', 'low' );

    $d->max_elements(0);
    is( $d->dump(@list), '...', 'zero' );
};

subtest 'max_depth' => sub {
    local $d = Devel::PartialDump->new;

    my $data = { foo => ["bar"], gorch => { 1 => ["bah"] } };

    $d->max_depth(10);
    is( $d->dump($data), '{ foo: [ "bar" ], gorch: { 1: [ "bah" ] } }', "high" );

    $d->max_depth(2);
    like( $d->dump($data), qr/^\{ foo: \[ "bar" \], gorch: \{ 1: ARRAY\(0x[0-9A-Fa-f]+\) \} \}/, "low" );

    $d->max_depth(0);
    like( $d->dump($data), qr/^HASH\(0x[0-9A-Fa-f]+\)/, "zero" );
};

{
    local $d = Devel::PartialDump->new( pairs => 0, list_delim => ',' );
    is( $d->dump("foo", "bar"), '"foo","bar"', "list_delim" );
}

{
    local $d = Devel::PartialDump->new( pairs => 1, pair_delim => '=>' );
    is( $d->dump("foo" => "bar"), 'foo=>"bar"', "pair_delim" );
}

done_testing;
