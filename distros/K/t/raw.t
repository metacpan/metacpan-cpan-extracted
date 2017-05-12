use strict;
use warnings;
use Test::More;
use Test::Exception;
use t::QServer;

test_qserver {
    my $port = shift;

    use_ok 'K::Raw';

    my $handle = khpu("localhost", $port, "");

    ok $handle > 0, 'connected';

    subtest scalar          => sub { scalar_tests($handle)          };
    subtest null_scalar     => sub { null_scalar_tests($handle)     };
    subtest infinity_scalar => sub { infinity_scalar_tests($handle) };
    subtest null_vector     => sub { null_vector_tests($handle)     };
    subtest ininite_vector  => sub { infinite_vector_tests($handle) };
    subtest vector          => sub { vector_tests($handle)          };
    subtest mixed_list      => sub { mixed_list_tests($handle)      };
    subtest dict            => sub { dict_test($handle)             };
    subtest table           => sub { table_test($handle)            };

    kclose($handle);
};

sub scalar_tests {
    my ($handle) = @_;

    ok  k($handle, '2 = 2'), 'parse true';
    ok !k($handle, '2 = 3'), 'parse false';

    is k($handle, '`int$7'),    7,    'parse int';
    is k($handle, '0x1f'),      0x1f, 'parse byte';
    is k($handle, '"c"'),       'c',  'parse char';
    is k($handle, '`short$12'), 12,   'parse short';
    is k($handle, '`long$13'),  13,   'parse long';

    my $real = k($handle, '`real$13.7');
    ok $real > 13.699999, 'real lower bound';
    ok $real < 13.700001, 'real upper bound';

    is k($handle, '`float$13.7'), 13.7,  'parse float';
    is k($handle, '`foo'),        'foo', 'parse symbol';

    my $timestamp = k($handle, '2012.03.24D23:25:13.12345678912345');
    is "$timestamp", '385946713123456789', 'parse timestamp';

    my $long = k($handle, '385946713123000000j');
    is "$long", '385946713123000000', 'parse long';

    is k($handle, '`month$3'),   3,    'parse month';
    is k($handle, '2012.03.24'), 4466, 'parse date';

    my $timespan = k($handle, '17D12:13:14.000001234');
    is "$timespan", '1512794000001234', 'parse timespan';

    is k($handle, '`minute$4'),   4,        'parse minute';
    is k($handle, '`second$5'),   5,        'parse second';
    is k($handle, '12:13:14.15'), 43994150, 'parse time';

    my $datetime = k($handle, '2012.03.24T12:13:14.01');
    is sprintf('%.3f', $datetime), '4466.509', 'parse datetime';

    throws_ok { k($handle, 'does_not_exist') } qr/does_not_exist/,
        'croaked properly on error';
}

sub null_scalar_tests {
    my ($handle) = @_;

    is k( $handle, '0b' ),   undef, 'null boolean';
    is k( $handle, '0x00' ), 0x00,  'null byte';  # 0
    is k( $handle, '0Nh' ),  undef, 'null short'; # 0
    is k( $handle, '0N' ),   undef, 'null int';
    is k( $handle, '0Nj' ),  undef, 'null long';
    is k( $handle, '0Ne' ),  undef, 'null real';
    is k( $handle, '0n' ),   undef, 'null float';
    is k( $handle, '" "' ),  ' ',   'null char'; # this ones weird
    is k( $handle, '`' ),    undef, 'null sym';
    is k( $handle, '0Nm' ),  undef, 'null month';
    is k( $handle, '0Nd' ),  undef, 'null day';
    is k( $handle, '0Nz' ),  undef, 'null datetime';
    is k( $handle, '0Np' ),  undef, 'null timestamp';
    is k( $handle, '0Nu' ),  undef, 'null minute';
    is k( $handle, '0Nv' ),  undef, 'null second';
    is k( $handle, '0Nt' ),  undef, 'null time';

    is k( $handle, '0n' ),   undef, 'NaN';
}

