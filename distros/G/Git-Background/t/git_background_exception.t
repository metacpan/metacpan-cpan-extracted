#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Git::Background::Exception;

use constant CLASS => 'Git::Background::Exception';

note('with output');
{
    my $obj = CLASS()->new(
        {
            exit_code => 7,
            stderr    => [ 'an error', 'happend' ],
            stdout    => [ 'text on',  'stdout' ],
        },
    );
    isa_ok( $obj, CLASS(), 'new returned object' );

    is( $obj->{_exit_code}, 7, 'contains exit_code' );
    is( $obj->exit_code,    7, 'can be read by ->exit_code' );

    is_deeply( $obj->{_stderr},  [ 'an error', 'happend' ], 'contains correct stderr' );
    is_deeply( [ $obj->stderr ], [ 'an error', 'happend' ], 'can be read by ->stderr' );

    is_deeply( $obj->{_stdout},  [ 'text on', 'stdout' ], 'contains correct stdout' );
    is_deeply( [ $obj->stdout ], [ 'text on', 'stdout' ], 'can be read by ->stdout' );

    is( "$obj",           "an error\nhappend", 'object stringifies to stderr' );
    is( ( $obj ? 1 : 0 ), 1,                   'booleanizes to true' );
}

note('without output');
{
    my $obj = CLASS()->new(
        {
            exit_code => 11,
            stderr    => [],
            stdout    => [],
        },
    );
    isa_ok( $obj, CLASS(), 'new returned object' );

    is( $obj->{_exit_code}, 11, 'contains exit_code' );
    is( $obj->exit_code,    11, 'can be read by ->exit_code' );

    is_deeply( $obj->{_stderr},  [], 'contains no stderr' );
    is_deeply( [ $obj->stderr ], [], 'can be read by ->stderr' );

    is_deeply( $obj->{_stdout},  [], 'contains no stdout' );
    is_deeply( [ $obj->stdout ], [], 'can be read by ->stdout' );

    is( "$obj",           'git exited with fatal exit code 11 but had no output to stderr', 'object stringifies to correct message' );
    is( ( $obj ? 1 : 0 ), 1,                                                                'booleanizes to true' );
}

note('boolean');
{
    my $obj = CLASS()->new(
        {
            exit_code => 13,
            stderr    => ['0'],
            stdout    => [],
        },
    );
    isa_ok( $obj, CLASS(), 'new returned object' );

    is( "$obj",           '0', 'object stringifies to stderr' );
    is( ( $obj ? 1 : 0 ), 1,   'booleanizes to true' );
}

note('incorrect usage');
{
    my $obj = CLASS()->new;
    isa_ok( $obj, CLASS(), 'new returned object' );

    ok( !defined $obj->{_exit_code}, q{_exit_code doesn't exist} );
    ok( !defined $obj->{_stderr},    q{_stderr doesn't exist} );
    ok( !defined $obj->{_stdout},    q{_stdout doesn't exist} );

    ok( !defined $obj->exit_code, q{exit_code returns undef} );
    is_deeply( [ $obj->stderr ], [], q{stderr returns an empty list} );
    is_deeply( [ $obj->stdout ], [], q{stdout returns an empty list} );

    is( "$obj",           'git exited with a fatal exit code but had no output to stderr', 'object stringifies to correct message' );
    is( ( $obj ? 1 : 0 ), 1,                                                               'booleanizes to true' );
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
