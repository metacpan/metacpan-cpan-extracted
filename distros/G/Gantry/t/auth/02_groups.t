use strict;
use Test::More tests => 1;

BEGIN {
    my $skip_all = 0;
    my @missing_list;

    eval { require Data::FormValidator; };
    if ( $@ ) {
        $skip_all++;
        push @missing_list, 'Data::FormValidator';
    }

    eval { require Template; };
    if ( $@ ) {
        $skip_all++;
        push @missing_list, 'Template Toolkit';
    }

    eval { require HTML::Prototype; };
    if ( $@ ) {
        $skip_all++;
        push @missing_list, 'HTML::Prototype';
    }

    SKIP: {
        skip "Gantry::Control::C::Groups requires @missing_list", 1
                if $skip_all;

        use_ok( 'Gantry::Control::C::Groups' );
    }
}
