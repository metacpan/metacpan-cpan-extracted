use v5.40;
use experimental 'class';

class Controller :isa(Minima::Controller);

use Minima::View::HTML;

field $view;

ADJUST {
    $view = Minima::View::HTML->new(
        app => $self->app,
    );

    $self->response->content_type('text/html; charset=utf-8');
}

method main
{
    $view->set_template('home');
    $self->render($view);
}
