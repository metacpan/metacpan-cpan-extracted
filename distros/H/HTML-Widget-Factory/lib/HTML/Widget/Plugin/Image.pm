use strict;
use warnings;
package HTML::Widget::Plugin::Image;
# ABSTRACT: an image object
$HTML::Widget::Plugin::Image::VERSION = '0.204';
use parent 'HTML::Widget::Plugin';

#pod =head1 SYNOPSIS
#pod
#pod   $widget_factory->image({
#pod     src => 'http://example.com/example.jpg',
#pod     alt => 'An Example Image',
#pod   });
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin provides a basic image widget.
#pod
#pod =cut

use Carp ();
use HTML::Element;

#pod =head1 METHODS
#pod
#pod =head2 C< provided_widgets >
#pod
#pod This plugin provides the following widgets: image
#pod
#pod =cut

sub provided_widgets { qw(image) }

#pod =head2 C< image >
#pod
#pod This method returns a basic image element.
#pod
#pod In addition to the generic L<HTML::Widget::Plugin> attributes, the following
#pod are valid arguments:
#pod
#pod =over
#pod
#pod =item src
#pod
#pod This is the source href for the image.  "href" is a synonym for src.  If no
#pod href is supplied, an exception is thrown.
#pod
#pod =item alt
#pod
#pod This is the alt text for the image.
#pod
#pod =back
#pod
#pod =cut

sub _attribute_args { qw(src alt) }

sub image {
  my ($self, $factory, $arg) = @_;

  if ($arg->{attr}{src} and $arg->{href}) {
    Carp::croak "don't provide both href and src for image widget";
  }

  $arg->{attr}{src} = $arg->{href} if not defined $arg->{attr}{src};

  Carp::croak "can't create an image without a src"
    unless defined $arg->{attr}{src};

  my $widget = HTML::Element->new('img');
  $widget->attr($_ => $arg->{attr}{$_}) for keys %{ $arg->{attr} };

  return $widget->as_XML;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widget::Plugin::Image - an image object

=head1 VERSION

version 0.204

=head1 SYNOPSIS

  $widget_factory->image({
    src => 'http://example.com/example.jpg',
    alt => 'An Example Image',
  });

=head1 DESCRIPTION

This plugin provides a basic image widget.

=head1 METHODS

=head2 C< provided_widgets >

This plugin provides the following widgets: image

=head2 C< image >

This method returns a basic image element.

In addition to the generic L<HTML::Widget::Plugin> attributes, the following
are valid arguments:

=over

=item src

This is the source href for the image.  "href" is a synonym for src.  If no
href is supplied, an exception is thrown.

=item alt

This is the alt text for the image.

=back

=head1 AUTHOR

Ricardo SIGNES

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
