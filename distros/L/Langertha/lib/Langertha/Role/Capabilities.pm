package Langertha::Role::Capabilities;
# ABSTRACT: Engine-capability registry derived from composed roles
our $VERSION = '0.500';
use Moose::Role;


# Role-name => list of capability flag names that role contributes.
# Plus implicit:
#   chat            -> simple_chat works (Role::Chat is composed)
#   streaming       -> chat_stream_request is wired up (Role::Streaming)
#   tools_native    -> Role::Tools (the named flags below come too)
#   tools_hermes    -> Role::HermesTools
#   ... see %ROLE_TO_CAPS below.
my %ROLE_TO_CAPS = (
  'Langertha::Role::Chat'             => [qw( chat )],
  'Langertha::Role::Streaming'        => [qw( streaming )],
  'Langertha::Role::Tools'            => [qw(
    tools_native tool_choice_auto tool_choice_any tool_choice_none tool_choice_named
  )],
  'Langertha::Role::HermesTools'      => [qw( tools_hermes )],
  'Langertha::Role::ResponseFormat'   => [qw(
    response_format_json_object response_format_json_schema
  )],
  'Langertha::Role::Embedding'        => [qw( embedding )],
  'Langertha::Role::Transcription'    => [qw( transcription )],
  'Langertha::Role::ImageGeneration'  => [qw( image_generation )],
  'Langertha::Role::Temperature'      => [qw( temperature )],
  'Langertha::Role::Seed'             => [qw( seed )],
  'Langertha::Role::ContextSize'      => [qw( context_size )],
  'Langertha::Role::ResponseSize'     => [qw( response_size )],
  'Langertha::Role::SystemPrompt'     => [qw( system_prompt )],
  'Langertha::Role::ParallelToolUse'  => [qw( parallel_tool_use )],
);

sub engine_capabilities {
  my ($self) = @_;
  my %caps;
  for my $role ( keys %ROLE_TO_CAPS ) {
    next unless $self->does($role);
    $caps{$_} = 1 for @{ $ROLE_TO_CAPS{$role} };
  }
  return \%caps;
}


sub supports {
  my ( $self, $cap ) = @_;
  return !!$self->engine_capabilities->{$cap};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Capabilities - Engine-capability registry derived from composed roles

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    if ( $engine->supports('tool_choice_named') ) { ... }

    my $caps = $engine->engine_capabilities;
    for my $cap ( sort keys %$caps ) {
        say "$cap" if $caps->{$cap};
    }

    # Engine-level override for a wire reality the role inventory
    # cannot express (e.g. provider only accepts string tool_choice):
    around engine_capabilities => sub {
      my ( $orig, $self, @rest ) = @_;
      my $caps = $self->$orig(@rest);
      delete $caps->{tool_choice_named};
      return $caps;
    };

=head1 DESCRIPTION

Composed by L<Langertha::Role::Chat> (and therefore present on every
engine), this role provides the C<engine_capabilities> method plus the
C<supports> helper. The default implementation derives the flag set
from which capability-bearing roles the engine composes — no per-role
plumbing required, the registry below is the single source of truth.

Engines override (via C<around>) when the wire reality differs from
the role inventory — for example to clear C<tool_choice_named> on a
provider that only accepts string forms of C<tool_choice>.

The mapping from role to flag is intentionally kept inside this one
module so adding a new capability is a single-file change. The role
itself does not need to know about C<engine_capabilities>.

=head2 engine_capabilities

    my $caps = $engine->engine_capabilities;

Returns a HashRef of capability flags. The default scans the composed
role inventory and sets flags from a static role-to-flags map. Override
via C<around> on an engine to remove flags for capabilities the wire
reality cannot deliver, or to add ad-hoc flags an engine wants to
advertise.

=head2 supports

    if ( $engine->supports('tool_choice_named') ) { ... }

Convenience wrapper that returns a true value when the named capability
is present and truthy in C<engine_capabilities>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
