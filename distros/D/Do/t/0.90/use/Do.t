use 5.014;

use strict;
use warnings;

use Test::More;

=name

Do

=abstract

Modern Perl

=synopsis

  package main;

  use Do;

  fun greeting($name) {
    "Hello $name";
  }

  say greeting("world");

  1;

=description

This package aims to provide a modern Perl development framework and
foundational set of types, functions, classes, patterns, and interfaces for
jump-starting application development. This package inherits all behavior from
L<Data::Object>; please see that documentation to learn more, or review
L<Data::Object::Use>.

=headers

+=head1 INSTALLATION

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

=cut

use_ok "Do";

ok 1 and done_testing;
