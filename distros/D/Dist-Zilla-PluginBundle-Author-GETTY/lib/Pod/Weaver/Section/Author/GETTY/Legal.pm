package Pod::Weaver::Section::Author::GETTY::Legal;
# ABSTRACT: Copyright and license section with a link to the author's site
our $VERSION = '0.327';
use Moose;
extends 'Pod::Weaver::Section::Legal';

use Pod::Elemental::Element::Nested;
use Pod::Elemental::Element::Pod5::Ordinary;
use namespace::autoclean;


has url => (
  is      => 'ro',
  isa     => 'Str',
  default => 'https://raudssus.de/',
);


around weave_section => sub {
  my ($orig, $self, $document, $input) = @_;

  my $before = scalar @{ $document->children };
  $self->$orig($document, $input);
  return if @{ $document->children } == $before;

  my $section = $document->children->[-1];
  my $url     = $self->url;
  return if grep { index($_->content, $url) >= 0 } @{ $section->children };

  push @{ $section->children }, Pod::Elemental::Element::Pod5::Ordinary->new({
    content => "L<$url>",
  });
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Author::GETTY::Legal - Copyright and license section with a link to the author's site

=head1 VERSION

version 0.327

=head1 SYNOPSIS

  [@GETTY/Legal]   ; in the Pod::Weaver bundle, nothing to configure

=head1 DESCRIPTION

Builds the usual C<COPYRIGHT AND LICENSE> section and adds the link to the
author's site below the notice. The link lives here, not in the
C<copyright_holder> of F<dist.ini>, so the holder stays plain text and the
generated F<README> and F<LICENSE> do not print POD markup. A holder that
still carries the link itself is left alone: the link is added only if the
notice does not contain it already.

=head2 url

The URL to link. Defaults to C<https://raudssus.de/>.

=head2 weave_section

Weaves the section as L<Pod::Weaver::Section::Legal> does and appends the
link paragraph to it.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-dist-zilla-pluginbundle-author-getty/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2026 by Torsten Raudssus <torsten@raudssus.de>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

L<https://raudssus.de/>

=cut
