use strict;
use warnings;
package HTML::Widget::Plugin::Multiselect;
# ABSTRACT: widget for multiple selections from a list
$HTML::Widget::Plugin::Multiselect::VERSION = '0.204';
use parent 'HTML::Widget::Plugin::Select';

#pod =head1 SYNOPSIS
#pod
#pod   $widget_factory->multiselect({
#pod     id      => 'multiopts', # if no name attr given, defaults to id value
#pod     size    => 3,
#pod     values  => [ 'value_1', 'value_3' ],
#pod     options => [
#pod       [ value_1 => 'Display Name 1' ],
#pod       [ value_2 => 'Display Name 2' ],
#pod       [ value_3 => 'Display Name 3' ],
#pod     ],
#pod   });
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin provides a select-from-list widget that allows the selection of
#pod multiple elements.
#pod
#pod =cut

use HTML::Element;

#pod =head1 METHODS
#pod
#pod =head2 C< provided_widgets >
#pod
#pod This plugin provides the following widgets: multiselect
#pod
#pod =cut

sub provided_widgets { qw(multiselect) }

#pod =head2 C< multiselect >
#pod
#pod This method returns a multiple-selection-from-list widget.  Yup.
#pod
#pod In addition to the generic L<HTML::Widget::Plugin> attributes and the
#pod L<HTML::Widget::Plugin::Select> attributes, the following are valid arguments:
#pod
#pod =over
#pod
#pod =item size
#pod
#pod This is the number of elements that should be visible in the widget.
#pod
#pod =back
#pod
#pod =cut

sub _attribute_args { qw(size) }

sub multiselect {
  my ($self, $factory, $arg) = @_;

  $arg->{attr}{name} = $arg->{attr}{id} if not defined $arg->{attr}{name};
  $arg->{attr}{multiple} = 'multiple';

  if ($arg->{values}) {
    $arg->{value} = delete $arg->{values};
  }

  $self->build($factory, $arg);
}

#pod =head2 C< make_option >
#pod
#pod This method, subclassed from the standard select widget, expects that C<$value>
#pod will be an array of selected values.
#pod
#pod =cut

sub make_option {
  my ($self, $factory, $value, $name, $arg, $opt_arg) = @_;

  my $option = HTML::Element->new('option', value => $value);
     $option->push_content($name);
     $option->attr(disabled => 'disabled') if $opt_arg && $opt_arg->{disabled};
     $option->attr(selected => 'selected')
       if $arg->{value} and grep { $_ eq $value } @{ $arg->{value} };

  return $option;
}

#pod =head2 C< validate_value >
#pod
#pod This method checks whether the given value option is valid.  It throws an
#pod exception if the given values are not all in the list of options.
#pod
#pod =cut

sub validate_value {
  my ($class, $values, $options) = @_;

  $values = [ $values ] unless ref $values;
  return unless grep { defined } @$values;

  for my $value (@$values) {
    my $matches = grep { $value eq $_ } map { ref $_ ? $_->[0] : $_ } @$options;
    Carp::croak "provided value '$value' not in given options" unless $matches;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widget::Plugin::Multiselect - widget for multiple selections from a list

=head1 VERSION

version 0.204

=head1 SYNOPSIS

  $widget_factory->multiselect({
    id      => 'multiopts', # if no name attr given, defaults to id value
    size    => 3,
    values  => [ 'value_1', 'value_3' ],
    options => [
      [ value_1 => 'Display Name 1' ],
      [ value_2 => 'Display Name 2' ],
      [ value_3 => 'Display Name 3' ],
    ],
  });

=head1 DESCRIPTION

This plugin provides a select-from-list widget that allows the selection of
multiple elements.

=head1 METHODS

=head2 C< provided_widgets >

This plugin provides the following widgets: multiselect

=head2 C< multiselect >

This method returns a multiple-selection-from-list widget.  Yup.

In addition to the generic L<HTML::Widget::Plugin> attributes and the
L<HTML::Widget::Plugin::Select> attributes, the following are valid arguments:

=over

=item size

This is the number of elements that should be visible in the widget.

=back

=head2 C< make_option >

This method, subclassed from the standard select widget, expects that C<$value>
will be an array of selected values.

=head2 C< validate_value >

This method checks whether the given value option is valid.  It throws an
exception if the given values are not all in the list of options.

=head1 AUTHOR

Ricardo SIGNES

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
