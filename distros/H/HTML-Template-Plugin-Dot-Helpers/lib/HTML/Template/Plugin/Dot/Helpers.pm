package HTML::Template::Plugin::Dot::Helpers;
{
  $HTML::Template::Plugin::Dot::Helpers::VERSION = '0.06';
}

use warnings;
use strict;

use HTML::Template::Pluggable;
use HTML::Template::Plugin::Dot::Helpers::Number;

HTML::Template::Pluggable->add_trigger('before_output' => sub {
	my $self = shift;
	$self->param('Number' => HTML::Template::Plugin::Dot::Helpers::Number->new);
});

1; # End of HTML::Template::Plugin::Dot::Helpers

__END__

=head1 NAME

HTML::Template::Plugin::Dot::Helpers - Add useful objects to your templates

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use HTML::Template::Plugin::Dot::Helpers;

Then in your template, you can do:

  <tmpl_var Number.format_currency(orderitem.price)>
  
=head1 DESCRIPTION

This helper class adds some useful objects to your Dot-enabled templates (see
L<HTML::Template::Plugin::Dot>).

=head2 Added objects

=over 4

=item Number

An extended Number::Format object. See L<Number::Format> for documentation.
Note that only the object oriented methods are supported here.

I've added several generic numerical methods. Most (well, all in this release)
are boolean methods, useful in C<< <tmpl_if>s >>. They are: 

=over 8

=item equals - test whether two numbers are equal (==)

=item le, lt, ge, gt - test how two numbers compare

(implemented with <=, <, >=, > respectively)

=back

The following is not yet implemented.

=item String

Adds generic string testing functions similar to the above:

=over 8

=item equals - test whether two strings are equal (eq)

=item le, lt, ge, gt - test how two strings compare lexically

=back

=back

=head1 AUTHOR

Rhesa Rozendaal, C<< <rhesa@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-template-plugin-dot-helpers@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Template-Plugin-Dot-Helpers>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rhesa Rozendaal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
