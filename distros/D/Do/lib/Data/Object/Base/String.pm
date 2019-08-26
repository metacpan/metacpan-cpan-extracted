package Data::Object::Base::String;

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

  $data = $data ? "$data" : "";

  if (!defined($data) || ref($data)) {
    croak('Instantiation Error: Not a String');
  }

  return bless \$data, $class;
}

1;
=encoding utf8

=head1 NAME

Data::Object::Base::String

=cut

=head1 ABSTRACT

Data-Object Abstract String Class

=cut

=head1 SYNOPSIS

  package My::String;

  use parent 'Data::Object::Base::String';

  my $string = My::String->new('abcedfghi');

=cut

=head1 DESCRIPTION

Data::Object::Base::String provides routines for operating on Perl 5 string
data.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(Str $arg1) : Object

The new method expects a string and returns a new class instance.

=over 4

=item new example

  # given abcedfghi

  package My::String;

  use parent 'Data::Object::Base::String';

  my $string = My::String->new('abcedfghi');

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