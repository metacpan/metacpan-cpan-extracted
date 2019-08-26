package Data::Object::Func::Code::Next;

use Data::Object 'Class';

extends 'Data::Object::Func::Code';

our $VERSION = '1.02'; # VERSION

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

sub execute {
  my ($self) = @_;

  my ($data, @args) = $self->unpack;

  return $data->call(@args);
}

sub mapping {
  return ('arg1', '@args');
}

1;
=encoding utf8

=head1 NAME

Data::Object::Func::Code::Next

=cut

=head1 ABSTRACT

Data-Object Code Function (Next) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Code::Next;

  my $func = Data::Object::Func::Code::Next->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Code::Next is a function object for Data::Object::Code.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Code->new(sub { [@_] });

  my $func = Data::Object::Func::Code::Next->new(
    arg1 => $data,
    args => [1,2,3]
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

=head1 STATUS

=begin html

<a href="https://travis-ci.org/iamalnewkirk/data-object" target="_blank">
<img src="https://travis-ci.org/iamalnewkirk/data-object.svg?branch=master"/>
</a>

=end html

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Data::Object::Class>

L<Data::Object::Role>

L<Data::Object::Rule>

L<Data::Object::Library>

L<Data::Object::Signatures>

L<Contributing|https://github.com/iamalnewkirk/data-object/CONTRIBUTING.mkdn>

L<GitHub|https://github.com/iamalnewkirk/data-object>

=cut