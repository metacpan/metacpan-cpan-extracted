package HTML::ElementRaw;

# Allow raw html as content so that special characters
# do not get encoded.  The string is incorporated as part
# of the start tag in order to bypass the regular HTML::Element
# encoding.

use strict;
use vars qw($VERSION @ISA);

require HTML::Element;

@ISA = qw(HTML::Element);

$VERSION = '1.18';

# Whole lotta overrides
#
# Have to store the string somewhere besides _content, because
# traverse looks in the attribute directly rather than calling
# content().

sub push_content {
  # Flatten elements into an HTML string if found,
  # otherwise just slap the text in.
  my @text = map(defined (ref $_ ? $_->as_HTML : $_) ? $_ : '', @_);
  shift->{_string}[0] .= join('',@text);
}
sub insert_element {
  push_content(@_);
}
sub starttag {
  shift->{_string}[0];
}
sub as_HTML {
  starttag(@_);
}

# These become degenerate
sub endtag  { return }
sub pos     { return }
sub attr    { return }
sub content { return }
sub tag     { return }

sub new {
  my $that = shift;
  my $class = ref($that) || $that;
  # The tag type does not get displayed.  We keep it
  # around anyway, just in case.
  my @args = @_ ? @_ : 'p';
  my $self = new HTML::Element @args;
  bless $self,$class;
  $self;
}

1;
__END__

=head1 NAME

HTML::ElementRaw - Perl extension for HTML::Element(3).

=head1 SYNOPSIS

  use HTML::ElementRaw;
  $er = new HTML::ElementRaw;
  $text = '<p>I would like this &nbsp; HTML to not be encoded</p>';
  $er->push_content($text);
  $h = new HTML::Element 'h2';
  $h->push_content($er);
  # Now $text will appear as you typed it, non-escaped,
  # embedded in the HTML produced by $h.
  print $h->as_HTML;

=head1 DESCRIPTION

Provides a way to graft raw HTML strings into your HTML::Element(3)
structures.  Since they represent raw text, these can only be leaves in
your HTML element tree.  The only methods that are of any real
use in this degenerate element are push_content() and as_HTML().
The push_content() method will simply prepend the provided text to
the current content.  If you happen to pass an HTML::element to
push_content, the output of the as_HTML() method in that element
will be prepended.

=head1 REQUIRES

HTML::Element(3)

=head1 AUTHOR

Matthew P. Sisk, E<lt>F<sisk@mojotoad.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 1998-2010 Matthew P. Sisk.
All rights reserved. All wrongs revenged. This program is free
software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=head1 SEE ALSO

HTML::Element(3), HTML::ElementSuper(3), HTML::Element::Glob(3), HTML::ElementTable(3), perl(1).

=cut
