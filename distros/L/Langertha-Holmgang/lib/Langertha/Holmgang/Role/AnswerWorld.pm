package Langertha::Holmgang::Role::AnswerWorld;
# ABSTRACT: The plugin role of a world with its own tools

use Moose::Role;

our $VERSION = '0.002';

requires qw( device_type tools tool );



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Role::AnswerWorld - The plugin role of a world with its own tools

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  package My::Sim::Library;
  use Moose;
  use namespace::autoclean;

  with 'Langertha::Holmgang::Role::AnswerWorld';

  sub device_type { 'library' }

  sub tools { return { search_books => [], lend_book => [qw( book reader )] } }

  sub tool {
    my ( $self, $world, $name, $args, $ctx ) = @_;
    if ( $name eq 'lend_book' ) {
      my $b = $world->{books}{ $args->{book} } or return ( 'Error: no book '.$args->{book}.'.', 0 );
      $b->{lent_to} = $args->{reader};
      return ( 'ok', 1 );
    }
    return ( join( "\n", sort keys %{ $world->{books} || {} } ), 1 );
  }

  __PACKAGE__->meta->make_immutable;

  # suite.yaml
  tools:
    - { name: lend_book, simulator: library, description: …, parameters: { … required: [ book, reader ] } }

=head1 DESCRIPTION

An answer world is a simulated world without a command line: instead of
C<run_command> it brings its own general tools (search, read, add …), the same
for every case of a suite. A suite tool names the world as its C<simulator>;
the tool's name picks what the world does. The world's state is the entry of
the case's state whose C<type> is the world's L</device_type> (the first by
key, when several have it).

The arguments, the result list (C<$output>, C<$ok>, optional C<$sim_gap>) and
the rules (only the state, three answers, keys documented in the POD) are the
same as for a device simulator — see L<Langertha::Holmgang::Role::Simulator>.
An answer world may also implement C<prepare> as described there.

=head2 device_type

  sub device_type { 'kueche' }

Required. The C<type> of the world's entry in the state, and the name a suite
tool gives as C<simulator>.

=head2 tools

  my $tools = $world->tools;   # { tool_name => [ required parameter names ] }

Required. The tools this world answers, each with the parameters it cannot do
without. The loader refuses a suite tool naming this world whose name is not a
key here, or whose C<parameters.required> lacks one of these names.

=head2 tool

  my ( $output, $ok, $gap ) = $world->tool( $state, $name, \%args, $ctx );

Required. Answers one call of the tool C<$name> with the model's C<%args> on
the world's state C<$state> (which it may change, like C<$dev> of a device
simulator).

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
