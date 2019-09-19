package Data::Object::Number;

use 5.014;

use strict;
use warnings;

use Role::Tiny::With;

use overload (
  '""'     => 'detract',
  '~~'     => 'detract',
  fallback => 1
);

with qw(
  Data::Object::Role::Dumpable
  Data::Object::Role::Functable
  Data::Object::Role::Throwable
);

use parent 'Data::Object::Number::Base';

our $VERSION = '1.80'; # VERSION

# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::Number

=cut

=head1 ABSTRACT

Data-Object Number Class

=cut

=head1 SYNOPSIS

  use Data::Object::Number;

  my $number = Data::Object::Number->new(1_000_000);

=cut

=head1 DESCRIPTION

This package provides routines for operating on Perl 5 numeric data.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Data::Object::Number::Base>

=cut

=head1 INTEGRATIONS

This package integrates behaviors from:

L<Data::Object::Role::Dumpable>

L<Data::Object::Role::Functable>

L<Data::Object::Role::Throwable>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 abs

  abs() : Any

The abs method returns the absolute value of the number. This method returns a
L<Data::Object::Number> object.

=over 4

=item abs example

  # given 12

  $number->abs; # 12

  # given -12

  $number->abs; # 12

=back

=cut

=head2 atan2

  atan2(Num $arg1) : NumObject

The atan2 method returns the arctangent of Y/X in the range -PI to PI This
method returns a L<Data::Object::Float> object.

=over 4

=item atan2 example

  # given 1

  $number->atan2(1); # 0.785398163397448

=back

=cut

=head2 cos

  cos() : NumObject

The cos method computes the cosine of the number (expressed in radians). This
method returns a L<Data::Object::Float> object.

=over 4

=item cos example

  # given 12

  $number->cos; # 0.843853958732492

=back

=cut

=head2 decr

  decr(Num $arg1) : NumObject

The decr method returns the numeric number decremented by 1. This method returns
a data type object to be determined after execution.

=over 4

=item decr example

  # given 123456789

  $number->decr; # 123456788

=back

=cut

=head2 defined

  defined() : NumObject

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false. This method returns a
L<Data::Object::Number> object.

=over 4

=item defined example

  # given $number

  $number->defined; # 1

=back

=cut

=head2 downto

  downto(Int $arg1) : ArrayObject

The downto method returns an array reference containing integer decreasing
values down to and including the limit. This method returns a
L<Data::Object::Array> object.

=over 4

=item downto example

  # given 10

  $number->downto(5); # [10,9,8,7,6,5]

=back

=cut

=head2 eq

  eq(Any $arg1) : NumObject

The eq method performs a numeric equality operation. This method returns a
L<Data::Object::Number> object representing a boolean.

=over 4

=item eq example

  # given 12345

  $number->eq(12346); # 0

=back

=cut

=head2 exp

  exp() : NumObject

The exp method returns e (the natural logarithm base) to the power of the
number. This method returns a L<Data::Object::Float> object.

=over 4

=item exp example

  # given 0

  $number->exp; # 1

  # given 1

  $number->exp; # 2.71828182845905

  # given 1.5

  $number->exp; # 4.48168907033806

=back

=cut

=head2 ge

  ge(Any $arg1) : NumObject

The ge method returns true if the argument provided is greater-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=over 4

=item ge example

  # given 0

  $number->ge(0); # 1

=back

=cut

=head2 gt

  gt(Any $arg1) : NumObject

The gt method performs a numeric greater-than comparison. This method returns a
L<Data::Object::Number> object representing a boolean.

=over 4

=item gt example

  # given 99

  $number->gt(50); # 1

=back

=cut

=head2 hex

  hex() : Str

The hex method returns a hex string representing the value of the number. This
method returns a L<Data::Object::String> object.

=over 4

=item hex example

  # given 175

  $number->hex; # 0xaf

=back

=cut

=head2 incr

  incr(Num $arg1) : NumObject

The incr method returns the numeric number incremented by 1. This method returns
a data type object to be determined after execution.

=over 4

=item incr example

  # given 123456789

  $number->incr; # 123456790

=back

=cut

=head2 int

  int() : IntObject

The int method returns the integer portion of the number. Do not use this
method for rounding. This method returns a L<Data::Object::Number> object.

=over 4

=item int example

  # given 12.5

  $number->int; # 12

=back

=cut

=head2 le

  le(Any $arg1) : NumObject

The le method returns true if the argument provided is less-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=over 4

=item le example

  # given 0

  $number->le; # 0

=back

=cut

=head2 log

  log() : FloatObject

The log method returns the natural logarithm (base e) of the number. This method
returns a L<Data::Object::Float> object.

=over 4

=item log example

  # given 12345

  $number->log; # 9.42100640177928

=back

=cut

=head2 lt

  lt(Any $arg1) : NumObject

The lt method performs a numeric less-than comparison. This method returns a
L<Data::Object::Number> object representing a boolean.

=over 4

=item lt example

  # given 86

  $number->lt(88); # 1

=back

=cut

=head2 mod

  mod() : NumObject

The mod method returns the division remainder of the number divided by the
argment. This method returns a L<Data::Object::Number> object.

=over 4

=item mod example

  # given 12

  $number->mod(1); # 0
  $number->mod(2); # 0
  $number->mod(3); # 0
  $number->mod(4); # 0
  $number->mod(5); # 2

=back

=cut

=head2 ne

  ne(Any $arg1) : NumObject

The ne method performs a numeric equality operation. This method returns a
L<Data::Object::Number> object representing a boolean.

=over 4

=item ne example

  # given -100

  $number->ne(100); # 1

=back

=cut

=head2 neg

  neg() : IntObject

The neg method returns a negative version of the number. This method returns a
L<Data::Object::Integer> object.

=over 4

=item neg example

  # given 12345

  $number->neg; # -12345

=back

=cut

=head2 pow

  pow() : NumObject

The pow method returns a number, the result of a math operation, which is the
number to the power of the argument. This method returns a
L<Data::Object::Number> object.

=over 4

=item pow example

  # given 12345

  $number->pow(3); # 1881365963625

=back

=cut

=head2 sin

  sin() : IntObject

The sin method returns the sine of the number (expressed in radians). This
method returns a data type object to be determined after execution.

=over 4

=item sin example

  # given 12345

  $number->sin; # -0.993771636455681

=back

=cut

=head2 sqrt

  sqrt(Int $arg1) : IntObject

The sqrt method returns the positive square root of the number. This method
returns a data type object to be determined after execution.

=over 4

=item sqrt example

  # given 12345

  $number->sqrt; # 111.108055513541

=back

=cut

=head2 to

  to(Int $arg1) : ArrayObject

The to method returns an array reference containing integer increasing or
decreasing values to and including the limit in ascending or descending order
based on the value of the floating-point object. This method returns a
L<Data::Object::Array> object.

=over 4

=item to example

  # given 5

  $number->to(9); # [5,6,7,8,9]
  $number->to(1); # [5,4,3,2,1]

=back

=cut

=head2 upto

  upto(Int $arg1) : Any

The upto method returns an array reference containing integer increasing
values up to and including the limit. This method returns a
L<Data::Object::Array> object.

=over 4

=item upto example

  # given 23

  $number->upto(25); # [23,24,25]

=back

=cut

=head1 CREDITS

Al Newkirk, C<+303>

Anthony Brummett, C<+10>

Adam Hopkins, C<+1>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

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