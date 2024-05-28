package Dist::Zilla::Plugin::License 6.032;
# ABSTRACT: output a LICENSE file

use Moose;
with 'Dist::Zilla::Role::FileGatherer';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This plugin adds a F<LICENSE> file containing the full text of the
#pod distribution's license, as produced by the C<fulltext> method of the
#pod dist's L<Software::License> object.
#pod
#pod =attr filename
#pod
#pod This attribute can be used to specify a name other than F<LICENSE> to be used.
#pod
#pod =cut

use Dist::Zilla::File::InMemory;

has filename => (
  is  => 'ro',
  isa => 'Str',
  default => 'LICENSE',
);

sub gather_files {
  my ($self, $arg) = @_;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => $self->filename,
    content => $self->zilla->license->fulltext,
  });

  $self->add_file($file);
  return;
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 SEE ALSO
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod the C<license> attribute of the L<Dist::Zilla> object to select the license
#pod to use.
#pod
#pod =item *
#pod
#pod Dist::Zilla roles:
#pod L<FileGatherer|Dist::Zilla::Role::FileGatherer>.
#pod
#pod =item *
#pod
#pod Other modules:
#pod L<Software::License>,
#pod L<Software::License::Artistic_2_0>.
#pod
#pod =back
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::License - output a LICENSE file

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This plugin adds a F<LICENSE> file containing the full text of the
distribution's license, as produced by the C<fulltext> method of the
dist's L<Software::License> object.

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

=head1 ATTRIBUTES

=head2 filename

This attribute can be used to specify a name other than F<LICENSE> to be used.

=head1 SEE ALSO

=over 4

=item *

the C<license> attribute of the L<Dist::Zilla> object to select the license
to use.

=item *

Dist::Zilla roles:
L<FileGatherer|Dist::Zilla::Role::FileGatherer>.

=item *

Other modules:
L<Software::License>,
L<Software::License::Artistic_2_0>.

=back

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
