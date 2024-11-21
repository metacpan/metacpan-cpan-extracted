use v5.40;
use experimental 'class';

class Minima::Controller;

use Data::Dumper;
use Encode qw(decode);
use Hash::MultiValue;
use Minima::View::PlainText;
use Plack::Request;
use Plack::Response;

field $env             :reader;
field $app      :param :reader;
field $route    :param :reader = {};

field $request  :reader;
field $response :reader;
field $params   :reader;

field $req_encoding;

ADJUST {
    $env = $app->env // {};

    $request  = Plack::Request->new($env);
    $response = Plack::Response->new(200);

    $params = $self->_get_request_parameters;
}

method hello
{
    $self->render(Minima::View::PlainText->new, "hello, world\n");
}

method not_found
{
    $response->code(404);
    $self->render(Minima::View::PlainText->new, "not found\n");
}

method redirect ($url, $code = 302)
{
    $response->redirect($url, $code);
    $response->finalize;
}

method render ($view, $data = {})
{
    $response->body($view->render($data));
    $view->prepare_response($response);

    $response->finalize;
}

method print_env
{
    return $self->redirect('/') unless $app->development;

    my $max = 0;
    for (map { length } keys %$env) {
        $max = $_ if $_ > $max;
    }

    $self->render(
        Minima::View::PlainText->new,
        map {
            sprintf "%*s => %s\n", -$max, $_, $env->{$_}
        } sort keys %$env
    );
}

method dd ($ref)
{
    my $dumper = Data::Dumper->new([ $ref ]);
    $dumper->Terse(1);

    $self->render(
        Minima::View::PlainText->new,
        $dumper->Dump,
    );
}

method _get_request_parameters
{
    $req_encoding = $app->config->{request_encoding} // 'UTF-8';

    my @parameters = map {
        $self->_decode($_)
    } $request->parameters->flatten;

    $params = Hash::MultiValue->new(@parameters);
}

method _decode ($data)
{
    if (ref $data eq ref {}) {
        my %encoded;
        for my ($k, $v) (%$data) {
            $encoded{ $self->_decode($k) } = $self->_decode($v);
        }
        return \%encoded;
    }

    if (ref $data eq ref []) {
        my @encoded;
        for my $v (@$data) {
            push @encoded, $self->_decode($v);
        }
        return \@encoded;
    }

    if (defined $data) {
        return decode($req_encoding, $data);
    }

    undef;
}

__END__

=head1 NAME

Minima::Controller - Base class for controllers used with Minima

=head1 SYNOPSIS

    use Minima::Controller;

    my $controller = Minima::Controller->new(
        app => $app,         # Minima::App
        route => $match,     # a match returned by Minima::Router
    );
    $controller->hello;

=head1 DESCRIPTION

Serving as a base class to controllers used with L<Minima>, this class
provides the basic infrastructure for any type of controller. It is
built around L<Plack::Request> and L<Plack::Response> objects, allowing
subclasses to interactly directly with Plack.

Minima::Controller also keeps references to the L<Minima::App> and Plack
environment. Additionally, it retains data received from the router,
making it readily available to controllers.

This base class is not connected to any view, which is left to methods
or subclasses. However, it sets a default C<Content-Type> header for the
response as C<'text/plain; charset=utf-8'> and response code to 200.

=head1 CONFIGURATION

The C<request_encoding> key can be included in the main L<Minima::App>
configuration hash to specify the expected request encoding. The I<GET>
and I<POST> parameters will be decoded based on this setting.

If not set, C<request_encoding> defaults to C<UTF-8>. You may use any
encoding value supported by L<Encode>.

=head1 METHODS

=head2 new

    method new (app, route = {})

Instantiates a controller with the given C<$app> reference, and
optionally the hash reference returned by the router. If this hash
reference contains data extracted from the URI by L<Minima::Router>,
then this data will be made available to the controller through the
L<C<route>|/route> field.

=head2 redirect

    method redirect ($url, $code = 302)

Utility method to set the redirect header to the given URL and code
(defaults to 302, a temporary redirect) and finalize the response.

Use with C<return> inside other controller methods to shortcut:

    # someone shouldn't be here
    return $self->redirect('/login');
    # continue for logged in users

=head2 render

    method render ($view, $data = {})

Utility method to call C<render> on the passed view, together with
optional data, and save to the response body. It then calls
C<prepare_response> on the passed view and returns the finalized
response.

=head1 EXTRAS

=head2 hello, not_found

Methods used to emit a minimal C<hello, world> or not found response.

=head2 print_env

Returns a plain text printout of the current Plack environment.

=head2 dd

    method dd ($ref)

Sets the response to C<text/plain>, dumps the passed reference with
L<Data::Dumper>, and finalizes the response. Useful for debugging.

    return dd($my_data);

=head1 ATTRIBUTES

All attributes below are accessible through reader methods.

=over 4

=item C<env>

Plack environment.

=item C<app>

Reference to a L<Minima::App>.

=item C<route>

Hash reference returned by the router.

=item C<request>

Internal L<Plack::Request>

=item C<response>

Internal L<Plack::Response>

=item C<params>

Decoded GET and POST parameters merged in a L<Hash::MultiValue>. See
L<"Configuration"|/CONFIGURATION> to set the desired encoding.

=back

=head1 SEE ALSO

L<Minima>, L<Minima::App>, L<Minima::Router>, L<Minima::View>,
L<Plack::Request>, L<Plack::Response>, L<perlclass>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
