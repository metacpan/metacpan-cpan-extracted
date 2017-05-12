use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use File::LibMagic qw( :complete );

# TODO can we simulate an out-of-memory error?

## no critic (TestingAndDebugging::ProhibitNoWarnings)

{
    my $h = magic_open(MAGIC_NONE);

    {
        no warnings 'uninitialized';
        like(
            exception { magic_load( undef, 't/samples/magic' ) },
            qr{magic_load requires a defined handle},
            'magic_load error when not given a handle'
        );
    }

    magic_close($h);
}

{
    my $h = magic_open(MAGIC_NONE);
    magic_load( $h, 't/samples/magic' );

    {
        no warnings 'uninitialized';
        like(
            exception { magic_buffer( undef, 'foo' ) },
            qr{magic_buffer requires a defined handle},
            'magic_buffer error when not given a handle'
        );
    }

    like(
        exception { magic_buffer( $h, undef ) },
        qr{magic_buffer requires defined content},
        'magic_buffer error with undef as content'
    );

    {
        no warnings 'uninitialized';
        like(
            exception { magic_file( undef, 't/samples/foo.foo' ) },
            qr{magic_file requires a defined handle},
            'magic_file error when not given a handle'
        );
    }

    like(
        exception { magic_file( $h, undef ) },
        qr{magic_file requires a filename},
        'magic_file error when given undef as a file'
    );

TODO: {
        local $TODO = 'check libmagic version';
        like(
            exception { magic_file( $h, 't/samples/missing' ) },
            qr{libmagic cannot open .+ at },
            'magic_file error when given a non-existent file (depends on libmagic version)'
        );
    }

    magic_close($h);
}

{
    no warnings 'uninitialized';
    my $h = magic_open(MAGIC_NONE);

    like(
        exception { magic_close(undef) },
        qr{magic_close requires a defined handle},
        'magic_close error when not given a handle'
    );
}

done_testing();
