use v5.40;
use experimental 'class';

class Minima::View;

use Carp;

method render
{
    carp "Base view render called.";
    "hello, world\n";
}

method prepare_response ($response)
{
    carp "Base view prepare_response` called.";
    undef;
}

__END__

=head1 NAME

Minima::View - Base class for views used with Minima

=head1 DESCRIPTION

This class serves as a base for views used with L<Minima>. It is not
intended to be used directly but rather to be subclassed.

It currently implements two methods: L<C<render>|/render> and
L<C<prepare_response>|/prepare_response>, which should not be called on
this base class. (Perhaps, with roles in Perl core in the future, this
class might become unnecessary.)

=head2 Subclasses

These views are built into Minima by default:

=over 4

=item L<Minima::View::HTML>

For rendering HTML content, includes utility methods.

=item L<Minima::View::JSON>

For creating JSON responses.

=item L<Minima::View::PlainText>

For plain text output.

=back

For HTML views, see L<Minima::View::HTML>. For JSON, see
L<Minima::View::JSON>.

=head1 METHODS

=head2 new

    method new ()

Constructs a new object. No arguments required.

=head2 prepare_response

    method prepare_response ($response)

Prepares the provided L<Plack::Response> object for finalizing.
Subclasses may use this method to set the I<Content-Type> header, for
example.

=head2 render

Renders content, and should not be called on this base class.

=head1 SEE ALSO

L<Minima>, L<Minima::View::HTML>, L<perlclass>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
