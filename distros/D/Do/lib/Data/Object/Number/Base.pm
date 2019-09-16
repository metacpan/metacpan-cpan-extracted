package Data::Object::Number::Base;

use 5.014;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();

use parent 'Data::Object::Base';

our $VERSION = '1.76'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  $data //= 0;

  if (Scalar::Util::blessed($data) && $data->can('detract')) {
    $data = $data->detract;
  }

  if (defined $data) {
    $data =~ s/^\+//; # not keen on this but ...
  }

  if (!defined($data) || ref($data)) {
    Carp::confess('Instantiation Error: Not a Number');
  }

  if (!Scalar::Util::looks_like_number($data)) {
    Carp::confess('Instantiation Error: Not an Number');
  }

  $data += 0 unless $data =~ /[a-zA-Z]/;

  return bless \$data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Number::Base

=cut

=head1 ABSTRACT

Data-Object Abstract Number Class

=cut

=head1 SYNOPSIS

  package My::Number;

  use parent 'Data::Object::Number::Base';

  my $number = My::Number->new(1_000_000);

=cut

=head1 DESCRIPTION

This package provides routines for operating on Perl 5 numeric data. If no
argument is provided, this package is instantiated with a default value of
C<0>.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Data::Object::Base>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(Int $arg1) : Object

The new method expects a number and returns a new class instance.

=over 4

=item new example

  # given 1_000_000

  package My::Number;

  use parent 'Data::Object::Number::Base';

  my $number = My::Number->new(1_000_000);

=back

=cut

=head1 CREDITS

Al Newkirk, C<+296>

Anthony Brummett, C<+10>

José Joaquín Atria, C<+1>

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