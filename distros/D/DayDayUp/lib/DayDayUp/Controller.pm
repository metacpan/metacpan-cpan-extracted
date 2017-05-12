package DayDayUp::Controller; # make CPAN happy

use MooseX::Declare;

class DayDayUp::Controller extends Mojolicious::Controller is mutable {
    
    our $VERSION = '0.95';

    method render_tt($template) {
        $self->stash->{template_path} = $template;
        $self->render( handler => 'html' );
    };
    
    method redirect_tt($url) {
        $self->stash->{url} = $url;
        $self->render_tt( 'redirect.html' );
    }
};

1;
