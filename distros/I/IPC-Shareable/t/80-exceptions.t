use warnings;
use strict;

use Test::More;

#plan skip_all => "TEST FILE NOT READY";

use IPC::Shareable;

{
    # exclusive duplicate

    my $opts = {
        key       => 1234,
        create    => 1,
        exclusive => 1,
        destroy   => 1,
        mode      => 0600,
        size      => 999,
    };

    my $s = tie my %opt_test => 'IPC::Shareable', $opts;
    $opt_test{a} = 1;


    is
        eval {
            my $s = tie my %opt_test => 'IPC::Shareable', $opts;
            1;
        },
        undef,
        "trying to re-create an existing memory segment fails";

    like $@, qr/ERROR:.*File exists/, "...and error message is sane";

}

done_testing();
