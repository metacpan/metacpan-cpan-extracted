package Dist::Zilla::Plugin::InlineFiles 6.032;
# ABSTRACT: files in a data section

use Moose;
with 'Dist::Zilla::Role::FileGatherer';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This plugin exists only to be extended, and gathers all files contained in its
#pod data section and those of its ancestors.  For more information, see
#pod L<Data::Section|Data::Section>.
#pod
#pod =cut

use Sub::Exporter::ForMethods;
use Data::Section 0.200002 # encoding and bytes
  { installer => Sub::Exporter::ForMethods::method_installer },
  '-setup' => { encoding => 'bytes' };
use Dist::Zilla::File::InMemory;

sub gather_files {
  my ($self) = @_;

  my $data = $self->merged_section_data;
  return unless $data and %$data;

  for my $name (keys %$data) {
    $self->add_file(
      Dist::Zilla::File::InMemory->new({
        name    => $name,
        content => ${ $data->{$name} },
      }),
    );
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 SEE ALSO
#pod
#pod Core Dist::Zilla plugins inheriting from L<InlineFiles>:
#pod L<MetaTests|Dist::Zilla::Plugin::MetaTests>,
#pod L<PodCoverageTests|Dist::Zilla::Plugin::PodCoverageTests>,
#pod L<PodSyntaxTests|Dist::Zilla::Plugin::PodSyntaxTests>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::InlineFiles - files in a data section

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This plugin exists only to be extended, and gathers all files contained in its
data section and those of its ancestors.  For more information, see
L<Data::Section|Data::Section>.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 SEE ALSO

Core Dist::Zilla plugins inheriting from L<InlineFiles>:
L<MetaTests|Dist::Zilla::Plugin::MetaTests>,
L<PodCoverageTests|Dist::Zilla::Plugin::PodCoverageTests>,
L<PodSyntaxTests|Dist::Zilla::Plugin::PodSyntaxTests>.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
