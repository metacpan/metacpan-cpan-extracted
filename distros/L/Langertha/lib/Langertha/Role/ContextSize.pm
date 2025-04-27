package Langertha::Role::ContextSize;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Role for an engine where you can specify the context size (in tokens)
$Langertha::Role::ContextSize::VERSION = '0.008';
use Moose::Role;

has context_size => (
  isa => 'Int',
  is => 'ro',
  predicate => 'has_context_size',
);

sub get_context_size {
  my ( $self ) = @_;
  return $self->context_size if $self->has_context_size;
  return $self->default_context_size if $self->can('default_context_size');
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::ContextSize - Role for an engine where you can specify the context size (in tokens)

=head1 VERSION

version 0.008

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
