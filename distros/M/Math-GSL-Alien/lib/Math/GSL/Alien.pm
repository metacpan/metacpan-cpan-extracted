package Math::GSL::Alien;

use strict;
use warnings;
use 5.008001;

our $VERSION = '1.05';

use base 'Alien::Base';
use Role::Tiny::With qw( with );

with 'Alien::Role::Dino';

1;

=encoding UTF-8

=head1 NAME

Math::GSL::Alien - Easy installation of the GSL library

=head1 SYNOPSIS

  # Build.PL
  use Math::GSL::Alien;
  use Module::Build 0.28; # need at least 0.28

  my $builder = Module::Build->new(
    configure_requires => {
      'Math::GSL::Alien' => '1.00', # first release
    },
    ...
    extra_compiler_flags => Alien::GSL->cflags,
    extra_linker_flags   => Alien::GSL->libs,
    ...
  );

  $builder->create_build_script;


  # lib/MyLibrary/GSL.pm
  package MyLibrary::GSL;

  use Math::GSL::Alien; # dynaload gsl

  ...

=head1 DESCRIPTION

Provides the Gnu Scientific Library (GSL) for use by Perl modules, installing it if necessary.
This module relies heavily on the L<Alien::Base> system to do so.
To avoid documentation skew, the author asks the reader to learn about the capabilities provided by that module rather than repeating them here.

The difference between this module and L<Alien::GSL>
is that this module will download and install a shared version of the GSL library,
whereas C<Alien::GSL> will install a static version of the GSL library.
The shared version is needed by L<Math::GSL>,
see L<Alien::GSL-#17|https://github.com/PerlAlien/Alien-GSL/issues/17>.
It will also reduce the size of the generated Perl XS libraries (C<.so>, C<.xs.dll>).

=head1 SEE ALSO

=over

=item *

L<Alien::Base>

=item *

L<PDL::Modules/"GNU SCIENTIFIC LIBRARY">

=item *

L<PerlGSL>

=item *

L<Math::GSL>

=back

=head1 SOURCE REPOSITORY

L<https://github.com/PerlAlien/Alien-GSL>

=head1 AUTHOR

=over 4

=item Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=item Håkon Hægland, E<lt>hakon.hagland@gmail.comE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2015 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


