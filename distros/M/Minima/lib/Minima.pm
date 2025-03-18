use v5.40;

package Minima v0.5.0;

use Minima::Setup;

sub init ($config = undef)
{
    Minima::Setup::prepare($config);
    \&Minima::Setup::init;
}

1;

__END__

=head1 NAME

Minima - Efficient web framework built with modern core classes

=head1 SYNOPSIS

F<app.psgi>

    use Minima;
    Minima::init;

For a "hello, world":

    $ minima run    # or plackup app.psgi, as you prefer

And that's it, you've got a functional app. To set up routes, edit
F<etc/routes.map>:

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

=head1 DESCRIPTION

Minima is a framework for PSGI web applications built with Perl's new
native object-oriented features (L<perlclass>). It is designed to be
simple and minimal, connecting only what is necessary without getting in
the way. Consequently, it's lightweight and fast.

Although designed in a typical MVC fashion, no restrictions are imposed
on design patterns. Controller classes have access to Plack request and
response objects and can interact with them directly. Minima also
provides a class for rendering HTML with ease with L<Template
Toolkit|Template>, but you are free to use your own solution.

To understand the basic principles of how it works, see the following
section in this document. For more about the running process, check
L<Minima::App>. You may also want to visit
L<Minima::Manual::Customizing> to learn how to customize everything
according to your needs.

=head1 HOW IT WORKS

A typical web application using Minima operates as follows:

=over 4

=item 1.

L<Minima::Setup> is loaded. It will read a configuration file (if any,
see L<"Config File" in Minima::Setup|Minima::Setup/"CONFIG FILE">) and
provides a C<init> subroutine that is passed to Plack as the entry point
for receiving requests.

=item 2.

A L<Minima::App> is created and initialized with the supplied
configuration.

=item 3.

L<Minima::App> passes a routes file (where all application routes are
defined) to L<Minima::Router> to be read and parsed.

=item 4.

The request URL is matched to a route. L<Minima::App> then calls the
appropriate controller and method, setting them up and passing along the
relevant information such as request and route data.

=item 5.

The controller handles the necessary logic, calling models (if required)
and using views (if desired) to produce content. Content is then
assigned to the response and finalized.

=back

=head1 GETTING STARTED

To begin a project, the Minima package provides a subroutine  (described
below) to help you get started with the process mentioned above.

You can also interact directly with L<Minima::Setup> for full control
over the setup process.

=head2 init

    sub init ($config = undef)

A convenience subroutine that calls
L<C<Minima::Setup::prepare>|Minima::Setup/prepare> to prepare the  main
app object and returns a reference to
L<C<Minima::Setup::init>|Minima::Setup/init>.

The optional argument allows you to specify the location of the
configuration file.

For a detailed explanation of behavior and options, refer to the
documentation for L<Minima::Setup>.

=head1 EXAMPLE

Minima's repository contains an example application under F<eg/>. To run
it (from the root of the repository), use:

    $ cd eg
    $ plackup minima.psgi   # configure plackup or your server as needed

=head1 MANAGING A PROJECT

Included with the distribution you'll find a helper program to manage
projects. See L<minima> for full details.

One of its main features is creating a project from scratch, using
templates with the recommended structure.

    $ minima new app

=head1 HISTORY

While speaking with Paul Evans about the implementation of class in
Perl's core, he remarked, "You should write a blog post about it." This
led to I<Problem #1>: I don't have a blog. Solving that seemed easy
enough, but then came I<Problem #2>: there wasn't a web framework that
used the class feature. Naturally, I decided to tackle I<Problem #2>
first.

=head1 SEE ALSO

L<perlclass>, L<Minima::App>, L<Minima::Manual::Customizing>,
L<Minima::Manual::FAQ>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
