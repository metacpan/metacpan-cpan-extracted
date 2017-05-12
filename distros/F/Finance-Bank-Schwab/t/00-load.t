use strict;
use warnings;
use Test::More;
use File::Find;

BEGIN {
    find( {
            wanted => sub {
                return unless m{\.pm$};

                s{^lib/}{};
                s{.pm$}{};
                s{/}{::}g;

                use_ok($_)
                  or die "Couldn't use_ok $_";
            },
            no_chdir => 1,
        },
        'lib'
    );
    done_testing();

}
