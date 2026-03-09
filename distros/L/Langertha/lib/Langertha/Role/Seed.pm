package Langertha::Role::Seed;
# ABSTRACT: Role for an engine that can set a seed
our $VERSION = '0.305';
use Moose::Role;
use Carp qw( croak );

has randomize_seed => (
  is => 'ro',
  lazy_build => 1,
);
sub _build_randomize_seed { 0 }


has seed => (
  is => 'ro',
  predicate => 'has_seed',
);


sub random_seed {
  return sprintf("%u",rand(100_000_000));
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Seed - Role for an engine that can set a seed

=head1 VERSION

version 0.305

=head2 randomize_seed

When true, a random seed is generated for each request. Defaults to C<0>
(disabled). Useful when you want varied outputs without setting a fixed seed.

=head2 seed

Fixed integer seed for reproducible outputs. Optional. When set, the engine
passes it to the API to make sampling deterministic. Use C<randomize_seed>
instead when you want a different random seed on each call.

=head2 random_seed

    my $seed = $engine->random_seed;

Returns a random unsigned integer suitable for use as a seed value.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Temperature> - Sampling temperature

=item * L<Langertha::Engine::Ollama> - Engine that composes this role

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
