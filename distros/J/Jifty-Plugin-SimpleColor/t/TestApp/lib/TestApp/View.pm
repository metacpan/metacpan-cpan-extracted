package TestApp::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/' => page {
   
    form {
        br {};  br {};  br {};  br {}; 
        my $action = new_action( class   => 'CreateColor' );
        render_action ( $action );
        form_submit();
    };
};

1;
