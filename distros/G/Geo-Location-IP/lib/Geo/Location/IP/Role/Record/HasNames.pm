package Geo::Location::IP::Role::Record::HasNames;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

role Geo::Location::IP::Role::Record::HasNames;

our $VERSION = 0.003;

field $names :param :reader;
field $name :reader;

#<<<
ADJUST :params (:$locales) {
    for my $locale (@{$locales}) {
        if (exists $names->{$locale}) {
            $name = $names->{$locale};
            last;
        }
    }
}
#>>>

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Role::Record::HasConfidence - Add the fields "name" and "names"

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  apply Geo::Location::IP::Role::Record::HasNames;

=head1 DESCRIPTION

A mixin that adds the fields C<name> and C<names> to a class.

Requires a C<locales> parameter such as ['zh-CN', 'en'].

=head1 SUBROUTINES/METHODS

=head2 name

  my $name = $obj->name;

Returns the object's localized name or the undefined value.

=head2 names

  my %names = %{$obj->names};

Returns a hash reference that maps locale codes to localized names.

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
