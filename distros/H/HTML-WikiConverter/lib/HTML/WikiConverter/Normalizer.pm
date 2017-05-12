package HTML::WikiConverter::Normalizer;

use warnings;
use strict;

use Carp;

use CSS;
use HTML::Element;

=head1 NAME

HTML::WikiConverter::Normalizer - Convert CSS styles to (roughly) corresponding HTML

=head1 SYNOPSIS

  use HTML::TreeBuilder;
  use HTML::WikiConverter::Normalizer;

  my $tree = new HTML::TreeBuilder();
  $tree->parse( '<p><font style="font-style:italic; font-weight:bold">text</font></p>' );

  my $norm = new HTML::WikiConverter::Normalizer();
  $norm->normalize($tree);

  # Roughly gives "<p><font><b><i>text</i></b></font></p>"
  print $tree->as_HTML();

=head1 DESCRIPTION

L<HTML::WikiConverter> dialects convert HTML into wiki markup. Most
(if not all) know nothing about CSS, nor do they take it into
consideration when performing html-to-wiki conversion. But there is no
good reason for, say, C<E<lt>font
style="font-weight:bold"E<gt>textE<lt>/fontE<gt>> not to be converted
into C<'''text'''> in the MediaWiki dialect. The same is true of other
dialects, all of which should be able to use CSS information to
produce wiki markup.