sub infinity_scalar_tests {
    my ($handle) = @_;

    is k( $handle, '0Wh'  ),  'inf', '+infinite short';
    is k( $handle, '0W'   ),  'inf', '+infinite int';
    is k( $handle, '0Wj'  ),  'inf', '+infinite long';
    is k( $handle, '0We'  ),  'inf', '+infinite real';
    is k( $handle, '0w'   ),  'inf', '+infinite float';
    is k( $handle, '0Wz'  ),  'inf', '+infinite datetime';
    is k( $handle, '0Wp'  ),  'inf', '+infinite timestamp';

    is k( $handle, '-0Wh' ), '-inf', '-infinite short';
    is k( $handle, '-0W'  ), '-inf', '-infinite int';
    is k( $handle, '-0Wj' ), '-inf', '-infinite long';
    is k( $handle, '-0We' ), '-inf', '-infinite real';
    is k( $handle, '-0w'  ), '-inf', '-infinite float';
    is k( $handle, '-0Wz' ), '-inf', '-infinite datetime';
    is k( $handle, '-0Wp' ), '-inf', '-infinite timestamp';
}

sub null_vector_tests {
    my ($handle) = @_;

    is_deeply k( $handle, '(),0b'  ), [ undef ], 'null boolean vector';
    is_deeply k( $handle, '(),0x00'), [ 0x00  ], 'null byte vector';
    is_deeply k( $handle, '()," "' ), [ ' '   ], 'null char vector'; # this ones weird
    is_deeply k( $handle, '(),0Nh' ), [ undef ], 'null short vector';
    is_deeply k( $handle, '(),0N'  ), [ undef ], 'null int vector';
    is_deeply k( $handle, '(),0Nj' ), [ undef ], 'null long vector';
    is_deeply k( $handle, '(),0Ne' ), [ undef ], 'null real vector';
    is_deeply k( $handle, '(),0n'  ), [ undef ], 'null float vector';
    is_deeply k( $handle, '(),`'   ), [ undef ], 'null sym vector';
    is_deeply k( $handle, '(),0Nm' ), [ undef ], 'null month vector';
    is_deeply k( $handle, '(),0Nd' ), [ undef ], 'null day vector';
    is_deeply k( $handle, '(),0Nz' ), [ undef ], 'null datetime vector';
    is_deeply k( $handle, '(),0Np' ), [ undef ], 'null timestamp vector';
    is_deeply k( $handle, '(),0Nu' ), [ undef ], 'null minute vector';
    is_deeply k( $handle, '(),0Nv' ), [ undef ], 'null second vector';
    is_deeply k( $handle, '(),0Nt' ), [ undef ], 'null time vector';

    is_deeply k( $handle, '(),0n'  ), [ undef ], 'NaN vector';
}

sub infinite_vector_tests {
    my ($handle) = @_;

    is_deeply k( $handle, '(),0Wh' ),  [ 'inf'  ], '+infinite short vector';
    is_deeply k( $handle, '(),0W'  ),  [ 'inf'  ], '+infinite int vector';
    is_deeply k( $handle, '(),0Wj' ),  [ 'inf'  ], '+infinite long vector';
    is_deeply k( $handle, '(),0We' ),  [ 'inf'  ], '+infinite real vector';
    is_deeply k( $handle, '(),0w'  ),  [ 'inf'  ], '+infinite float vector';
    is_deeply k( $handle, '(),0Wz' ),  [ 'inf'  ], '+infinite datetime vector';
    is_deeply k( $handle, '(),0Wp' ),  [ 'inf'  ], '+infinite timestamp vector';

    is_deeply k( $handle, '(),-0Wh' ), [ '-inf' ], '-infinite short vector';
    is_deeply k( $handle, '(),-0W'  ), [ '-inf' ], '-infinite int vector';
    is_deeply k( $handle, '(),-0Wj' ), [ '-inf' ], '-infinite long vector';
    is_deeply k( $handle, '(),-0We' ), [ '-inf' ], '-infinite real vector';
    is_deeply k( $handle, '(),-0w'  ), [ '-inf' ], '-infinite float vector';
    is_deeply k( $handle, '(),-0Wz' ), [ '-inf' ], '-infinite datetime vector';
    is_deeply k( $handle, '(),-0Wp' ), [ '-inf' ], '-infinite timestamp vector';
}

