package Data::Object::Autobox;

use 5.014;

use strict;
use warnings;

use base 'autobox';

require Data::Object::Array::Autobox;
require Data::Object::Code::Autobox;
require Data::Object::Float::Autobox;
require Data::Object::Hash::Autobox;
require Data::Object::Number::Autobox;
require Data::Object::Scalar::Autobox;
require Data::Object::String::Autobox;
require Data::Object::Undef::Autobox;

our $VERSION = '1.70'; # VERSION

sub import {
  my ($class) = @_;

  $class->SUPER::import(
    ARRAY     => 'Data::Object::Array::Autobox',
    CODE      => 'Data::Object::Code::Autobox',
    FLOAT     => 'Data::Object::Float::Autobox',
    HASH      => 'Data::Object::Hash::Autobox',
    INTEGER   => 'Data::Object::Number::Autobox',
    NUMBER    => 'Data::Object::Number::Autobox',
    SCALAR    => 'Data::Object::Scalar::Autobox',
    STRING    => 'Data::Object::String::Autobox',
    UNDEF     => 'Data::Object::Undef::Autobox',
    UNIVERSAL => 'Data::Object::Scalar::Autobox'
  );

  return $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Autobox

=cut

=head1 ABSTRACT

Data-Object Autoboxing

=cut

=head1 SYNOPSIS

  use Data::Object::Autobox;

  my $input  = [1,1,1,1,3,3,2,1,5,6,7,8,9];
  my $output = $input->grep(sub{$_[0] < 5})->unique->sort; # [1,2,3]

  $output->join(',')->print; # 1,2,3

  $object->isa('Data::Object::Array');

=cut

=head1 DESCRIPTION

This package implements autoboxing via L<autobox> to provide
L<boxing|http://en.wikipedia.org/wiki/Object_type_(object-oriented_programming)>
for native Perl 5 data types.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<autobox>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 CREDITS

Al Newkirk, C<+287>

Anthony Brummett, C<+10>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<GitHub|https://github.com/iamalnewkirk/do>

L<Projects|https://github.com/iamalnewkirk/do/projects>

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