use strict;
use warnings;
package HTML::Widget::Plugin::Attrs;
# ABSTRACT: an HTML attribute string
$HTML::Widget::Plugin::Attrs::VERSION = '0.204';
use parent 'HTML::Widget::Plugin';

#pod =head1 DESCRIPTION
#pod
#pod This plugin produces HTML attribute strings.
#pod
#pod =cut

use HTML::Element;

#pod =head1 METHODS
#pod
#pod =head2 C< provided_widgets >
#pod
#pod This plugin provides the following widgets: attrs
#pod
#pod =cut

sub provided_widgets { qw(attrs) }

#pod =head2 C< attrs >
#pod
#pod This method returns HTML attribute strings, so:
#pod
#pod   $factory->attrs({
#pod     size => 10,
#pod     name => q(Michael "Five-Toes" O'Gambini),
#pod   });
#pod
#pod will produce something like:
#pod
#pod   size="10" name="Michael &quot;Five-Toes&quot;"
#pod
#pod None of the standard argument rewriting applies.  These are the valid
#pod arguments:
#pod
#pod =over
#pod
#pod =item -tag
#pod
#pod This may be the name of an HTML element.  If given, it will be used to look up
#pod what attributes are boolean.
#pod
#pod =item -bool
#pod
#pod This may be an arrayref of attribute names to treat as boolean arguments.
#pod
#pod =back
#pod
#pod All attributes not beginning with a dash will be treated as attributes for the
#pod attribute string.  Boolean attributes will always have the attribute name as
#pod the value if true, and will be omitted if false.
#pod
#pod If both C<-tag> and C<-bool> are given, they are unioned.
#pod
#pod =cut

# Note that we're totally replacing the standard args rewriting!  This is not
# going to act quite like existing widget plugins! -- rjbs, 2008-05-05
# ALL unless they are boolean args.
sub rewrite_arg { return $_[1] }

sub attrs {
  my ($self, $factor, $arg) = @_;

  my $attr = {};

  my %bool;
  $bool{lc $_} = 1 for @{ $arg->{-bool} || [] };

  require HTML::Tagset;
  if ($arg->{-tag} and my $entry = $HTML::Tagset::boolean_attr{$arg->{-tag}}) {
    $bool{lc $_} = 1 for (ref $entry ? keys %$entry : $entry);
  }

  my $str = '';
  for my $key (sort grep { $_ !~ /^-/ and defined $arg->{$_} } keys %$arg) {
    my $is_bool = $bool{ lc $key };
    next if $is_bool and not $arg->{$key};

    $str .= HTML::Entities::encode_entities($key)
         .  '="'
         . ($is_bool ? HTML::Entities::encode_entities($key)
                     : HTML::Entities::encode_entities($arg->{$key}))
         .  '" ';
  }

  # Remove the trailing space that we're sure to have -- rjbs, 2008-05-05
  substr $str, -1, 1, '' if length $str;

  return $str;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widget::Plugin::Attrs - an HTML attribute string

=head1 VERSION

version 0.204

=head1 DESCRIPTION

This plugin produces HTML attribute strings.

=head1 METHODS

=head2 C< provided_widgets >

This plugin provides the following widgets: attrs

=head2 C< attrs >

This method returns HTML attribute strings, so:

  $factory->attrs({
    size => 10,
    name => q(Michael "Five-Toes" O'Gambini),
  });

will produce something like:

  size="10" name="Michael &quot;Five-Toes&quot;"

None of the standard argument rewriting applies.  These are the valid
arguments:

=over

=item -tag

This may be the name of an HTML element.  If given, it will be used to look up
what attributes are boolean.

=item -bool

This may be an arrayref of attribute names to treat as boolean arguments.

=back

All attributes not beginning with a dash will be treated as attributes for the
attribute string.  Boolean attributes will always have the attribute name as
the value if true, and will be omitted if false.

If both C<-tag> and C<-bool> are given, they are unioned.

=head1 AUTHOR

Ricardo SIGNES

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
