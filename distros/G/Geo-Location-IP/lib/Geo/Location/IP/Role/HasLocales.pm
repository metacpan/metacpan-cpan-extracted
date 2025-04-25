package Geo::Location::IP::Role::HasLocales;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

role Geo::Location::IP::Role::HasLocales;

our $VERSION = 0.004;

field $locales :param :reader = ['en'];

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Role::HasLocales - Add a "locales" field

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  apply Geo::Location::IP::Role::HasLocales;

=head1 DESCRIPTION

A mixin that adds the field C<locales> to a class.

=head1 SUBROUTINES/METHODS

=head2 locales

  my @locales = @{$obj->locales};

Returns an array reference of locale codes such as ['zh-CN', 'en'].

=for Pod::Coverage DOES META new

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
