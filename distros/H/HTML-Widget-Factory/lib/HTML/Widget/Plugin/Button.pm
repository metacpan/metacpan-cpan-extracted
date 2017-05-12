use strict;
use warnings;
package HTML::Widget::Plugin::Button;
# ABSTRACT: a button for clicking
$HTML::Widget::Plugin::Button::VERSION = '0.204';
use parent 'HTML::Widget::Plugin';

#pod =head1 SYNOPSIS
#pod
#pod   $widget_factory->button({
#pod     text => "submit & continue",
#pod     type => 'submit',
#pod   });
#pod
#pod ...or...
#pod
#pod   $widget_factory->button({
#pod     html => "reset <em>all</em> content",
#pod     type => 'reset',
#pod   });
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin provides a basic button widget.
#pod
#pod =cut

use HTML::Element;

#pod =head1 METHODS
#pod
#pod =head2 C< provided_widgets >
#pod
#pod This plugin provides the following widgets: input
#pod
#pod =cut

sub provided_widgets { qw(button) }

#pod =head2 C< button >
#pod
#pod This method returns simple button element.
#pod
#pod In addition to the generic L<HTML::Widget::Plugin> attributes, the following
#pod are valid arguments:
#pod
#pod =over
#pod
#pod =item text
#pod
#pod =item html
#pod
#pod One of these options may be provided.  If text is provided, it is used as the
#pod content of the button, after being entity encoded.  If html is provided, it is
#pod used as the content of the button with no encoding performed.
#pod
#pod =item type
#pod
#pod This is the type of input button to be created.  Valid types are button,
#pod submit, and reset.  The default is button.
#pod
#pod =item value
#pod
#pod This is the widget's initial value.
#pod
#pod =back
#pod
#pod =cut

sub _attribute_args { qw(type value) }
sub _boolean_args   { qw(disabled) }

sub button {
  my ($self, $factory, $arg) = @_;

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

my %TYPES = map { $_ => 1 } qw(button reset submit);
sub __is_valid_type {
  my ($self, $type) = @_;

  return exists $TYPES{ $type };
}

sub build {
  my ($self, $factory, $arg) = @_;

  $arg->{attr}{name} = $arg->{attr}{id} if not defined $arg->{attr}{name};
  $arg->{attr}{type} ||= 'button';

  Carp::croak "invalid button type: $arg->{attr}{type}"
    unless $self->__is_valid_type($arg->{attr}{type});

  Carp::croak "text and html arguments for link widget are mutually exclusive"
    if $arg->{text} and $arg->{html};

  my $widget = HTML::Element->new('button');
  $widget->attr($_ => $arg->{attr}{$_}) for keys %{ $arg->{attr} };

  my $content;
  if ($arg->{html}) {
    $content = ref $arg->{html}
             ? $arg->{html}
             : HTML::Element->new('~literal' => text => $arg->{html});
  } else {
    $content = defined $arg->{text}
             ? $arg->{text}
             : ucfirst lc $arg->{attr}{type};
  }

  $widget->push_content($content);

  return $widget->as_XML;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widget::Plugin::Button - a button for clicking

=head1 VERSION

version 0.204

=head1 SYNOPSIS

  $widget_factory->button({
    text => "submit & continue",
    type => 'submit',
  });

...or...

  $widget_factory->button({
    html => "reset <em>all</em> content",
    type => 'reset',
  });

=head1 DESCRIPTION

This plugin provides a basic button widget.

=head1 METHODS

=head2 C< provided_widgets >

This plugin provides the following widgets: input

=head2 C< button >

This method returns simple button element.

In addition to the generic L<HTML::Widget::Plugin> attributes, the following
are valid arguments:

=over

=item text

=item html

One of these options may be provided.  If text is provided, it is used as the
content of the button, after being entity encoded.  If html is provided, it is
used as the content of the button with no encoding performed.

=item type

This is the type of input button to be created.  Valid types are button,
submit, and reset.  The default is button.

=item value

This is the widget's initial value.

=back

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
