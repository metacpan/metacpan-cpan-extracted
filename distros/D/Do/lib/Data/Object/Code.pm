package Data::Object::Code;

use 5.014;

use strict;
use warnings;

use Role::Tiny::With;

use overload (
  '""'     => 'detract',
  '~~'     => 'detract',
  '&{}'    => 'self',
  fallback => 1
);

with qw(
  Data::Object::Role::Detract
  Data::Object::Role::Dumper
  Data::Object::Role::Functable
  Data::Object::Role::Throwable
);

use parent 'Data::Object::Code::Base';

our $VERSION = '1.07'; # VERSION

# METHODS

sub self {
  return shift;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Code

=cut

=head1 ABSTRACT

Data-Object Code Class

=cut

=head1 SYNOPSIS

  use Data::Object::Code;

  my $code = Data::Object::Code->new(sub { shift + 1 });

=cut

=head1 DESCRIPTION

This package provides routines for operating on Perl 5 code references.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 self

  self() : Object

The self method returns the calling object (noop).

=over 4

=item self example

  my $self = $code->self();

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