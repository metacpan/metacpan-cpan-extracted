package Data::Object::Hash::Autobox;

use 5.014;

use strict;
use warnings;

use Role::Tiny::With;

with 'Data::Object::Role::Proxyable';

our $VERSION = '1.50'; # VERSION

# BUILD

sub BUILDPROXY {
  my ($class, $method, $data, @args) = @_;

  return sub {
    require Data::Object::Hash;

    if (!(Scalar::Util::blessed($data) && $data->isa('Data::Object::Hash'))) {
      $data = Data::Object::Hash->new($data);
    }

    return $data->$method(@args);
  };
}

1;

=encoding utf8

=head1 NAME

Data::Object::Hash::Autobox

=cut

=head1 ABSTRACT

Data-Object Hash Class Autoboxing

=cut

=head1 SYNOPSIS

  use Data::Object::Hash::Autobox;

=cut

=head1 DESCRIPTION

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::Hash> objects.

=head1 ROLES

This package assumes all behavior from the follow roles:

L<Data::Object::Role::Proxyable>

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