The issue becomes especially problematic when considering that several
WYSIWYG HTML editors (e.g. Mozilla's) produce this sort of CSS-heavy
HTML. Prior to C<HTML::WikiConverter::Normalizer>, this HTML would
have been essentially converted to text, the CSS information having
been ignored by C<HTML::WikiConverter>.

C<HTML::WikiConverter::Normalizer> avoids this with a few simple
transformations that convert CSS styles into HTML tags.

=head1 METHODS

=head2 new

  my $norm = new HTML::WikiConverter::Normalizer();

Constructs a new normalizer

=cut

sub new {
  my( $pkg, %attrs ) = @_;
  my $self = bless \%attrs, $pkg;
  $self->{_css} = new CSS( { parser => 'CSS::Parse::Lite' } );
  $self->{_handlers} = $self->handlers;
  return $self;
}

=head2 normalize

  $norm->normalize($elem);

Normalizes C<$elem> and all its descendents, where C<$elem> is an
L<HTML::Element> object.

=cut

sub normalize {
  my( $self, $root ) = @_;
  $self->_normalize($root);
  $self->_postprocess($root);
}

=head1 SUBCLASSING

The following methods may be useful to subclasses.

=cut

sub _css { shift->{_css} }
sub _handlers { shift->{_handlers} }

=head2 handlers

  my $handlers = $self->handlers;

Class method returning reference to an array of handlers used to
convert CSS to HTML. Each handler is a hashref that specifies the CSS
properties and values to match, and the HTML tags and attributes the
matched properties will be converted to.

The C<type>, C<name>, C<value>, and C<tag> keys may be used to match
an element's property or attribute. C<type> may be either C<"css"> if
matching a CSS property (in which case C<name> must contain the name
of the property, and C<value> must contain the property value to
match) or C<"attr"> if matching an HTML tag attribute (in which case
C<name> must contain the name of the attribute, and C<value> must
contain the attribute value to match).

C<value> may be a string (for an exact match), regex (which will be
used to match against the element's property or attribute value),
coderef (which will be passed the property or attribute value and is
expected to return true on match, false otherwise), or C<"*"> (which
matches any property or attribute value). A tag or list of tags can
also be matched with the C<tag> key, which takes either a string or an
arrayref.

To specify what actions the handler will take, the C<new_tag>,
C<new_attr>, and C<normalizer> keys are used. C<new_tag> is required
and indicates the name of the tag that will be created. C<attribute>
is optional and indicates the name of the attribute in the new tag
that will take the value of the original CSS property. If a coderef is
given as the C<normalizer>, it will be passed the value of the
property/attribute and should return one suitable to be assigned to
the new tag attribute.

=cut

sub handlers { [
  { type => 'css',  name => 'font-family', value => '*', new_tag => 'font', new_attr => 'face' },
  { type => 'css',  name => 'font-size', value => '*', new_tag => 'font', new_attr => 'size', normalizer => \&_normalize_fontsize },
  { type => 'css',  name => 'color', value => '*', new_tag => 'font', new_attr => 'color', normalizer => \&_normalize_color },
  { type => 'css',  name => 'font-weight', value => 'bold', new_tag => 'b' },
  { type => 'css',  name => 'text-decoration', value => 'underline', new_tag => 'u' },
  { type => 'css',  name => 'font-style', value => 'italic', new_tag => 'i' },
  { type => 'attr', name => 'align', value => 'center', tag => [ qw/ div p / ], new_tag => 'center' },

#  { type => 'attr', tag =>  'font', attr => 'size', value => '*', new_tag => 'span', style => 'font-size' },
] }

sub _new_handlers {
  span_to_font => {
    xpath => '//[@style[contains(., "font-size")]]',
  },
}

sub _normalize_color {
  my( $self, $color ) = @_;
  return $color;
}

sub _normalize_fontsize {
  my( $self, $size ) = @_;
  return $size;
}

sub _normalize {
  my( $self, $node ) = @_;
  $self->_normalize_css( $node );
  $self->_normalize_attrs( $node );
}

sub _normalize_css {
  my( $self, $node ) = @_;

  $node->objectify_text;

  # Recurse
  $self->_normalize_css($_) for $node->content_list;

  my $style_text = $node->attr('style') or return;
  my $full_css = "this { $style_text }";

  $self->_css->read_string( $full_css );
  my $style = $self->_css->get_style_by_selector('this');

  my @original_props = @{ $style->{properties} || [] };
  my @new_props = ( );

  foreach my $prop ( @original_props ) {
    my $handler = $self->_find_handler( type => 'css', name => $prop->{property}, value => $prop->{simple_value}, tag => $node->tag );
    if( $handler ) {
      $self->_handle( $handler, $node, $prop->{simple_value} );
    } else {
      push @new_props, $prop;
    }
  }

  $style->{properties} = \@new_props;
  chomp( my $style_string = $style->to_string );
  $style_string =~ s/^this \{\s*(.*?)\s*\}$/$1/;
  $style_string =~ s/\s+$//;
  $style_string ||= undef;

  $node->attr( style => $style_string );
  $self->_css->purge();
}

sub _normalize_attrs {
  my( $self, $node ) = @_;

  $node->objectify_text();

  # Recurse
  $self->_normalize_attrs($_) for $node->content_list;
  
  foreach my $attr ( $node->all_external_attr_names ) {
    my $attr_value = $node->attr($attr);
    my $handler = $self->_find_handler( type => 'attr', name => $attr, value => $attr_value, tag => $node->tag );
    if( $handler ) {
      $self->_handle( $handler, $node, $attr_value );
      $node->attr( $attr => undef );
    }
  }
}

sub _postprocess { }

sub _handle {
  my( $self, $handler, $node, $value ) = @_;
  $value = $handler->{normalizer} ? $handler->{normalizer}->( $self, $value ) : $value;

  my %elem_attrs = ( );
  $elem_attrs{$handler->{new_attr}} = $value if $handler->{new_attr};

  my $new_elem = new HTML::Element( $handler->{new_tag}, %elem_attrs );

  foreach my $c ( $node->content_list ) {
    $c->detach;
    $new_elem->push_content($c);
  }

  $node->push_content($new_elem);
}

sub _find_handler {
  my( $self, %args ) = @_;

  my @arg_keys = qw/ type name value /;
  for my $arg ( @arg_keys ) {
    if( not exists $args{$arg} ) {
      my( $t, $n, $v ) = @args{ @arg_keys };
      $_ ||= '' for ( $t, $n, $v );

      croak sprintf "missing required '$arg' key (type: %s, name: %s, value: %s)", $t, $n, $v;
    }
  }

  my $type  = $args{type};
  my $name  = $args{name};
  my $value = $args{value};
  my $tag   = $args{tag} || '';

  foreach my $handler ( @{ $self->_handlers } ) {
    next unless $handler->{type} eq $type;
    next unless $handler->{name} eq $name;
    next if $handler->{tag} and ! $self->_match_handler_tag( $handler->{tag}, $tag );

    if( ref $handler->{value} eq 'Regexp' ) {
      return $handler if $value =~ $handler->{value}
    } elsif( ref $handler->{value} eq 'CODE' ) {
      return $handler if $handler->{value}->( $value );
    } elsif( $handler->{value} eq '*') {
      return $handler;
    } else {
      return $handler if $handler->{value} eq $value;
    }
  }

  return;
}

sub _match_handler_tag {
  my( $self, $handler_tag, $tag ) = @_;
  my %handler_tags = map { $_ => 1 } ( ref $handler_tag eq 'ARRAY' ? @$handler_tag : $handler_tag );
  return $handler_tags{$tag} ? 1 : 0;
}

=head1 SEE ALSO

L<CSS>

=head1 AUTHOR

David J. Iberri, C<< <diberri@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-wikiconverter
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WikiConverter>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2006 David J. Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
