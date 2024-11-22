use v5.40;
use experimental 'class';

class Minima::View::JSON :isa(Minima::View);

use JSON;

field $app :param;

method prepare_response ($response)
{
    $response->content_type('application/json');
}

method render ($data = {})
{
    $app->development
        ? JSON->new->utf8->pretty->encode($data)
        : encode_json $data
        ;
}

__END__

=head1 NAME

Minima::View::JSON - Render JSON views

=head1 SYNOPSIS

    use Minima::View::JSON;

    my $view = Minima::View::JSON->new(app => $app);
    my $body = $view->render({ data => ... });

=head1 DESCRIPTION

Minima::View::JSON provides a view for generating JSON responses.
Internally, it  utilizes L<JSON> to convert data structures into valid
JSON strings. While the  installation of L<JSON::XS> is not mandatory,
it is highly recommended for better performance.

B<Note:> Minima::View::JSON encodes data as UTF-8.

=head1 METHODS

=head2 new

    method new (app)

Creates a new instance of the class. Expects a L<Minima::App> object as
the C<app> parameter.

=head2 prepare_response

    method prepare_response ($response)

Sets the appropriate I<Content-Type> header on the provided
L<Plack::Response> object.

=head2 render

    method render ($data = {})

Converts the given data structure into a JSON string and returns the
result.

=head1 SEE ALSO

L<Minima>, L<Minima::Controller>, L<Minima::View>, L<perlclass>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in November 2024.
