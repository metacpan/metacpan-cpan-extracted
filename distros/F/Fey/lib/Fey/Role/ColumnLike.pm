package Fey::Role::ColumnLike;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.43';

use Moose::Role;

# This seems weird, but basically we're saying that column-like things
# do these four roles, but the implementation is different for
# column-like things (than for example, selectable things).
with(
    'Fey::Role::Selectable' => { -excludes => 'is_selectable' },
    'Fey::Role::Comparable' => { -excludes => 'is_comparable' },
    'Fey::Role::Groupable'  => { -excludes => 'is_groupable' },
    'Fey::Role::Orderable'  => { -excludes => 'is_orderable' },
);

requires '_build_id', 'is_alias';

sub _containing_table_name_or_alias {
    my $t = $_[0]->table();

    $t->is_alias() ? $t->alias_name() : $t->name();
}

sub is_selectable { return $_[0]->table() ? 1 : 0 }

sub is_comparable { return $_[0]->table() ? 1 : 0 }

sub is_groupable { return $_[0]->table() ? 1 : 0 }

sub is_orderable { return $_[0]->table() ? 1 : 0 }

1;

# ABSTRACT: A role for "column-like" behavior

__END__

=pod

=head1 NAME

Fey::Role::ColumnLike - A role for "column-like" behavior

=head1 VERSION

version 0.43

=head1 SYNOPSIS

  use Moose 2.1200;

  with 'Fey::Role::ColumnLike';

=head1 DESCRIPTION

Class which do this role are "column-like" . This role aggregates
several other roles for the L<Fey::Column> and L<Fey::Column::Alias>
classes.

=head1 METHODS

This role provides the following methods:

=head2 $column->is_selectable()

=head2 $column->is_comparable()

=head2 $column->is_groupable()

=head2 $column->is_orderable()

These methods all return true when the C<< $column->table() >>
returns an object.

=head1 ROLES

This class does the C<Fey::Role::Selectable>,
C<Fey::Role::Comparable>, C<Fey::Role::Groupable>, and
C<Fey::Role::Orderable> roles.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
