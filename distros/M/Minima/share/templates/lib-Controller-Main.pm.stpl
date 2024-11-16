use v5.40;
use experimental 'class';

class Controller::Main :isa(Minima::Controller);

use Minima::View::HTML;

field $view;

ADJUST {
    $view = Minima::View::HTML->new(
        app => $self->app,
    );
    $view->add_pre('header');
    $view->add_post('footer');

    $self->response->content_type('text/html; charset=utf-8');
}

method home
{
    $view->set_template('home');
    $self->render($view);
}

method not_found
{
    $self->response->code(404);
    $view->set_compound_title('Not Found');
    $view->set_template('e404');
    $self->render($view);
}

method error ($e)
{
    $self->response->code(500);
    $view->set_compound_title('Error');
    $view->set_template('e500');
    $self->render($view, { error => $e });
}
