use strict;

use Test::More tests => 1;

#-------------------------------------------------------------------------
# basic usability
#-------------------------------------------------------------------------

BEGIN {
    my $skip_all = 0;
    my @missing_list;

    eval { require Hash::Merge; };
    if ( $@ ) {
        $skip_all++;
        push @missing_list, 'Hash::Merge';
    }

    eval { require Config::General; };
    if ( $@ ) {
        $skip_all++;
        push @missing_list, 'Config::General';
    }

    SKIP: {
        skip "Gantry::Conf requires @missing_list", 1
                if $skip_all;

        use_ok( 'Gantry::Conf' );
    }
}
