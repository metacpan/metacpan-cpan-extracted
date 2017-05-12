use strict;
use warnings;
package HTML::Widget::Plugin::Link;
# ABSTRACT: a hyperlink
$HTML::Widget::Plugin::Link::VERSION = '0.204';
use parent 'HTML::Widget::Plugin';

#pod =head1 SYNOPSIS
#pod
#pod   $widget_factory->link({
#pod     text => "my favorite D&D pages",
#pod     href => 'http://rjbs.manxome.org/rubric/entries/tags/dnd',
#pod   });
#pod
#pod ...or...
#pod
#pod   $widget_factory->link({
#pod     html => "some <em>great<em> d&amp;d pages",
#pod     href => 'http://rjbs.manxome.org/rubric/entries/tags/dnd',
#pod   });
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin provides a basic input widget.
#pod
#pod =cut

use Carp ();
use HTML::Element;

#pod =head1 METHODS
#pod
#pod =head2 C< provided_widgets >
#pod
#pod This plugin provides the following widgets: link
#pod
#pod =cut

sub provided_widgets { qw(link) }

#pod =head2 C< link >
#pod
#pod This method returns a basic text hyperlink.
#pod
#pod In addition to the generic L<HTML::Widget::Plugin> attributes, the following
#pod are valid arguments:
#pod
#pod =over
#pod
#pod =item href
#pod
#pod This is the URI to which the link ... um ... links.  If no href is supplied, an
#pod exception is thrown.
#pod
#pod =item html
#pod
#pod =item text
#pod
#pod Either of these may contain the text of created link.  If passed as C<html>, it
#pod is not escaped; if passed as C<text>, it is.  If no text is supplied, the href
#pod is used.  If both options are provided, an exception is thrown.
#pod
#pod =back
#pod
#pod =cut

sub _attribute_args { qw(href title) }

sub link { ## no critic Builtin
  my ($self, $factory, $arg) = @_;

  $arg->{attr}{name} = $arg->{attr}{id} if not defined $arg->{attr}{name};

  Carp::croak "can't create a link without an href"
    unless $arg->{attr}{href};

  Carp::croak "text and html arguments for link widget are mutually exclusive"
    if $arg->{text} and $arg->{html};

  my $widget = HTML::Element->new('a');
  $widget->attr($_ => $arg->{attr}{$_}) for keys %{ $arg->{attr} };

  my $content;
  if ($arg->{html}) {
    $content = ref $arg->{html}
             ? $arg->{html}
             : HTML::Element->new('~literal' => text => $arg->{html});
  } else {
    $content = defined $arg->{text} ? $arg->{text} : $arg->{attr}{href};
  }

  $widget->push_content($content);

  # We chomp this to avoid significant whitespace. -- rjbs, 2008-09-22
  my $xml = $widget->as_XML;
  chomp $xml;
  return $xml;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widget::Plugin::Link - a hyperlink

=head1 VERSION

version 0.204

=head1 SYNOPSIS

  $widget_factory->link({
    text => "my favorite D&D pages",
    href => 'http://rjbs.manxome.org/rubric/entries/tags/dnd',
  });

...or...

  $widget_factory->link({
    html => "some <em>great<em> d&amp;d pages",
    href => 'http://rjbs.manxome.org/rubric/entries/tags/dnd',
  });

=head1 DESCRIPTION

This plugin provides a basic input widget.

=head1 METHODS

=head2 C< provided_widgets >

This plugin provides the following widgets: link

=head2 C< link >

This method returns a basic text hyperlink.

In addition to the generic L<HTML::Widget::Plugin> attributes, the following
are valid arguments:

=over

=item href

This is the URI to which the link ... um ... links.  If no href is supplied, an
exception is thrown.

=item html

=item text

Either of these may contain the text of created link.  If passed as C<html>, it
is not escaped; if passed as C<text>, it is.  If no text is supplied, the href
is used.  If both options are provided, an exception is thrown.

=back

=head1 AUTHOR

Ricardo SIGNES

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
