package Dist::Zilla::Plugin::FinderCode 6.010;
# ABSTRACT: a callback-based FileFinder plugin

use Moose;
with 'Dist::Zilla::Role::FileFinder';

use namespace::autoclean;

use Moose::Util::TypeConstraints;

has code => (
  is  => 'ro',
  isa => 'CodeRef',
  required => 1,
);

has style => (
  is  => 'ro',
  isa => enum([ qw(grep list) ]),
  required => 1,
);

sub find_files {
  my ($self) = @_;

  my $method = '_find_via_' . $self->style;

  $self->$method;
}

sub _find_via_grep {
  my ($self) = @_;

  my @files = grep { $self->code->($_, $self) } @{ $self->zilla->files };
  return \@files;
}

sub _find_via_list {
  my ($self) = @_;

  my $code = $self->code;
  $self->$code;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::FinderCode - a callback-based FileFinder plugin

=head1 VERSION

version 6.010

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
