use strict;
use warnings;
package MIME::Visitor 0.007;
# ABSTRACT: walk through MIME parts and do stuff (like rewrite)

use Encode;
use MIME::BodyMunger;

#pod =head1 SYNOPSIS
#pod
#pod   # This will reverse all lines in each text part, taking care of all encoding
#pod   # for you.
#pod
#pod   MIME::Visitor->rewrite_all_lines(
#pod     $mime_entity,
#pod     sub { chomp; $_ = reverse . "\n"; },
#pod   );
#pod
#pod =head1 DESCRIPTION
#pod
#pod MIME::Visitor provides a simple way to walk through the parts of a MIME
#pod message, taking action on each one.  In general, this is not a very complicated
#pod thing to do, but having it in one place is convenient.
#pod
#pod The most powerful feature of MIME::Visitor, though, is its methods for
#pod rewriting text parts.  These methods take care of character sets for you so
#pod that you can treat everything like text instead of worrying about content
#pod transfer encoding or character set encoding.
#pod
#pod At present, only MIME::Entity messages can be handled.  Other types will be
#pod added in the future.
#pod
#pod =method walk_parts
#pod
#pod   MIME::Visitor->walk_parts($root, sub { ... });
#pod
#pod This method calls the given code on every part of the given root message,
#pod including the root itself.
#pod
#pod =cut

sub walk_parts {
  my ($self, $root, $code) = @_;

  $code->($root);
  for my $part ($root->parts) {
    $self->walk_parts($part, $code);
  }
}

#pod =method walk_leaves
#pod
#pod   MIME::Visitor->walk_leaves($root, sub { ... });
#pod
#pod This method calls the given code on every leaf part of the given root message.
#pod It descends into multipart parts of the message without calling the callback on
#pod them.
#pod
#pod =cut

sub walk_leaves {
  my ($self, $root, $code) = @_;

  $self->walk_parts(
    $root,
    sub {
      return if $_[0]->is_multipart;
      $code->($_[0]);
    },
  );
}

#pod =method walk_text_leaves
#pod
#pod   MIME::Visitor->walk_text_leaves($root, sub { ... });
#pod
#pod This method behaves like C<walk_leaves>, but only calls the callback on parts
#pod with a content type of text/plain or text/html.
#pod
#pod =cut

sub walk_text_leaves {
  my ($self, $root, $code) = @_;
  $self->walk_leaves($root, sub {
    return unless $_[0]->effective_type =~ qr{\Atext/(?:html|plain)(?:$|;)}i;
    $code->($_[0]);
  });
}

#pod =method rewrite_parts
#pod
#pod   MIME::Visitor->rewrite_parts($root, sub { ... });
#pod
#pod This method walks the text leaves of the MIME message, rewriting the content of
#pod the parts.  For each text leaf, the callback is invoked like this:
#pod
#pod   $code->(\$content, $part);
#pod
#pod For more information, see L<MIME::BodyMunger/rewrite_content>.
#pod
#pod =cut

sub rewrite_parts {
  my ($self, $root, $code) = @_;

  $self->walk_text_leaves($root, sub {
    my ($part) = @_;
    MIME::BodyMunger->rewrite_content($part, $code);
  });
}

#pod =method rewrite_all_lines
#pod
#pod   MIME::Visitor->rewrite_all_lines($root, sub { ... });
#pod
#pod This method behaves like C<rewrite_parts>, but the callback is called for each
#pod line of each relevant part, rather than for the part's body as a whole.
#pod
#pod =cut

sub rewrite_all_lines {
  my ($self, $root, $code) = @_;

  $self->walk_text_leaves($root, sub {
    my ($part) = @_;
    MIME::BodyMunger->rewrite_lines($part, $code);
  });
}

#pod =head1 THANKS
#pod
#pod Thanks to Pobox.com and Listbox.com, who sponsored the development of this
#pod module.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIME::Visitor - walk through MIME parts and do stuff (like rewrite)

=head1 VERSION

version 0.007

=head1 SYNOPSIS

  # This will reverse all lines in each text part, taking care of all encoding
  # for you.

  MIME::Visitor->rewrite_all_lines(
    $mime_entity,
    sub { chomp; $_ = reverse . "\n"; },
  );

=head1 DESCRIPTION

MIME::Visitor provides a simple way to walk through the parts of a MIME
message, taking action on each one.  In general, this is not a very complicated
thing to do, but having it in one place is convenient.

The most powerful feature of MIME::Visitor, though, is its methods for
rewriting text parts.  These methods take care of character sets for you so
that you can treat everything like text instead of worrying about content
transfer encoding or character set encoding.

At present, only MIME::Entity messages can be handled.  Other types will be
added in the future.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 walk_parts

  MIME::Visitor->walk_parts($root, sub { ... });

This method calls the given code on every part of the given root message,
including the root itself.

=head2 walk_leaves

  MIME::Visitor->walk_leaves($root, sub { ... });

This method calls the given code on every leaf part of the given root message.
It descends into multipart parts of the message without calling the callback on
them.

=head2 walk_text_leaves

  MIME::Visitor->walk_text_leaves($root, sub { ... });

This method behaves like C<walk_leaves>, but only calls the callback on parts
with a content type of text/plain or text/html.

=head2 rewrite_parts

  MIME::Visitor->rewrite_parts($root, sub { ... });

This method walks the text leaves of the MIME message, rewriting the content of
the parts.  For each text leaf, the callback is invoked like this:

  $code->(\$content, $part);

For more information, see L<MIME::BodyMunger/rewrite_content>.

=head2 rewrite_all_lines

  MIME::Visitor->rewrite_all_lines($root, sub { ... });

This method behaves like C<rewrite_parts>, but the callback is called for each
line of each relevant part, rather than for the part's body as a whole.

=head1 THANKS

Thanks to Pobox.com and Listbox.com, who sponsored the development of this
module.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
