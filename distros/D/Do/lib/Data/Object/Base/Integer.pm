package Data::Object::Base::Integer;

use strict;
use warnings;

use Carp 'croak';
use Scalar::Util 'blessed', 'looks_like_number';

use parent 'Data::Object::Base';

our $VERSION = '1.02'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  my $role = 'Data::Object::Role::Detract';

  if (blessed($data) && $data->can('does') && $data->does($role)) {
    $data = $data->detract;
  }

  $data = "$data" if $data;

  if (defined $data) {
    $data =~ s/^\+//; # not keen on this but ...
  }

  if (!defined($data) || ref($data)) {
    croak('Instantiation Error: Not an Integer');
  }

  if (!looks_like_number($data)) {
    croak('Instantiation Error: Not an Integer');
  }

  $data += 0 unless $data =~ /[a-zA-Z]/;

  return bless \$data, $class;
}

1;
=encoding utf8

=head1 NAME

Data::Object::Base::Integer

=cut

=head1 ABSTRACT

Data-Object Abstract Integer Class

=cut

=head1 SYNOPSIS

  package My::Integer;

  use parent 'Data::Object::Base::Integer';

  my $integer = My::Integer->new(9);

=cut

=head1 DESCRIPTION

Data::Object::Base::Integer provides routines for operating on Perl 5 integer
data.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(Int $arg1) : Object

The new method expects a number and returns a new class instance.

=over 4

=item new example

  # given 9

  package My::Integer;

  use parent 'Data::Object::Base::Integer';

  my $integer = My::Integer->new(9);

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