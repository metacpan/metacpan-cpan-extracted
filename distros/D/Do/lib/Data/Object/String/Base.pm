package Data::Object::String::Base;

use 5.014;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();

use parent 'Data::Object::Base';

our $VERSION = '1.07'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  if (Scalar::Util::blessed($data) && $data->can('detract')) {
    $data = $data->detract;
  }

  $data = $data ? "$data" : "";

  if (!defined($data) || ref($data)) {
    Carp::confess('Instantiation Error: Not a String');
  }

  return bless \$data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::String::Base

=cut

=head1 ABSTRACT

Data-Object Abstract String Class

=cut

=head1 SYNOPSIS

  package My::String;

  use parent 'Data::Object::String::Base';

  my $string = My::String->new('abcedfghi');

=cut

=head1 DESCRIPTION

Data::Object::String::Base provides routines for operating on Perl 5 string
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

  use parent 'Data::Object::String::Base';

  my $string = My::String->new('abcedfghi');

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