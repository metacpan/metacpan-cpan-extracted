package Data::Object::Hash::Base;

use 5.014;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();

use parent 'Data::Object::Base';

our $VERSION = '1.50'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  if (Scalar::Util::blessed($data) && $data->can('detract')) {
    $data = $data->detract;
  }

  unless (ref($data) eq 'HASH') {
    Carp::confess('Instantiation Error: Not a HashRef');
  }

  return bless $data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Hash::Base

=cut

=head1 ABSTRACT

Data-Object Abstract Hash Class

=cut

=head1 SYNOPSIS

  package My::Hash;

  use parent 'Data::Object::Hash::Base';

  my $hash = My::Hash->new({1..4});

=cut

=head1 DESCRIPTION

This package provides routines for operating on Perl 5 hash references.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Data::Object::Base>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(HashRef $arg1) : Object

The new method expects a list or hash reference and returns a new class
instance.

=over 4

=item new example

  # given 1..4

  package My::Hash;

  use parent 'Data::Object::Hash::Base';

  my $hash = My::Hash->new({1..4});

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