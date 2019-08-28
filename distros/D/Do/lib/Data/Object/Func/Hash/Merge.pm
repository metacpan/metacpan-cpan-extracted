package Data::Object::Func::Hash::Merge;

use Data::Object 'Class';

extends 'Data::Object::Func::Hash';

our $VERSION = '1.05'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has args => (
  is => 'ro',
  isa => 'ArrayRef[Any]',
  opt => 1
);

# METHODS

sub clone {
  require Storable;

  return Storable::dclone(pop);
}

sub execute {
  my ($self) = @_;

  my ($data, @args) = $self->unpack;

  if (!@args) {
    return $self->clone($data);
  }

  if (@args > 1) {
    return $self->clone($self->recurse($data, $self->recurse(@args)));
  }

  my ($right) = @args;
  my (%merge) = %$data;

  for my $key (keys %$right) {
    my $lprop = $$data{$key};
    my $rprop = $$right{$key};

    $merge{$key}
      = ((ref($rprop) eq 'HASH') and (ref($lprop) eq 'HASH'))
      ? $self->recurse($$data{$key}, $$right{$key})
      : $$right{$key};
  }

  return $self->clone(\%merge);
}

sub mapping {
  return ('arg1', '@args');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Hash::Merge

=cut

=head1 ABSTRACT

Data-Object Hash Function (Merge) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Hash::Merge;

  my $func = Data::Object::Func::Hash::Merge->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Hash::Merge is a function object for Data::Object::Hash.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 clone

  clone(Any $arg1) : Any

Returns a cloned data structure.

=over 4

=item clone example

  my $clone = $self->clone();

=back

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Hash->new({1..8,9,undef});

  my $func = Data::Object::Func::Hash::Merge->new(
    arg1 => $data,
    args => [{7,7,9,9}]
  );

  my $result = $func->execute;

=back

=cut

=head2 mapping

  mapping() : (Str)

Returns the ordered list of named function object arguments.

=over 4

=item mapping example

  my @data = $self->mapping;

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<GitHub|https://github.com/iamalnewkirk/do>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/README-DEVEL.mkdn>

L<Reporting|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Data::Object::Class>

L<Data::Object::Role>

L<Data::Object::Rule>

L<Data::Object::Library>

L<Data::Object::Signatures>

=cut