package TestApp::View;
use strict;
use warnings;
use Jifty::View::Declare -base;
use Jifty::View::Declare::Helpers;


template '/' => page {
    with ( name => 'openid-form' ),
    form {
        my $openid = new_action( class   => 'AuthenticateOpenID',
                                moniker => 'authenticateopenid' );
        div { { class is 'openid'};
            div { { id is 'openid-login' };
                render_action( $openid );
                outs_raw(
                    Jifty->web->return(
                        to     => '/openid_verify_done',
                        label  => _("Login with OpenID"),
                        submit => $openid
                    ));
            };
        };
    };
    show 'openid/wayf', '/';
};


template '/openid_verify_done' => page {
    h1 { "Done" };
};




1;
