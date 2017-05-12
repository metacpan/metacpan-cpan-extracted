use strict;
use warnings;
package HTML::Widget::Plugin::Input;
# ABSTRACT: the most basic input widget
$HTML::Widget::Plugin::Input::VERSION = '0.204';
use parent 'HTML::Widget::Plugin';

#pod =head1 SYNOPSIS
#pod
#pod   $widget_factory->input({
#pod     id    => 'flavor',   # if "name" isn't given, id will be used for name
#pod     size  => 25,
#pod     value => $default_flavor,
#pod   });
#pod
#pod ...or...
#pod
#pod   $widget_factory->hidden({
#pod     id    => 'flavor',   # if "name" isn't given, id will be used for name
#pod     value => $default_flavor,
#pod   });
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin provides a basic input widget.
#pod
#pod The C<default_classes> attribute may be used to add a default class to every
#pod produced input.  This class cannot be overridden.
#pod
#pod   my $plugin = HTML::Widget::Factory::Input->new({
#pod     default_classes => [ qw(foo bar) ],
#pod   });
#pod
#pod =cut

use HTML::Element;

#pod =head1 METHODS
#pod
#pod =head2 C< provided_widgets >
#pod
#pod This plugin provides the following widgets: input, hidden
#pod
#pod =cut

sub provided_widgets { qw(input hidden) }

#pod =head2 C< input >
#pod
#pod This method returns a basic one-line text-entry widget.
#pod
#pod In addition to the generic L<HTML::Widget::Plugin> attributes, the following
#pod are valid arguments:
#pod
#pod =over
#pod
#pod =item value
#pod
#pod This is the widget's initial value.
#pod
#pod =item type
#pod
#pod This is the type of input widget to be created.  You may wish to use a
#pod different plugin, instead.
#pod
#pod =back
#pod
#pod =cut

sub _attribute_args { qw(disabled type value size maxlength) }
sub _boolean_args   { qw(disabled) }

sub input {
  my ($self, $factory, $arg) = @_;

  $self->build($factory, $arg);
}

#pod =head2 C< hidden >
#pod
#pod This method returns a hidden input that is not displayed in the rendered HTML.
#pod Its arguments are the same as those to C<input>.
#pod
#pod This method may later be factored out into a plugin.
#pod
#pod =cut

sub hidden {
  my ($self, $factory, $arg) = @_;

  $arg->{attr}{type} = 'hidden';

  $self->build($factory, $arg);
}

#pod =head2 C< build >
#pod
#pod   my $widget = $class->build($factory, $arg);
#pod
#pod This method does the actual construction of the input based on the args
#pod collected by the widget-constructing method.  It is primarily here for
#pod subclasses to exploit.
#pod
#pod =cut

sub build {
  my ($self, $factory, $arg) = @_;

  $arg->{attr}{name} = $arg->{attr}{id} unless defined $arg->{attr}{name};

  my $widget = HTML::Element->new('input');

  $widget->attr($_ => $arg->{attr}{$_}) for keys %{ $arg->{attr} };
  return $widget->as_XML;
}

sub rewrite_arg {
  my ($self, $arg, $method) = @_;

  $arg = $self->SUPER::rewrite_arg($arg);

  if ($self->{default_classes} && $method ne 'hidden') {
    my $class = join q{ }, @{ $self->{default_classes} };
    $arg->{attr}{class} = defined $arg->{attr}{class}
      ? "$class $arg->{attr}{class}"
      : $class;
  }

  return $arg;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widget::Plugin::Input - the most basic input widget

=head1 VERSION

version 0.204

=head1 SYNOPSIS

  $widget_factory->input({
    id    => 'flavor',   # if "name" isn't given, id will be used for name
    size  => 25,
    value => $default_flavor,
  });

...or...

  $widget_factory->hidden({
    id    => 'flavor',   # if "name" isn't given, id will be used for name
    value => $default_flavor,
  });

=head1 DESCRIPTION

This plugin provides a basic input widget.

The C<default_classes> attribute may be used to add a default class to every
produced input.  This class cannot be overridden.

  my $plugin = HTML::Widget::Factory::Input->new({
    default_classes => [ qw(foo bar) ],
  });

=head1 METHODS

=head2 C< provided_widgets >

This plugin provides the following widgets: input, hidden

=head2 C< input >

This method returns a basic one-line text-entry widget.

In addition to the generic L<HTML::Widget::Plugin> attributes, the following
are valid arguments:

=over

=item value

This is the widget's initial value.

=item type

This is the type of input widget to be created.  You may wish to use a
different plugin, instead.

=back

=head2 C< hidden >

This method returns a hidden input that is not displayed in the rendered HTML.
Its arguments are the same as those to C<input>.

This method may later be factored out into a plugin.

=head2 C< build >

  my $widget = $class->build($factory, $arg);

This method does the actual construction of the input based on the args
collected by the widget-constructing method.  It is primarily here for
subclasses to exploit.

=head1 AUTHOR

Ricardo SIGNES

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
