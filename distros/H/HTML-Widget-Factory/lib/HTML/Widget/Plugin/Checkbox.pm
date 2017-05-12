use strict;
use warnings;
package HTML::Widget::Plugin::Checkbox;
# ABSTRACT: it's either [ ] or [x]
$HTML::Widget::Plugin::Checkbox::VERSION = '0.204';
use parent 'HTML::Widget::Plugin';

#pod =head1 SYNOPSIS
#pod
#pod   $widget_factory->checkbox({
#pod     id      => 'checkbox-id',    # also used as default for control name
#pod     value   => 'checkbox-value', # -not- the "am I checked?" setting
#pod     checked => $true_or_false,
#pod   });
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin provides a widget for boolean checkbox widgets.
#pod
#pod =cut

use HTML::Element;

#pod =head1 METHODS
#pod
#pod =head2 C< provided_widgets >
#pod
#pod This plugin provides the following widgets: checkbox
#pod
#pod =cut

sub provided_widgets { qw(checkbox) }

#pod =head2 C< checkbox >
#pod
#pod This method returns a checkbox widget.
#pod
#pod In addition to the generic L<HTML::Widget::Plugin> attributes, the following
#pod are valid arguments:
#pod
#pod =over
#pod
#pod =item checked
#pod
#pod This is the widget's initial state.  If true, the checkbox is checked.
#pod Otherwise, it is not.
#pod
#pod =item value
#pod
#pod This is the value for the checkbox, not to be confused with whether or not it
#pod is checked.
#pod
#pod =back
#pod
#pod =cut

sub _attribute_args { qw(checked disabled value) }
sub _boolean_args   { qw(checked disabled) }

sub checkbox {
  my ($self, $factory, $arg) = @_;

  $arg->{attr}{type} = 'checkbox';

  $arg->{attr}{name} = $arg->{attr}{id} if not defined $arg->{attr}{name};

  my $widget = HTML::Element->new('input');

  $widget->attr($_ => $arg->{attr}{$_}) for keys %{ $arg->{attr} };
  return $widget->as_XML;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widget::Plugin::Checkbox - it's either [ ] or [x]

=head1 VERSION

version 0.204

=head1 SYNOPSIS

  $widget_factory->checkbox({
    id      => 'checkbox-id',    # also used as default for control name
    value   => 'checkbox-value', # -not- the "am I checked?" setting
    checked => $true_or_false,
  });

=head1 DESCRIPTION

This plugin provides a widget for boolean checkbox widgets.

=head1 METHODS

=head2 C< provided_widgets >

This plugin provides the following widgets: checkbox

=head2 C< checkbox >

This method returns a checkbox widget.

In addition to the generic L<HTML::Widget::Plugin> attributes, the following
are valid arguments:

=over

=item checked

This is the widget's initial state.  If true, the checkbox is checked.
Otherwise, it is not.

=item value

This is the value for the checkbox, not to be confused with whether or not it
is checked.

=back

=head1 AUTHOR

Ricardo SIGNES

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
