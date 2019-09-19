package Do;

use 5.014;

use strict;
use warnings;

use parent 'Data::Object';

our $VERSION = '1.80'; # VERSION

1;

=encoding utf8

=head1 NAME

Do

=cut

=head1 ABSTRACT

Modern Perl

=cut

=head1 SYNOPSIS

  package main;

  use Do;

  fun greeting($name) {
    "Hello $name";
  }

  say greeting("world");

  1;

=cut

=head1 DESCRIPTION

This package aims to provide a modern Perl development framework and
foundational set of types, functions, classes, patterns, and interfaces for
jump-starting application development. This package inherits all behavior from
L<Data::Object>; please see that documentation to learn more, or review
L<Data::Object::Use>.

=cut

=head1 INSTALLATION

If you have cpanm, you only need one line:

  $ cpanm -qn Do

If you don't have cpanm, get it! It takes less than a minute, otherwise:

  $ curl -L https://cpanmin.us | perl - -qn Do

Add C<Do> to the list of dependencies in C<cpanfile>:

  requires "Do" => "1.80"; # 1.80 or newer

If cpanm doesn't have permission to install modules in the current Perl
installation, it will automatically set up and install to a local::lib in your
home directory.  See the L<local::lib|local::lib> documentation for details on
enabling it in your environment. We recommend using a
L<Perlbrew|https://github.com/gugod/app-perlbrew> or
L<Plenv|https://github.com/tokuhirom/plenv> environment. These tools will help
you manage multiple Perl installations in your C<$HOME> directory. They are
completely isolated Perl installations.

=head1 CREDITS

Al Newkirk, C<+303>

Anthony Brummett, C<+10>

Adam Hopkins, C<+1>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

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