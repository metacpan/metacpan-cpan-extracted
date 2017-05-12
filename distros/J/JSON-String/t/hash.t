use strict;
use warnings;

use Test::More tests => 2;

use JSON::String;
use JSON;

my $codec = JSON->new->canonical;

subtest 'encode hash' => sub {
    plan tests => 6;

    my $orig = { a => "1", b => "2", c => "3" };
    my $string = $codec->encode($orig);

    my $obj = JSON::String->tie($string);
    isa_ok($obj, 'HASH');
    is_deeply({ %$obj },
              $orig,
              'object hashifies');
    is(scalar(%$obj), scalar(%$orig), 'hash as scalar');
    foreach my $key ( qw( a b c )) {
        is($obj->{$key}, $orig->{$key}, "key $key");
    }
};

subtest 'change hash' => sub {
    plan tests => 4;

    my $expected = { a => 1, b => 2, c => 3 };
    my $string = $codec->encode($expected);
    my $obj = JSON::String->tie($string);

    $obj->{a} = $expected->{a} = 'hi';
    is($string,
       $codec->encode($expected),
       'change key a');

    $obj->{newkey} = $expected->{newkey} = 'new';
    is($string,
       $codec->encode($expected),
       'add new key');

    delete $obj->{b}; delete $expected->{b};
    is($string,
       $codec->encode($expected),
       'delete element');

    %$obj = %$expected = ();
    is($string,
        $codec->encode($expected),
        'clear');
};
