package Data::Object::Autobox;

use 5.014;

use strict;
use warnings;

use base 'autobox';

require Data::Object::Autobox::Array;
require Data::Object::Autobox::Code;
require Data::Object::Autobox::Float;
require Data::Object::Autobox::Hash;
require Data::Object::Autobox::Integer;
require Data::Object::Autobox::Number;
require Data::Object::Autobox::Scalar;
require Data::Object::Autobox::String;
require Data::Object::Autobox::Undef;
require Data::Object::Autobox::Any;

our $VERSION = '1.02'; # VERSION

sub import {
  my ($class) = @_;

  $class->SUPER::import(
    ARRAY     => 'Data::Object::Autobox::Array',
    CODE      => 'Data::Object::Autobox::Code',
    FLOAT     => 'Data::Object::Autobox::Float',
    HASH      => 'Data::Object::Autobox::Hash',
    INTEGER   => 'Data::Object::Autobox::Integer',
    NUMBER    => 'Data::Object::Autobox::Number',
    SCALAR    => 'Data::Object::Autobox::Scalar',
    STRING    => 'Data::Object::Autobox::String',
    UNDEF     => 'Data::Object::Autobox::Undef',
    UNIVERSAL => 'Data::Object::Autobox::Any'
  );

  return;
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