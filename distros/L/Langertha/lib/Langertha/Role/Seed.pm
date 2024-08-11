package Langertha::Role::Seed;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Role for an engine that can set a seed
$Langertha::Role::Seed::VERSION = '0.003';
use Moose::Role;
use Carp qw( croak );
use POSIX qw( round );

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
  return round(rand(100_000_000));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Seed - Role for an engine that can set a seed

=head1 VERSION

version 0.003

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/langertha>

  git clone https://github.com/Getty/langertha.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
