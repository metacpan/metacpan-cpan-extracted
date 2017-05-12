package TestApp::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/' => page {
    render_region (name => 'form', path => 'form');
};

template 'form' => sub {
    form {
        br {};  br {};
        my $action = new_action( class   => 'CreateMediaFile' );
        render_action ( $action );
        form_submit();
    };

   hyperlink (label => 'Manage files',
                onclick => {
                popout => '/media_manage', args => { mediadir => '/images/', rootdir => '/images/'} });
};


1;
