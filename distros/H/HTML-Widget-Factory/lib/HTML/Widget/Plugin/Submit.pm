use strict;
use warnings;
package HTML::Widget::Plugin::Submit;
# ABSTRACT: for submit type inputs
$HTML::Widget::Plugin::Submit::VERSION = '0.204';
use parent 'HTML::Widget::Plugin::Input';

#pod =head1 SYNOPSIS
#pod
#pod   $widget_factory->submit({
#pod     id    => 'button-id', # will be used as default control name, too
#pod     value => 'button label',
#pod   });
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin provide a simple submit plugin, which returns an input element of
#pod type submit.
#pod
#pod =head1 METHODS
#pod
#pod =head2 C< provided_widgets >
#pod
#pod This plugin provides the following widgets: input
#pod
#pod =cut

sub provided_widgets { qw(submit) }

#pod =head2 C< submit >
#pod
#pod This method returns a basic submit input.
#pod
#pod In addition to the generic L<HTML::Widget::Plugin> attributes, the following
#pod are valid arguments:
#pod
#pod =over
#pod
#pod =item value
#pod
#pod This is the widget's initial value, which (for submit inputs) is generally used
#pod as the text for the label on its face.
#pod
#pod =back
#pod
#pod =cut

use HTML::Element;

sub submit {
  my ($self, $factory, $arg) = @_;

  $arg->{attr}{type} = 'submit';

  # I suppose I could carp, here, if the type is altered, but... it's your
  # foot, shoot it if you want. -- rjbs, 2007-02-28]

  $self->build($factory, $arg);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widget::Plugin::Submit - for submit type inputs

=head1 VERSION

version 0.204

=head1 SYNOPSIS

  $widget_factory->submit({
    id    => 'button-id', # will be used as default control name, too
    value => 'button label',
  });

=head1 DESCRIPTION

This plugin provide a simple submit plugin, which returns an input element of
type submit.

=head1 METHODS

=head2 C< provided_widgets >

This plugin provides the following widgets: input

=head2 C< submit >

This method returns a basic submit input.

In addition to the generic L<HTML::Widget::Plugin> attributes, the following
are valid arguments:

=over

=item value

This is the widget's initial value, which (for submit inputs) is generally used
as the text for the label on its face.

=back

=head1 AUTHOR

Ricardo SIGNES

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
