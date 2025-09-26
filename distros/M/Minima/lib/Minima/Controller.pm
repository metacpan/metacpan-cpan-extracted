use v5.40;
use experimental 'class';

class Minima::Controller;

use Data::Dumper;
use Encode qw(decode);
use Hash::MultiValue;
use JSON;
use Minima::View::PlainText;
use Plack::Request;
use Plack::Response;
use Scalar::Util qw(reftype);

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

method before_action    ($m) { }
method after_action     ($r) { }

method trimmed_params ($options = {})
{
    my $exclude = $options->{exclude} // [];
    my @f_params = $params->flatten;
    my @params;

    for my ($k, $v) (@f_params) {
        if (defined $v) {
            my $skip = 0;
            for my $pat (@$exclude) {
                if (ref $pat && reftype $pat eq 'REGEXP') {
                    if (defined $k && $k =~ $pat) { $skip = 1; last }
                } else {
                    if (defined $k && $k eq $pat) { $skip = 1; last }
                }
            }
            if (!$skip) {
                if (!ref $v) {
                    $v = trim $v;
                } elsif (ref $v eq ref []) {
                    $v = [ map { defined $_ ? trim($_) : $_ } @$v ];
                }
            }
        }
        push @params, $k, $v;
    }
    return Hash::MultiValue->new(@params);
}

method json_body
{
    my $c_type = $request->content_type // '';
    return undef unless $c_type =~ m|\Aapplication/json\b|i;

    my $body = $request->content // '';
    return undef unless length $body;

    my $data;

    try {
        $data = decode_json($body);
    } catch ($e) {
        return undef;
    }

    return $data;
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
        join '', map {
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

    # Access route parameters (from URI captures)
    my $post_id = $controller->route->{post};

    # Access request parameters (query string or POST)
    my $q = $controller->params->get('q');

    # Render a response
    $controller->render(
        Minima::View::PlainText->new,
        "Post: $post_id, search: $q\n"
    );

=head1 DESCRIPTION

Serving as a base class to controllers used with L<Minima>, this class
provides the basic infrastructure for any type of controller. It is
built around L<Plack::Request> and L<Plack::Response> objects, allowing
subclasses to interactly directly with Plack.

Minima::Controller also keeps references to the L<Minima::App> and Plack
environment. Additionally, it retains data received from the router,
making it readily available to controllers.

Controllers may also define optional lifecycle hooks: C<before_action>
(to run checks before an action is executed) and C<after_action> (to run
logic after an action has completed). For details on how these hooks are
invoked during dispatch, see L<the C<run> method in
Minima::App|Minima::App/run>.

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

=head2 before_action

    method before_action ($method)

Optional hook that runs before the action method is invoked. It receives
the name of the action that is about to be executed.

If it returns a response, that response is immediately returned to the
client and the action itself will not run. If it returns nothing, the
normal action flow continues.

This is typically used for authentication, access control, or other
pre-conditions.

See also: L<Minima::App/run>.

=head2 after_action

    method after_action ($response)

Optional hook that runs after the action has completed. It receives the
response object returned by the action.

The return value of C<after_action> is ignored; any changes must be made
directly to the response object. This is typically used for logging,
instrumentation, or post-processing.

See also: L<Minima::App/run>.

=head2 json_body

    method json_body

Attempts to decode the request body as JSON. This method is useful for
controllers handling C<application/json> POST requests.

If the C<Content-Type> is not C<application/json>, the body is empty,
the declared C<Content-Length> is invalid, or the JSON cannot be parsed,
the method returns C<undef>. Otherwise, it returns the decoded Perl
structure (typically a hash or array reference).

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

=head2 trimmed_params

    method trimmed_params ($options = {})

Returns a new L<Hash::MultiValue> with decoded request parameters where
leading and trailing whitespace in values has been removed. Keys are
left unchanged. The original L<C<params>|/params> are not modified.
Array values are also trimmed element-wise.

Options:

=over 4

=item C<exclude>

Array reference of parameter names (strings) or regular expressions to
exclude from trimming. For example:

    my $params = $self->trimmed_params(
            { exclude => [ 'password', qr/^raw_/ ] }
        );

=back

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

The C<route> attribute contains the hash reference returned by
L<Minima::Router>. In addition to C<controller> and C<action>, it may
include named captures extracted from the URI pattern.

For example, given this route:

    GET  /blog/{post}   :Main    show_post

The action method can access the captured parameter directly:

    method show_post
    {
        my $id = $self->route->{post};
        ...
    }

These route parameters are separate from L<C<params>|/params>, which
holds decoded query string and POST parameters.

=item C<request>

Internal L<Plack::Request>

=item C<response>

Internal L<Plack::Response>

=item C<params>

Decoded GET and POST parameters merged in a L<Hash::MultiValue>. See
L<"Configuration"|/CONFIGURATION> to set the desired encoding.

Trimming whitespace is not performed automatically. If you need trimmed
parameters, call L<C<trimmed_params>|/trimmed_params>, which returns a
new L<Hash::MultiValue> with leading and trailing whitespace removed
from values (keys are untouched).

=back

=head1 SEE ALSO

L<Minima>, L<Minima::App>, L<Minima::Router>, L<Minima::View>,
L<Plack::Request>, L<Plack::Response>, L<perlclass>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
