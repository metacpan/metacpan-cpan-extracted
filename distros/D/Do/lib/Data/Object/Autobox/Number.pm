package Data::Object::Autobox::Number;

use 5.014;

use strict;
use warnings;

use Data::Object ();

our $VERSION = '1.05'; # VERSION

# BUILD

sub new {
  Data::Object->number(pop);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Autobox::Number

=cut

=head1 ABSTRACT

Data-Object Autoboxing for Number Objects

=cut

=head1 SYNOPSIS

  use Data::Object::Autobox::Number;

=cut

=head1 DESCRIPTION

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::Number> objects.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(Num $arg1) : NumberObject

Construct a new object.

=over 4

=item new example

  my $number = Data::Object::Autobox::Number->new(1_000);

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