use strict;
use warnings;
package MIME::BodyMunger 0.007;
# ABSTRACT: rewrite the content of text parts, minding charset

use Carp ();
use Encode;
use Variable::Magic ();

#pod =head1 SYNOPSIS
#pod
#pod   MIME::BodyMunger->rewrite_content(
#pod     $mime_entity,
#pod     sub {
#pod       my ($body_ref) = @_;
#pod       $$body_ref =~ s/zig/zag/;
#pod     },
#pod   );
#pod
#pod =head1 DESCRIPTION
#pod
#pod MIME::BodyMunger provides methods for rewriting text parts.  These methods
#pod take care of character sets for you so that you can treat everything like text
#pod instead of worrying about content transfer encoding or character set encoding.
#pod
#pod At present, only MIME::Entity messages can be handled.  Other types will be
#pod added in the future.
#pod
#pod =method rewrite_content
#pod
#pod   MIME::BodyMunger->rewrite_content($message, sub { ... });
#pod
#pod This method uses the given callback to rewrite the content (body) of the
#pod message.  It decodes the content (using Content-Transfer-Encoding and the
#pod Content-Type charset (or ISO-8859-1, if none is given)) and provides a
#pod reference to the character string to the coderef.  If the content is altered,
#pod the body will be re-encoded into the original charset and the message will be
#pod updated.
#pod
#pod The callback is invoked like this:
#pod
#pod   $code->(\$content, $message);
#pod
#pod In the future, there should be an option to re-encode to an alternate charset.
#pod
#pod =cut

sub rewrite_content {
  my ($self, $entity, $code) = @_;

  Carp::confess "rewrite_content called on non-text part"
    unless $entity->effective_type =~ qr{\Atext/(?:html|plain)(?:$|;)}i;

  my $charset = $entity->head->mime_attr('content-type.charset')
             || 'ISO-8859-1';

  $charset = 'MacRoman' if lc $charset eq 'macintosh';

  Carp::carp(qq{rewriting message in unknown charset "$charset"})
    unless my $known_charset = Encode::find_encoding($charset);

  my $changed = 0;
  my $got_set = Variable::Magic::wizard(set => sub { $changed = 1 });

  my $body = $known_charset
           ? Encode::decode($charset, $entity->bodyhandle->as_string)
           : $entity->bodyhandle->as_string;

  Variable::Magic::cast($body, $got_set);
  $code->(\$body, $entity);

  if ($changed) {
    my $io = $entity->open('w');
    $io->print($known_charset ? Encode::encode($charset, $body) : $body);
  }
}

#pod =method rewrite_lines
#pod
#pod   MIME::BodyMunger->rewrite_lines($message, sub { ... });
#pod
#pod This method behaves like C<rewrite_content>, but the callback is invoked once
#pod per line, like this:
#pod
#pod   local $_ = $line;
#pod   $code->($message);
#pod
#pod If any line is changed, the entire body will be reencoded and updated.
#pod
#pod =cut

sub rewrite_lines {
  my ($self, $entity, $code) = @_;

  Carp::confess "rewrite_lines called on non-text part"
    unless $entity->effective_type =~ qr{\Atext/(?:html|plain)(?:$|;)}i;

  my $charset = $entity->head->mime_attr('content-type.charset')
             || 'ISO-8859-1';

  $charset = 'MacRoman' if lc $charset eq 'macintosh';

  Carp::carp(qq{rewriting message in unknown charset "$charset"})
    unless my $known_charset = Encode::find_encoding($charset);

  my $changed = 0;
  my $got_set = Variable::Magic::wizard(set => sub { $changed = 1 });

  my @lines = $entity->bodyhandle->as_lines;

  for my $line (@lines) {
    local $_ = $known_charset ? Encode::decode($charset, $line) : $line;
    Variable::Magic::cast($_, $got_set);
    $code->(\$_, $entity);
    Variable::Magic::dispell($_, $got_set);
    $line = $_;
  };

  if ($changed) {
    my $io = $entity->open('w');
    $io->print($known_charset ? Encode::encode($charset, $_) : $_) for @lines;
  }
}

#pod =head1 THANKS
#pod
#pod Thanks to Pobox.com and Listbox.com, who sponsored the development of this
#pod module.
#pod
#pod Thanks to Brian Cassidy for writing some tests for the initial release.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIME::BodyMunger - rewrite the content of text parts, minding charset

=head1 VERSION

version 0.007

=head1 SYNOPSIS

  MIME::BodyMunger->rewrite_content(
    $mime_entity,
    sub {
      my ($body_ref) = @_;
      $$body_ref =~ s/zig/zag/;
    },
  );

=head1 DESCRIPTION

MIME::BodyMunger provides methods for rewriting text parts.  These methods
take care of character sets for you so that you can treat everything like text
instead of worrying about content transfer encoding or character set encoding.

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

=head2 rewrite_content

  MIME::BodyMunger->rewrite_content($message, sub { ... });

This method uses the given callback to rewrite the content (body) of the
message.  It decodes the content (using Content-Transfer-Encoding and the
Content-Type charset (or ISO-8859-1, if none is given)) and provides a
reference to the character string to the coderef.  If the content is altered,
the body will be re-encoded into the original charset and the message will be
updated.

The callback is invoked like this:

  $code->(\$content, $message);

In the future, there should be an option to re-encode to an alternate charset.

=head2 rewrite_lines

  MIME::BodyMunger->rewrite_lines($message, sub { ... });

This method behaves like C<rewrite_content>, but the callback is invoked once
per line, like this:

  local $_ = $line;
  $code->($message);

If any line is changed, the entire body will be reencoded and updated.

=head1 THANKS

Thanks to Pobox.com and Listbox.com, who sponsored the development of this
module.

Thanks to Brian Cassidy for writing some tests for the initial release.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Brian Cassidy Ricardo Signes

=over 4

=item *

Brian Cassidy <bricas@bricas-laptop.(none)>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
