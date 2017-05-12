use Test::More tests => 2;
use strict;

# template toolkit plugin
BEGIN {
    my $skip_all;

    eval { require Template; };
    if ( $@ ) {
        $skip_all++;
    }

    SKIP: {
        if ( $skip_all ) {
            skip 'Gantry::Template::TT requires Template Toolkit', 2;
        }

        use_ok('Gantry::Template::TT');
    }
    exit 0 if $skip_all;
}

can_ok('Gantry::Template::TT', 'do_action', 'do_error', 'do_process' );
