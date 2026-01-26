package Pod::Elemental::Transformer::Author::GETTY;
# ABSTRACT: Transform custom POD commands to =head2
our $VERSION = '0.304';
use Moose;
with 'Pod::Elemental::Transformer';

use namespace::autoclean;


my @COMMANDS = qw(
  attr
  method
  func
  opt
  env
  event
  hook
  resource
  seealso
  example
);

my %IS_COMMAND = map { $_ => 1 } @COMMANDS;

sub transform_node {
  my ($self, $node) = @_;

  for my $child (@{ $node->children }) {
    # Transform matching commands to head2
    if ($child->isa('Pod::Elemental::Element::Pod5::Command')
        && $IS_COMMAND{ $child->command }) {
      $child->{command} = 'head2';
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

Pod::Elemental::Transformer::Author::GETTY - Transform custom POD commands to =head2

=head1 VERSION

version 0.304

=head1 SYNOPSIS

  my $xform = Pod::Elemental::Transformer::Author::GETTY->new;
  $xform->transform_node($pod_document);

=head1 DESCRIPTION

This transformer converts custom POD commands into standard C<=head2> commands.
The commands are left in place (not collected into sections), so documentation
stays close to the code it documents.

=head1 SUPPORTED COMMANDS

The following commands are transformed to C<=head2>:

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

C<=event> - for documenting events

=item *

C<=hook> - for documenting hooks

=item *

C<=resource> - for documenting resources/features

=item *

C<=seealso> - for documenting related modules

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

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
