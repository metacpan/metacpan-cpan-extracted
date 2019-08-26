package Data::Object::Type::Func;

use strict;
use warnings;

use parent 'Data::Object::Type';

our $VERSION = '1.02'; # VERSION

# BUILD
# METHODS

sub name {
  return 'DoFunc';
}

sub aliases {
  return ['FuncObj', 'FuncObject'];
}

sub validation {
  my ($self, $data) = @_;

  return 0 if !$data->isa('Data::Object::Func');

  return 1;
}

1;
=encoding utf8

=head1 NAME

Data::Object::Type::Func

=cut

=head1 ABSTRACT

Data-Object Func Type Constraint

=cut

=head1 SYNOPSIS

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Func;

  register Data::Object::Type::Func;

  1;

=cut

=head1 DESCRIPTION

Type constraint for validating L<Data::Object::Func> objects. This type
constraint is registered in the L<Data::Object::Library> type library.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 aliases

  aliases() : ArrayRef

The aliases method returns aliases to register in the type library.

=over 4

=item aliases example

  my $aliases = $self->aliases();

=back

=cut

=head2 name

  name() : StrObject

The name method returns the name of the data type.

=over 4

=item name example

  my $name = $self->name();

=back

=cut

=head2 validation

  validation(Object $arg1) : NumObject

The validation method returns truthy if type check is valid.

=over 4

=item validation example

  my $validation = $self->validation();

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