sub vector_tests {
    my ($handle) = @_;

    is_deeply k($handle, '(0b;1b;0b)'), [undef, 1, undef], 'parse bool vector';
    is_deeply k($handle, '"abc"'),      [qw/a b c/],       'parse char vector';
    is_deeply k($handle, '(7h;8h;9h)'), [7, 8, 9],         'parse short vector';
    is_deeply k($handle, '(7i;8i;9i)'), [7, 8, 9],         'parse int vector';

    is_deeply
        [ map {"$_"} @{ k($handle, '(7j;8j;9j)') } ],
        [ qw(7 8 9) ],
        'parse long vector';

    is_deeply k($handle, '(7e;8e;9e)'), [7, 8, 9],   'parse real vector';
    is_deeply k($handle, '(7f;8f;9f)'), [7, 8, 9],   'parse float vector';
    is_deeply k($handle, '(`a;`b;`c)'), [qw(a b c)], 'parse symbol vector';

    is_deeply
        [ map { "$_" } @{ k($handle, 'enlist 2012.03.24D23:25:13.123456789') } ],
        [ '385946713123456789' ],
        'parse timestamp vector';
}

sub mixed_list_tests {
    my ($handle) = @_;

    is_deeply
        [ map { "$_" } @{ k($handle, '(1b;8i;9j)') } ],
        [ qw/1 8 9/],
        'parse mixed list of nums';

    is_deeply
        k($handle, '((1e;2i;(3f;`foo));"x")'),
        [
            [
                1,
                2,
                [3,'foo'],
            ],
            'x',
        ],
        'parse complex mixed list';
}

sub dict_test {
    my ($handle) = @_;

    # dictionary
    is_deeply
        k($handle, '`foo`bar!(1;2)'),
        {
            foo => 1,
            bar => 2,
        },
        'parse dictionary';

    # one key dictionary
    is_deeply
        k($handle, '`foo!1'),
        1,
        'parse dictionary with one val';

    is_deeply
        k($handle, '`foo`bar!((1;2);(3;4))'),
        {
            foo => [ 1, 2],
            bar => [ 3, 4 ],
        },
        'parse dictionary w/ list values';

    is_deeply
        k($handle, '`foo`foo!(1;2)'),
        { foo => 1 },
        'parse dictionary w/ list values';

    is_deeply
        k($handle, '`foo`bar!(0n;`)'),
        { foo => undef, bar => undef },
        'parse dictionary w/ null values';

    is_deeply
        k($handle, '()!()'),
        {},
        'parse empty dictionary';
}

sub table_test {
    my ($handle) = @_;

    # table
    is_deeply
        k($handle, '([] grr: (`aaa;`bbb;`ccc); bla: (`xxx;`yyy;`zzz))'),
        {
            grr => [qw(aaa bbb ccc)],
            bla => [qw(xxx yyy zzz)],
        },
        'parse table';

    is_deeply
        k($handle, '([] hah: `symbol$(`aaa;`bbb;`ccc))'),
        {
            hah => [qw(aaa bbb ccc)],
        },
        'parse single column table';

    # table w/ primary key
    is_deeply
        k($handle, '([p: (`a;`b); q: (`c;`d) ] foo: (`aaa;`bbb); bar: (`ccc;`ddd))'),
        {
            p   => [qw(a b)],
            q   => [qw(c d)],
            foo => [qw(aaa bbb)],
            bar => [qw(ccc ddd)],
        },
        'parse table w/ primary key';
}

END { done_testing; }
