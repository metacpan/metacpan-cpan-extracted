use Test2::V0;

use Function::Interface;

subtest 'valid case' => sub {
    my @data = (
        'Str'                       => ['Str'],
        'ArrayRef[Int]'             => ['ArrayRef[Int]'],
        'Enum["a", $b, C]'          => ['Enum["a", $b, C]'],
        'ArrayRef[Dict[Str,Int]]'   => ['ArrayRef[Dict[Str,Int]]'],
        'Str, Int'                  => ['Str', 'Int'],
        ' Str'                      => ['Str'],
        'Str '                      => ['Str'],
        ' Str '                     => ['Str'],
        'Enum[@a]'                  => ['Enum[@a]'],
        'Dict[%h]'                  => ['Dict[%h]'],
        'ArrayRef [Int]'            => ['ArrayRef [Int]'],

        'Str, ArrayRef[Int ], Enum[ "a", "b", $a], Int, ArrayRef[Dict[Str,Int]], HashRef'
        => ['Str', 'ArrayRef[Int ]', 'Enum[ "a", "b", $a]', 'Int', 'ArrayRef[Dict[Str,Int]]', 'HashRef'],

        'ArrayRef[
            Int, Str
        ]' => [
        'ArrayRef[
            Int, Str
        ]'],
    );

    while (my ($src, $expected) = splice @data, 0, 2) {
        my $got = Function::Interface::_assert_valid_interface_return($src);
        is $got, $expected, $src;
    }
};

subtest 'invalid case' => sub {
    my @data = (
        '#Str',
        '$Str',
        'Str#',
        'Str$',
        'ArrayRef[Int Int]',
    );

    for my $src (@data) {
        like dies {
            Function::Interface::_assert_valid_interface_return($src);
        }, qr/^invalid interface return/, $src;
    }
};


done_testing;
