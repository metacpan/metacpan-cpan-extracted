package Data::Object::Autobox::Integer;

use 5.014;

use strict;
use warnings;

use Data::Object ();

our $VERSION = '1.05'; # VERSION

# BUILD

sub new {
  Data::Object->integer(pop);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Autobox::Integer

=cut

=head1 ABSTRACT

Data-Object Autoboxing for Integer Objects

=cut

=head1 SYNOPSIS

  use Data::Object::Autobox::Integer;

=cut

=head1 DESCRIPTION

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::Integer> objects.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(Int $arg1) : IntegerObject

Construct a new object.

=over 4

=item new example

  my $integer = Data::Object::Autobox::Integer->new(1_000);

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<GitHub|https://github.com/iamalnewkirk/do>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/README-DEVEL.mkdn>

L<Reporting|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Data::Object::Class>

L<Data::Object::Role>

L<Data::Object::Rule>

L<Data::Object::Library>

L<Data::Object::Signatures>

=cut