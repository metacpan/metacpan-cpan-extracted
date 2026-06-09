use warnings;
use strict;

use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process);


my $k = tie my $sv, 'IPC::Shareable', {
    create => 1,
    destroy => 1,
    size => 1,
    serializer => 'storable',
};

my $ok = eval {
    $sv = "more than one byte";
    1;
};

is $ok, undef, "Overwriting the byte boundary size of an shm barfs ok";
like $@, qr/exceeds shared segment size/, "...and the error is sane";

(tied $sv)->clean_up_all;

# JSON serializer: same size check fires in _encode_json
{
    my $k2 = tie my $sv2, 'IPC::Shareable', {
        create     => 1,
        destroy    => 1,
        serializer => 'json',
        size       => 1,
    };

    my $ok2 = eval { $sv2 = 'x'; 1 };

    is $ok2, undef, "json: croaks when encoded data exceeds segment size";
    like $@, qr/exceeds shared segment size/, "json: ...and the error is sane";

    $k2->clean_up_all;
}

IPC::Shareable::_end;

assert_clean_process();

done_testing();
