package KiokuDB::Role::ID;
BEGIN {
  $KiokuDB::Role::ID::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Role::ID::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: A role for objects who choose their own ID.

use namespace::clean -except => 'meta';

requires "kiokudb_object_id";

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Role::ID - A role for objects who choose their own ID.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    # typically you set up your own ID role, and map the C<kiokudb_object_id>
    # method to your schema's ID

    package MySchema::ID;
    use Moose::Role;

    with qw(KiokuDB::Role::ID);

    sub kiokudb_object_id { shift->id };

    requires "id";




    package MySchema::Foo;
    use Moose;

    with qw(MySchema::ID);

    sub id { ... }

=head1 DESCRIPTION

This role provides a way for objects to determine their own IDs.

You must implement or alias the C<kiokudb_object_id> method to return a string.

=head1 REQUIRED METHODS

=over 4

=item kiokudb_object_id

Should return a string to be used as the ID of the object.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
