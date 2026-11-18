package Pod::Weaver::Section::Author::GETTY::Support;
# ABSTRACT: Support section that is left out when it has nothing to say
our $VERSION = '0.328';
use Moose;
extends 'Pod::Weaver::Section::GenerateSection';

use namespace::autoclean;


around weave_section => sub {
  my ($orig, $self, $document, $input) = @_;

  # GenerateSection fills its template stash from
  # $input->{distmeta}{resources}{repository}{web} and the like, which
  # autovivifies empty resources, repository and bugtracker hashes in the
  # dist's own distmeta, the one META.json is written from. It gets a copy of
  # distmeta with a copy of resources, which it may vivify freely.
  if (ref $input->{distmeta} eq 'HASH') {
    my %distmeta = %{ $input->{distmeta} };
    $distmeta{resources} = { %{ $distmeta{resources} } } if ref $distmeta{resources} eq 'HASH';
    $input = { %$input, distmeta => \%distmeta };
  }

  my $before = scalar @{ $document->children };
  $self->$orig($document, $input);
  return if @{ $document->children } == $before;

  my $section = $document->children->[-1];
  my @text = $section->can('children') ? @{ $section->children } : ($section);
  pop @{ $document->children } unless grep { $_->content =~ /\S/ } @text;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Author::GETTY::Support - Support section that is left out when it has nothing to say

=head1 VERSION

version 0.328

=head1 SYNOPSIS

  [@GETTY/Support]   ; in the Pod::Weaver bundle, configured there

=head1 DESCRIPTION

Renders its text as L<Pod::Weaver::Section::GenerateSection> does and drops
the section again when the rendered text is empty. The bundle's C<SUPPORT>
template names the issue tracker and the IRC channel; a distribution with
neither gets no C<SUPPORT> section at all instead of an empty heading. Reading
the resources for the template leaves the distribution's metadata untouched.

=head2 weave_section

Weaves the section as L<Pod::Weaver::Section::GenerateSection> does and
removes it again if its text holds nothing but whitespace.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-dist-zilla-pluginbundle-author-getty/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
