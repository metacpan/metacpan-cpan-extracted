package HTML::Widget::JavaScript;

use warnings;
use strict;

use base 'HTML::Widget';

use HTML::Widget::JavaScript::Result;

=head1 NAME

HTML::Widget::JavaScript - Adds JavaScript validation to HTML::Widget

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 UNMAINTAINED MODULE

B<This module is unmaintained.>

B<No future updates are planned at this time. You have been warned.>

=head1 SYNOPSIS

This module adds JavaScript field validation for L<HTML::Widget> objects.

When a JavaScript checked constraint fails, an alert box with the given error
message (set by the C<message()> constraint method) is displayed.

Currently, these constraints are implemented in JavaScript: All, AllOrNone, Any,
ASCII, Email (simplified), Equal, HTTP, In, Integer, Length, Printable, Range 
and String.

In other words, these constraints are missing: Date, DateTime, Time and Regex.
Note that, although JavaScript support is missing, they will continue to work
using server-side validation.

=head1 METHODS

See L<HTML::Widget>.

=cut

*result = \&process;

=head2 $self->result( $query, $uploads )

=head2 $self->process( $query, $uploads )

After finishing setting up the widget and all its elements, call either 
C<process()> or C<result()> to create an L<HTML::Widget::JavaScript::Result>. 
If passed a C<$query> it will run filters and validation on the parameters. 
The Result object can then be used to produce the HTML.

=cut

sub process {
	my ( $self, $query, $uploads ) = @_;
	bless $self->SUPER::process($query, $uploads), 'HTML::Widget::JavaScript::Result';
}

sub _instantiate {
    my ( $self, $class, @args ) = @_;

	(my $js_class = $class) =~ s/HTML::Widget/HTML::Widget::JavaScript/;
    eval "require $js_class";
    if ($@) {
		return $self->SUPER::_instantiate($class, @args);
	}

    return $js_class->new(@args);
}

=head1 TODO

Implement the missing constraints.

Maybe add support for altering the error displaying behaviour (e.g. instead of
using alert(), maybe we could fill the error span with the error messages 
directly through JavaScript).

=head1 AUTHOR

Nilson Santos Figueiredo Júnior, C<< <nilsonsfj at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests directly to the author.
If you ask nicely it will probably get fixed or implemented.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::Widget::JavaScript

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-Widget-JavaScript>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-Widget-JavaScript>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-Widget-JavaScript>

=back

=head1 SEE ALSO

L<HTML::Widget>

=head1 COPYRIGHT & LICENSE

Copyright 2006, 2009 Nilson Santos Figueiredo Júnior, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::Widget::JavaScript
