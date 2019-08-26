package Data::Object::Base::Undef;

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

  if (defined $data) {
    croak('Instantiation Error: Not an Undef');
  }

  return bless \$data, $class;
}

1;
=encoding utf8

=head1 NAME

Data::Object::Base::Undef

=cut

=head1 ABSTRACT

Data-Object Abstract Undef Class

=cut

=head1 SYNOPSIS

  package My::Undef;

  use parent 'Data::Object::Base::Undef';

  my $undef = My::Undef->new(undef);

=cut

=head1 DESCRIPTION

Data::Object::Base::Undef provides routines for operating on Perl 5 undefined
data.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(Undef $arg1) : Object

The new method expects an undefined value and returns a new class instance.

=over 4

=item new example

  # given undef

  package My::Undef;

  use parent 'Data::Object::Base::Undef';

  my $undef = My::Undef->new(undef);

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