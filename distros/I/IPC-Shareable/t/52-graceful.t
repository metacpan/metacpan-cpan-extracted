use warnings;
use strict;

use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue);


# non-graceful
{
    tie my $sv, 'IPC::Shareable', {
        key     => unique_glue('lock'),
        create  => 1,
        exclusive => 1,
        destroy => 1,
        serializer => 'storable',
    };

    my $catch = eval {
        tie my $sv2, 'IPC::Shareable', {
            key     => unique_glue('lock'),
            create  => 1,
            exclusive => 1,
            destroy => 1,
            serializer => 'storable',
        };
        1;
    };

    is
        $catch,
        undef,
        "without 'graceful', we croak if two attemps made on same exclusive seg";

    like
        $@,
        qr/using exclusive/,
        "...and error message is sane";
}

# graceful
my $catch;

{
    tie my $sv, 'IPC::Shareable', {
        key     => unique_glue('DONE'),
        create  => 1,
        exclusive => 1,
        graceful  => 1,
        destroy => 1,
        serializer => 'storable',
    };

    tie my $sv2, 'IPC::Shareable', {
        key     => unique_glue('DONE'),
        create  => 1,
        exclusive => 1,
        graceful  => 1,
        destroy => 1,
        serializer => 'storable',
    };
}

END {
    is
        $@,
        '',
        "with 'graceful', we silently exit if two attempts made on same exclusive seg";

    IPC::Shareable::_end;

    assert_clean_process();

    done_testing;
};
