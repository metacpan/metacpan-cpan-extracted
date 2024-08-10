package Langertha::Role::Models;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Role for APIs with several models
$Langertha::Role::Models::VERSION = '0.002';
use Moose::Role;

requires qw(
  default_model
);

has models => (
  is => 'rw',
  isa => 'ArrayRef[Str]',
  lazy_build => 1,
);
sub _build_models {
  my ( $self ) = @_;
  return [
    $self->can('all_models')
      ? $self->all_models
      : $self->model
  ];
}

has model => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);
sub _build_model {
  my ( $self ) = @_;
  return $self->default_model;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Models - Role for APIs with several models

=head1 VERSION

version 0.002

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
