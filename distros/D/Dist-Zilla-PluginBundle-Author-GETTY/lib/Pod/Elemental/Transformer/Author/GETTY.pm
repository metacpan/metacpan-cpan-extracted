package Pod::Elemental::Transformer::Author::GETTY;
# ABSTRACT: Transform custom POD commands to =head1 and =head2
our $VERSION = '0.307';
use Moose;
with 'Pod::Elemental::Transformer';

use namespace::autoclean;


# Commands that transform to =head1 with specific content
my %HEAD1_COMMANDS = (
  synopsis    => 'SYNOPSIS',
  description => 'DESCRIPTION',
  seealso     => 'SEE ALSO',
);

# Commands that transform to =head2 (keeping content as-is)
my @HEAD2_COMMANDS = qw(
  attr
  method
  func
  opt
  env
  hook
  example
);

my %IS_HEAD2_COMMAND = map { $_ => 1 } @HEAD2_COMMANDS;

sub transform_node {
  my ($self, $node) = @_;

  for my $child (@{ $node->children }) {
    if ($child->isa('Pod::Elemental::Element::Pod5::Command')) {
      my $cmd = $child->command;

      # Transform head1 commands (replace content with fixed heading)
      if (my $heading = $HEAD1_COMMANDS{$cmd}) {
        $child->{command} = 'head1';
        $child->{content} = $heading;
      }
      # Transform head2 commands (keep content)
      elsif ($IS_HEAD2_COMMAND{$cmd}) {
        $child->{command} = 'head2';
      }
    }

    # Recurse into nested structures
    if ($child->can('children') && $child->children) {
      $self->transform_node($child);
    }
  }

  return $node;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Transformer::Author::GETTY - Transform custom POD commands to =head1 and =head2

=head1 VERSION

version 0.307

=head1 SYNOPSIS

  my $xform = Pod::Elemental::Transformer::Author::GETTY->new;
  $xform->transform_node($pod_document);

=head1 DESCRIPTION

This transformer converts custom POD commands into standard C<=head1> and
C<=head2> commands. The commands are left in place (not collected into
sections), so documentation stays close to the code it documents.

=head1 SUPPORTED COMMANDS

=head2 Section Commands (transform to C<=head1>)

=over 4

=item *

C<=synopsis> - transforms to C<=head1 SYNOPSIS>

=item *

C<=description> - transforms to C<=head1 DESCRIPTION>

=item *

C<=seealso> - transforms to C<=head1 SEE ALSO>

=back

=head2 Inline Commands (transform to C<=head2>)

=over 4

=item *

C<=attr> - for documenting attributes

=item *

C<=method> - for documenting methods

=item *

C<=func> - for documenting functions

=item *

C<=opt> - for documenting CLI options

=item *

C<=env> - for documenting environment variables

=item *

C<=hook> - for documenting hooks

=item *

C<=example> - for documenting examples

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
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
