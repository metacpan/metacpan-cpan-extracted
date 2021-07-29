use warnings;
use strict;

use IPC::Shareable;
use Test::More;

my $k = tie my $sv, 'IPC::Shareable', {
    create => 1,
    destroy => 1,
    size => 1,
};

my $ok = eval {
    $sv = "more than one byte";
    1;
};

is $ok, undef, "Overwriting the byte boundary size of an shm barfs ok";
like $@, qr/exceeds shared segment size/, "...and the error is sane";

(tied $sv)->clean_up_all;

done_testing();
