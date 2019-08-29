package Data::Object::Type::Array;

use strict;
use warnings;

use parent 'Data::Object::Type';

our $VERSION = '1.07'; # VERSION

# BUILD
# METHODS

sub name {
  return 'DoArray';
}

sub aliases {
  return ['ArrayObj', 'ArrayObject'];
}

sub coercions {
  return ['ArrayRef', sub {
      require Data::Object::Array;
      Data::Object::Array->new($_[0]);
  }];
}

sub validation {
  my ($self, $data) = @_;

  return 0 if !$data->isa('Data::Object::Array');

  return 1;
}

sub explaination {
  my ($self, $data, $type, $name) = @_;

  my $param = $type->parameters->[0];

  for my $i (0 .. $#$data) {
    next if $param->check($data->[$i]);

    my $indx = sprintf('%s->[%d]', $name, $i);
    my $desc = $param->validate_explain($data->[$i], $indx);
    my $text = '"%s" constrains each value in the array object with "%s"';

    return [sprintf($text, $type, $param), @{$desc}];
  }

  return;
}

sub parameterize {
  my ($self, $data, $type) = @_;

  $type->check($_) || return for @$data;

  return !!1;
}

sub parameterize_coercions {
  my ($self, $data, $type, $anon) = @_;

  my $coercions = [];

  push @$coercions, 'ArrayRef', sub {
    my $value = @_ ? $_[0] : $_;
    my $items = [];

    for (my $i = 0; $i < @$value; $i++) {
      return $value unless $anon->check($value->[$i]);
      $items->[$i] = $data->coerce($value->[$i]);
    }

    return $type->coerce($items);
  };

  return $coercions;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Type::Array

=cut

=head1 ABSTRACT

Data-Object Array Type Constraint

=cut

=head1 SYNOPSIS

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Array;

  register Data::Object::Type::Array;

  1;

=cut

=head1 DESCRIPTION

Type constraint for validating L<Data::Object::Array> objects. This type
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

=head2 explaination

  explaination(Object $arg1, Object $arg2, Str $arg3) : Any

The explaination method returns the explaination for the type check failure.

=over 4

=item explaination example

  my $explaination = $self->explaination();

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

=head2 parameterize

  parameterize(Object $arg1, Object $arg2) : Num

The parameterize method returns truthy if parameterized type check is valid.

=over 4

=item parameterize example

  my $parameterize = $self->parameterize();

=back

=cut

=head2 parameterize_coercions

  parameterize(Object $arg1, Object $arg2) : Num

The parameterize_coercions method returns truthy if parameterized type check is valid.

=over 4

=item parameterize_coercions example

  my $parameterize_coercions = $self->parameterize_coercions();

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

L<On GitHub|https://github.com/iamalnewkirk/do>

L<Initiatives|https://github.com/iamalnewkirk/do/projects>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/CONTRIBUTE.mkdn>

L<Reporting|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Data::Object::Class>

L<Data::Object::Role>

L<Data::Object::Rule>

L<Data::Object::Library>

L<Data::Object::Signatures>

=cut