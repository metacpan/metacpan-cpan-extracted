package Langertha::Role::ResponseFormat;
# ABSTRACT: Role for an engine where you can specify structured output
our $VERSION = '0.304';
use Moose::Role;

has response_format => (
  isa => 'HashRef',
  is => 'ro',
  predicate => 'has_response_format',
);



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::ResponseFormat - Role for an engine where you can specify structured output

=head1 VERSION

version 0.304

=head2 response_format

A HashRef specifying the structured output format for the response. The exact
structure depends on the engine. For OpenAI-compatible engines this is typically
C<{ type => 'json_object' }> or a JSON Schema definition. Optional.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Chat> - Chat functionality that uses response format

=item * L<Langertha::Role::OpenAICompatible> - OpenAI-compatible engines that support this role

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
