package Data::Object::Struct;

use strict;
use warnings;

use Data::Object::Class;

with 'Data::Object::Role::Immutable';

our $VERSION = '1.02'; # VERSION

# BUILD

sub BUILD {
  my ($self, $args) = @_;

  $self->immutable;

  return $args;
}

1;
=encoding utf8

=head1 NAME

Data::Object::Struct

=cut

=head1 ABSTRACT

Data-Object Struct Declaration

=cut

=head1 SYNOPSIS

  package Environment;

  use Data::Object::Struct;

  has 'mode';

  1;

=cut

=head1 DESCRIPTION

This package modifies the consuming package making it a struct.

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