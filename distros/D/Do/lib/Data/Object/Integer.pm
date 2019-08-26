package Data::Object::Integer;

use Try::Tiny;
use Role::Tiny::With;

use Data::Object::Export qw(
  cast
  croak
  load
);

map with($_), my @roles = qw(
  Data::Object::Role::Detract
  Data::Object::Role::Dumper
  Data::Object::Role::Output
  Data::Object::Role::Throwable
);

map with($_), my @rules = qw(
  Data::Object::Rule::Comparison
  Data::Object::Rule::Defined
);

use overload (
  '""'     => 'data',
  '~~'     => 'data',
  fallback => 1
);

use parent 'Data::Object::Base::Integer';

our $VERSION = '1.02'; # VERSION

# BUILD
# METHODS

sub roles {
  return cast([@roles]);
}

sub rules {
  return cast([@rules]);
}

# DISPATCHERS

sub defined {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Integer::Defined';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub downto {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Integer::Downto';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub eq {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Integer::Eq';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub ge {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Integer::Ge';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub gt {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Integer::Gt';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub le {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Integer::Le';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub lt {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Integer::Lt';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub ne {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Integer::Ne';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub to {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Integer::To';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub upto {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Integer::Upto';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

1;
=encoding utf8

=head1 NAME

Data::Object::Integer

=cut

=head1 ABSTRACT

Data-Object Integer Class

=cut

=head1 SYNOPSIS

  use Data::Object::Integer;

  my $integer = Data::Object::Integer->new(9);

=cut

=head1 DESCRIPTION

This package provides routines for operating on Perl 5 integer data.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 defined

  defined() : NumObject

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false. This method returns a
L<Data::Object::Number> object.

=over 4

=item defined example

  # given $integer

  $integer->defined; # 1

=back

=cut

=head2 downto

  downto(Int $arg1) : ArrayObject

The downto method returns an array reference containing integer decreasing
values down to and including the limit. This method returns a
L<Data::Object::Array> object.

=over 4

=item downto example

  # given 1

  $integer->downto(0); # [1,0]

=back

=cut

=head2 eq

  eq(Any $arg1) : NumObject

The eq method performs a numeric equality operation. This method returns a
L<Data::Object::Number> object representing a boolean.

=over 4

=item eq example

  # given 1

  $integer->eq(1); # 1

=back

=cut

=head2 ge

  ge(Any $arg1) : NumObject

The ge method returns true if the argument provided is greater-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=over 4

=item ge example

  # given 1

  $integer->ge(0); # 1

=back

=cut

=head2 gt

  gt(Any $arg1) : NumObject

The gt method performs a numeric greater-than comparison. This method returns a
L<Data::Object::Number> object representing a boolean.

=over 4

=item gt example

  # given 1

  $integer->gt(1); # 0

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

  $integer->le(1); # 1

=back

=cut

=head2 lt

  lt(Any $arg1) : NumObject

The lt method performs a numeric less-than comparison. This method returns a
L<Data::Object::Number> object representing a boolean.

=over 4

=item lt example

  # given 1

  $integer->lt(1); # 0

=back

=cut

=head2 ne

  ne(Any $arg1) : NumObject

The ne method performs a numeric equality operation. This method returns a
L<Data::Object::Number> object representing a boolean.

=over 4

=item ne example

  # given 1

  $integer->ne(0); # 1

=back

=cut

=head2 roles

  roles() : ArrayRef

The roles method returns the list of roles attached to object. This method
returns a L<Data::Object::Array> object.

=over 4

=item roles example

  # given $integer

  $integer->roles;

=back

=cut

=head2 rules

  rules() : ArrayRef

The rules method returns consumed rules.

=over 4

=item rules example

  my $rules = $integer->rules();

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

  # given 1

  $integer->to(2); # [1,2]
  $integer->to(0); # [1,0]

=back

=cut

=head2 upto

  upto(Int $arg1) : Any

The upto method returns an array reference containing integer increasing
values up to and including the limit. This method returns a
L<Data::Object::Array> object.

=over 4

=item upto example

  # given 1

  $integer->upto(2); # [1,2]

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