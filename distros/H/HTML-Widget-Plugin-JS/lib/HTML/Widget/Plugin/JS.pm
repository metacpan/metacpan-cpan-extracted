use strict;
use warnings;
package HTML::Widget::Plugin::JS;
$HTML::Widget::Plugin::JS::VERSION = '0.006';
# ABSTRACT: a JavaScript variable declaration emitter

use parent qw(HTML::Widget::Plugin);

use Data::JavaScript::Anon;

sub provided_widgets { qw(js_var js_vars js_anon) }

sub boolean_args {}
sub attribute_args {}

#pod =head2 js_var
#pod
#pod =head2 js_vars
#pod
#pod These are two names for the same widget.  Given a hashref, they will produce
#pod JavaScript code to assign the data in the hashref.
#pod
#pod In otherwords, this widget:
#pod
#pod   $fac->js_vars({
#pod     foo => { a => 1, b => 2 },
#pod     bar => [ 4, 2, 3 ],
#pod   });
#pod
#pod ...will be rendered something like this:
#pod
#pod   var foo = { a: 1, b: 2 };
#pod   var bar = [ 1, 2, 3 ];
#pod
#pod =cut

sub js_vars {
  my ($self, $factory, $arg) = @_;

  my $str =
    join "\n",
    map  { HTML::Widget::Plugin::JS::Encoder->var_dump($_ => $arg->{$_}) }
    keys %$arg;

  return $str;
}

BEGIN { *js_var = \&js_vars }

#pod =head2 js_anon
#pod
#pod This widget converts a given data structure to an anonymous JavaScript
#pod structure.  This basically just provides a widget factory interface to
#pod Data::JavaScript::Anon.
#pod
#pod It also escapes end-tag-like content in strings, using a JavaScript C<\u003c>
#pod form to avoid being interpreted as a real end tag in JavaScript embedded in
#pod HTML.
#pod
#pod Software is terrible.
#pod
#pod =cut

sub js_anon {
  my ($self, $factory, $arg) = @_;

  HTML::Widget::Plugin::JS::Encoder->anon_dump($arg);
}

{
  package
    HTML::Widget::Plugin::JS::Encoder;
  use parent 'Data::JavaScript::Anon';

  sub _escape {
    my ($self, $text) = @_;
    $text = $self->SUPER::_escape($text);
    $text =~ s/</\\u003c/g;
    return $text;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widget::Plugin::JS - a JavaScript variable declaration emitter

=head1 VERSION

version 0.006

=head2 js_var

=head2 js_vars

These are two names for the same widget.  Given a hashref, they will produce
JavaScript code to assign the data in the hashref.

In otherwords, this widget:

  $fac->js_vars({
    foo => { a => 1, b => 2 },
    bar => [ 4, 2, 3 ],
  });

...will be rendered something like this:

  var foo = { a: 1, b: 2 };
  var bar = [ 1, 2, 3 ];

=head2 js_anon

This widget converts a given data structure to an anonymous JavaScript
structure.  This basically just provides a widget factory interface to
Data::JavaScript::Anon.

It also escapes end-tag-like content in strings, using a JavaScript C<\u003c>
form to avoid being interpreted as a real end tag in JavaScript embedded in
HTML.

Software is terrible.

=head1 AUTHOR

Ricardo SIGNES

=head1 CONTRIBUTOR

=for stopwords Ricardo SIGNES

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
