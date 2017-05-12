package KiokuDB::Role::Immutable;
BEGIN {
  $KiokuDB::Role::Immutable::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Role::Immutable::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: A role for objects that are never updated.

use namespace::clean -except => 'meta';



__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Role::Immutable - A role for objects that are never updated.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    with qw(KiokuDB::Role::Immutable);

=head1 DESCRIPTION

This is a role for objects that are never updated after they are inserted to
the database.

The object will be skipped entirely on all update/store operations unless it is
being collapsed for the first time, and its child objects will B<not> be
updated unless they are found while collapsing another object.

This means that:

    my $immutable = $kiokudb->lookup($id);

    $immutable->child->name("foo");

    $kiokudb->update($immutable);

will not work, you need to update the child directly:

    $kiokudb->update($immutable->child);

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
