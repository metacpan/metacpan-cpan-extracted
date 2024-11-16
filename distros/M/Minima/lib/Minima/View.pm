use v5.40;
use experimental 'class';

class Minima::View;

use Carp;

method render
{
    carp "Base view render called.";
    "hello, world\n";
}

__END__

=head1 NAME

Minima::View - Base class for views used with Minima

=head1 DESCRIPTION

This class serves as a base for views used with L<Minima>. It is not
intended to be used directly but rather to be subclassed.

It currently implements a single method: C<render>, which should not be
called on this base class. (Perhaps, with roles in Perl core in the
future, this class might become unnecessary.)

For HTML views, see L<Minima::View::HTML>.

=head1 METHODS

=head2 new

Constructs a new object. No arguments required.

=head2 render

Renders content, and should not be called on this base class.

=head1 SEE ALSO

L<Minima>, L<Minima::View::HTML>, L<perlclass>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
