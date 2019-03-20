use Test2::V0;

use Function::Interface;

sub positional() { !!0 }
sub named()      { !!1 }
sub required()   { !!0 }
sub optional()   { !!1 }

subtest 'valid case' => sub {
    my @data = (
        'Str $a' => [ ['Str', '$a', positional, required] ],
        'Str :$a' => [ ['Str', '$a', named, required] ],
        'Str $a=' => [ ['Str', '$a', positional, optional] ],
        'Str :$a=' => [ ['Str', '$a', named, optional] ],

        'ArrayRef[Int] $a' => [ ['ArrayRef[Int]', '$a', positional, required] ],
        'Int $a, Num $b' => [ ['Int', '$a', positional, required], ['Num', '$b', positional, required] ],
    );

    while (my ($src, $expected) = splice @data, 0, 2) {
        my $got = Function::Interface::_assert_valid_interface_params($src);

        my @e = map {
            +{
                type     => $_->[0],
                name     => $_->[1],
                named    => !!$_->[2],
                optional => !!$_->[3],
            }
        } @$expected;

        is $got, \@e, $src;
    }
};

subtest 'invalid case' => sub {
    my @data = (
        'Str',
        '$a',
        '$Str $a',
        '#Str $a',
    );

    for my $src (@data) {
        like dies {
            Function::Interface::_assert_valid_interface_params($src);
        }, qr/^invalid interface params/, $src;
    }
};

done_testing;
