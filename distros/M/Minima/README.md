# Minima

Efficient web framework build with modern core classes.

_app.psgi_

    use Minima;
    Minima::init;

For a `hello, world`:

    $ minima run    # or plackup app.psgi, as you prefer

And that's it, you've got a functional app. To set up routes, edit
_etc/routes.map_:

    GET     /           :Main   home
    POST    /login      :Login  process_login
    @       not_found   :Main   not_found

Controllers:

    class Controller::Main :isa(Minima::Controller);

    method home {
        $view->set_template('home');
        $self->render($view, { name => 'world' });
    }

Templates:

    %% if name
    <h1>hello, [% name %]</h1>
    %% end

## Installation

Install with [cpanm][cpm]:

    $ cpanm Minima

## Documentation

To learn more about Minima, check the included documentation with:

    $ perldoc Minima

Or, if you haven't installed it yet:

    $ perldoc lib/Minima

 [cpm]: https://github.com/miyagawa/cpanminus
