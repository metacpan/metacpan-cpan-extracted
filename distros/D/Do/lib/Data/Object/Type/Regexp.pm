package Data::Object::Type::Regexp;

use strict;
use warnings;

use parent 'Data::Object::Type';

our $VERSION = '1.05'; # VERSION

# BUILD
# METHODS

sub name {
  return 'DoRegexp';
}

sub aliases {
  return ['RegexpObj', 'RegexpObject'];
}

sub coercions {
  return ['RegexpRef', sub {
      require Data::Object::Regexp;
      Data::Object::Regexp->new($_[0]);
  }];
}

sub validation {
  my ($self, $data) = @_;

  return 0 if !$data->isa('Data::Object::Regexp');

  return 1;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Type::Regexp

=cut

=head1 ABSTRACT

Data-Object Regexp Type Constraint

=cut

=head1 SYNOPSIS

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Regexp;

  register Data::Object::Type::Regexp;

  1;

=cut

=head1 DESCRIPTION

Type constraint for validating L<Data::Object::Regexp> objects. This type
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

=head2 coercions

  coercions() : ArrayRef

The coercions method returns coercions to configure on the type constraint.

=over 4

=item coercions example

  my $coercions = $self->coercions();

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