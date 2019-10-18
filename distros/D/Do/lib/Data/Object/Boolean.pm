package Data::Object::Boolean;

use 5.014;

use strict;
use warnings;

use Scalar::Util ();

state $TrueVal = 1;
state $TrueRef = \$TrueVal;
state $TrueType = 'True';
state $True = bless $TrueRef;

state $FalseVal = 0;
state $FalseRef = \$FalseVal;
state $FalseType = 'False';
state $False = bless $FalseRef;

use overload (
  '""'     => sub{${$_[0]}},
  '!'      => sub{${$_[0]}?$False:$True},
  fallback => 1
);

our $VERSION = '1.88'; # VERSION

# METHODS

sub new {
  IsTrue($_[1])
}

sub False {
  $False
}

sub True {
  $True
}

sub Type {
  if (not defined $_[0]) {
    return $FalseType;
  }

  if (not ref $_[0]) {
    return !!$_[0] ? $TrueType : $FalseType;
  }

  if (Scalar::Util::reftype($_[0]) eq 'SCALAR') {
    return ${$_[0]} ? $TrueType : $FalseType;
  }

  if (Scalar::Util::blessed($_[0])) {
    return $TrueType;
  }

  return !!$_[0] ? $TrueType : $FalseType;
}

sub IsTrue {
  Type($_[0]) eq $TrueType ? $True : $False
}

sub IsFalse {
  Type($_[0]) eq $FalseType ? $True : $False
}

sub TO_JSON {
  ${$_[0]} ? \1 : \0
}

1;

=encoding utf8

=head1 NAME

Data::Object::Boolean

=cut

=head1 ABSTRACT

Data-Object Boolean Class

=cut

=head1 SYNOPSIS

  use Data::Object::Boolean;

  my $bool;

  $bool = Data::Object::Boolean->new; # false
  $bool = Data::Object::Boolean->new(1); # true
  $bool = Data::Object::Boolean->new(0); # false
  $bool = Data::Object::Boolean->new(''); # false
  $bool = Data::Object::Boolean->new(undef); # false

=cut

=head1 DESCRIPTION

This package provides functions and representation for boolean values.

=cut

=head1 FUNCTIONS

This package implements the following functions.

=cut

=head2 false

  False() : Object

The False function returns a boolean object representing false.

=over 4

=item False example

  Data::Object::Boolean::False(); # false

=back

=cut

=head2 isfalse

  IsFalse(Maybe[Any] $arg) : Object

The IsFalse function returns a boolean object representing false if no
arugments are passed, otherwise this function will return a boolean object
based on the argument provided.

=over 4

=item IsFalse example

  Data::Object::Boolean::IsFalse(); # false
  Data::Object::Boolean::IsFalse($value); # true/false

=back

=cut

=head2 istrue

  IsTrue() : Object

The IsTrue function returns a boolean object representing truth if no
arugments are passed, otherwise this function will return a boolean object
based on the argument provided.

=over 4

=item IsTrue example

  Data::Object::Boolean::IsTrue(); # true
  Data::Object::Boolean::IsTrue($value); # true/false

=back

=cut

=head2 to_json

  TO_JSON(Any $arg) : Ref['SCALAR']

The TO_JSON function returns a scalar ref representing truthiness or falsiness
based on the arguments passed. This function is commonly used by JSON encoders
and instructs them on how they should represent the value.

=over 4

=item TO_JSON example

  Data::Object::Boolean::TO_JSON($true); # \1
  Data::Object::Boolean::TO_JSON($false); # \0

=back

=cut

=head2 true

  True() : Object

The True function returns a boolean object representing truth.

=over 4

=item True example

  Data::Object::Boolean::True(); # true

=back

=cut

=head2 type

  Type() : Object

The Type function returns either "True" or "False" based on the truthiness or
falsiness of the argument provided.

=over 4

=item Type example

  Data::Object::Boolean::Type($value); # "True" or "False"

=back

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(Any $arg) : Object

The new method returns a boolean object based on the value of the argument
provided.

=over 4

=item new example

  my $bool;

  $bool = Data::Object::Boolean->new; # false
  $bool = Data::Object::Boolean->new(1); # true
  $bool = Data::Object::Boolean->new(0); # false
  $bool = Data::Object::Boolean->new(''); # false
  $bool = Data::Object::Boolean->new(undef); # false

=back

=cut

=head1 CREDITS

Al Newkirk, C<+319>

Anthony Brummett, C<+10>

Adam Hopkins, C<+2>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated here,
https://github.com/iamalnewkirk/do/blob/master/LICENSE.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/do/wiki>

L<Project|https://github.com/iamalnewkirk/do>

L<Initiatives|https://github.com/iamalnewkirk/do/projects>

L<Milestones|https://github.com/iamalnewkirk/do/milestones>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/CONTRIBUTE.mkdn>

L<Issues|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Do>

L<Data::Object>

L<Data::Object::Class>

L<Data::Object::ClassHas>

L<Data::Object::Role>

L<Data::Object::RoleHas>

L<Data::Object::Library>

=cut