package KiokuDB::Role::Upgrade::Data;
BEGIN {
  $KiokuDB::Role::Upgrade::Data::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Role::Upgrade::Data::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Classes that provide their own upgrade routine.

use namespace::clean;

requires "kiokudb_upgrade_data";

# ex: set sw=4 et:

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Role::Upgrade::Data - Classes that provide their own upgrade routine.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    with qw(KiokuDB::Role::Upgrade::Data);

    sub kiokudb_upgrade_data {
        my ( $class, %args ) = @_;

        # convert the data from the old version of the class to the new version
        # as necessary

        $args{entry}->derive(
            class_version => our $VERSION,
            ...
        );
    }

=head1 DESCRIPTION

This class allows you to take control the data conversion process completely
(there is only one handler per class, not one handler per version with this
approach).

See L<KiokuDB::Role::Upgrade::Handlers::Table> for a more DWIM approach, and
L<KiokuDB::TypeMap::Entry::MOP> for more details.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
