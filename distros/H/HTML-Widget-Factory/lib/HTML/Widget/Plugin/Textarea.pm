use strict;
use warnings;
package HTML::Widget::Plugin::Textarea;
# ABSTRACT: a widget for a large text entry box
$HTML::Widget::Plugin::Textarea::VERSION = '0.204';
use parent 'HTML::Widget::Plugin';

#pod =head1 SYNOPSIS
#pod
#pod   $widget_factory->textarea({
#pod     id    => 'elem-id', # also used as control name, if no name given
#pod     value => $big_hunk_of_text,
#pod   });
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin provides a text-entry area widget.
#pod
#pod The C<default_classes> attribute may be used to add a default class to every
#pod produced input.  This class cannot be overridden.
#pod
#pod   my $plugin = HTML::Widget::Factory::Input->new({
#pod     default_classes => [ qw(foo bar) ],
#pod   });
#pod
#pod =head1 METHODS
#pod
#pod =head2 C< provided_widgets >
#pod
#pod This plugin provides the following widgets: textarea
#pod
#pod =cut

sub provided_widgets { qw(textarea) }

#pod =head2 C< textarea >
#pod
#pod This method returns a text-entry area widget.
#pod
#pod In addition to the generic L<HTML::Widget::Plugin> attributes, the following
#pod are valid arguments:
#pod
#pod =over
#pod
#pod =item disabled
#pod
#pod If true, this option indicates that the widget can't be changed by the user.
#pod
#pod =item value
#pod
#pod If this argument is given and defined, the widget will be initially populated
#pod by its value.
#pod
#pod =back
#pod
#pod =cut

use HTML::Element;

sub _attribute_args { qw(disabled id) }
sub _boolean_args   { qw(disabled) }

sub textarea {
  my ($self, $factory, $arg) = @_;

  $arg->{attr}{name} = $arg->{attr}{id} if not defined $arg->{attr}{name};

  my $widget = HTML::Element->new('textarea');

  $widget->attr($_ => $arg->{attr}{$_})
    for grep {; defined $arg->{attr}{$_} } keys %{ $arg->{attr} };

  $widget->push_content($arg->{value}) if defined $arg->{value};

  return $widget->as_XML;
}

sub rewrite_arg {
  my ($self, $arg, @rest) = @_;

  $arg = $self->SUPER::rewrite_arg($arg, @rest);

  if ($self->{default_classes}) {
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

HTML::Widget::Plugin::Textarea - a widget for a large text entry box

=head1 VERSION

version 0.204

=head1 SYNOPSIS

  $widget_factory->textarea({
    id    => 'elem-id', # also used as control name, if no name given
    value => $big_hunk_of_text,
  });

=head1 DESCRIPTION

This plugin provides a text-entry area widget.

The C<default_classes> attribute may be used to add a default class to every
produced input.  This class cannot be overridden.

  my $plugin = HTML::Widget::Factory::Input->new({
    default_classes => [ qw(foo bar) ],
  });

=head1 METHODS

=head2 C< provided_widgets >

This plugin provides the following widgets: textarea

=head2 C< textarea >

This method returns a text-entry area widget.

In addition to the generic L<HTML::Widget::Plugin> attributes, the following
are valid arguments:

=over

=item disabled

If true, this option indicates that the widget can't be changed by the user.

=item value

If this argument is given and defined, the widget will be initially populated
by its value.

=back

=head1 AUTHOR

Ricardo SIGNES

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
