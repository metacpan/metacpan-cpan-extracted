package Data::Object::Base::Array;

use strict;
use warnings;

use Carp 'croak';
use Scalar::Util 'blessed';

use parent 'Data::Object::Base';

our $VERSION = '1.02'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  my $role = 'Data::Object::Role::Detract';

  if (blessed($data) && $data->can('does') && $data->does($role)) {
    $data = $data->detract;
  }

  unless (ref($data) eq 'ARRAY') {
    croak('Instantiation Error: Not a ArrayRef');
  }

  return bless $data, $class;
}

1;
=encoding utf8

=head1 NAME

Data::Object::Base::Array

=cut

=head1 ABSTRACT

Data-Object Abstract Array Class

=cut

=head1 SYNOPSIS

  use Data::Object::Base::Array;

  my $array = Data::Object::Base::Array->new([1..9]);

=cut

=head1 DESCRIPTION

Data::Object::Base::Array provides routines for operating on Perl 5 array
references.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(ArrayRef $arg1) : Object

The new method expects a list or array reference and returns a new class
instance.

=over 4

=item new example

  package My::Array;

  use parent 'Data::Object::Base::Array';

  # given 1..9

  my $array = My::Array->new([1..9]);

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