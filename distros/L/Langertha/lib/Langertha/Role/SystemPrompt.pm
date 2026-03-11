package Langertha::Role::SystemPrompt;
# ABSTRACT: Role for APIs with system prompt
our $VERSION = '0.307';
use Moose::Role;

has system_prompt => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_system_prompt',
);



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::SystemPrompt - Role for APIs with system prompt

=head1 VERSION

version 0.307

=head2 system_prompt

An optional system prompt string. When set, it is automatically prepended to
the conversation as a C<system> role message by L<Langertha::Role::Chat/chat_messages>.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Chat> - Chat role that injects the system prompt into messages

=item * L<Langertha::Raider> - Autonomous agent with its own C<mission> prompt

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
