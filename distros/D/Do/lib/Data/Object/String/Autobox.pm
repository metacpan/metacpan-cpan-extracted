package Data::Object::String::Autobox;

use 5.014;

use strict;
use warnings;

use Role::Tiny::With;

with 'Data::Object::Role::Proxyable';

our $VERSION = '1.88'; # VERSION

# BUILD

sub BUILDPROXY {
  my ($class, $method, $data, @args) = @_;

  return sub {
    require Data::Object::String;

    if (!(Scalar::Util::blessed($data) && $data->isa('Data::Object::String'))) {
      $data = Data::Object::String->new($data);
    }

    return $data->$method(@args);
  };
}

1;

=encoding utf8

=head1 NAME

Data::Object::String::Autobox

=cut

=head1 ABSTRACT

Data-Object String Class Autoboxing

=cut

=head1 SYNOPSIS

  use Data::Object::String::Autobox;

=cut

=head1 DESCRIPTION

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::String> objects.

=head1 ROLES

This package assumes all behavior from the follow roles:

L<Data::Object::Role::Proxyable>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 CREDITS

Al Newkirk, C<+319>

Anthony Brummett, C<+10>

Adam Hopkins, C<+2>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated here,
https://github.com/iamalnewkirk/do/blob/master/LICENSE.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/do/wiki>

L<Project|https://github.com/iamalnewkirk/do>

L<Initiatives|https://github.com/iamalnewkirk/do/projects>

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