package Testapp::View;
use strict;
use warnings;
use Jifty::View::Declare -base;
use Jifty::View::Declare::Helpers;
 
 
template '/' => page {
    with ( name => 'test texts' ),
    form {
        my $create = new_action( class => 'CreateTexts',
                                moniker => 'texts' );
            render_action( $create );
    };
};
 
