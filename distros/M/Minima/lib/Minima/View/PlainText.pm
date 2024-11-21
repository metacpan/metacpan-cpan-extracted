use v5.40;
use experimental 'class';

use utf8;

class Minima::View::PlainText :isa(Minima::View);

method prepare_response ($response)
{
    $response->content_type('text/plain; charset=utf-8');
}

method render ($data = '')
{
    utf8::encode($data);
    $data;
}

__END__

=head1 NAME

Minima::View::PlainText - Render plain text views

=head1 SYNOPSIS

    use Minima::View::JSON;

    my $view = Minima::View::PlainText->new;
    $view->prepare_response($response);

    my $body = $view->render("hello, world\n");

=head1 DESCRIPTION

Minima::View::PlainText provides a utility view for generating plain  
text responses, following the same conventions as other native Minima
views.

B<Note:> Minima::View::PlainText encodes strings as UTF-8.

=head1 METHODS

=head2 new

    method new ()

Creates a new instance of the class. This method does not require any
arguments.

=head2 prepare_response

    method prepare_response ($response)

Sets the appropriate I<Content-Type> header on the provided
L<Plack::Response> object.

=head2 render

    method render ($data = '')

Encodes the provided string as UTF-8 and returns it.

=head1 SEE ALSO

L<Minima>, L<Minima::Controller>, L<Minima::View>, L<perlclass>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in November 2024.
