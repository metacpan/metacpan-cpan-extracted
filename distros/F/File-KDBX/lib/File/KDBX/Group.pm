package File::KDBX::Group;
# ABSTRACT: A KDBX database group

use warnings;
use strict;

use Devel::GlobalDestruction;
use File::KDBX::Constants qw(:bool :icon :iteration);
use File::KDBX::Error;
use File::KDBX::Iterator;
use File::KDBX::Util qw(:assert :class :coercion generate_uuid);
use Hash::Util::FieldHash;
use List::Util qw(any sum0);
use Ref::Util qw(is_coderef is_ref);
use Scalar::Util qw(blessed);
use Time::Piece;
use boolean;
use namespace::clean;

extends 'File::KDBX::Object';

our $VERSION = '0.901'; # VERSION


# has uuid                        => sub { generate_uuid(printable => 1) };
has name                        => '',          coerce => \&to_string;
has notes                       => '',          coerce => \&to_string;
has tags                        => '',          coerce => \&to_string;
has icon_id                     => ICON_FOLDER, coerce => \&to_icon_constant;
has custom_icon_uuid            => undef,       coerce => \&to_uuid;
has is_expanded                 => false,       coerce => \&to_bool;
has default_auto_type_sequence  => '',          coerce => \&to_string;
has enable_auto_type            => undef,       coerce => \&to_tristate;
has enable_searching            => undef,       coerce => \&to_tristate;
has last_top_visible_entry      => undef,       coerce => \&to_uuid;
# has custom_data                 => {};
has previous_parent_group       => undef,       coerce => \&to_uuid;
# has entries                     => [];
# has groups                      => [];
has times                       => {};

has last_modification_time  => sub { gmtime }, store => 'times', coerce => \&to_time;
has creation_time           => sub { gmtime }, store => 'times', coerce => \&to_time;
has last_access_time        => sub { gmtime }, store => 'times', coerce => \&to_time;
has expiry_time             => sub { gmtime }, store => 'times', coerce => \&to_time;
has expires                 => false,          store => 'times', coerce => \&to_bool;
has usage_count             => 0,              store => 'times', coerce => \&to_number;
has location_changed        => sub { gmtime }, store => 'times', coerce => \&to_time;

my @ATTRS = qw(uuid custom_data entries groups);
sub _set_nonlazy_attributes {
    my $self = shift;
    $self->$_ for @ATTRS, list_attributes(ref $self);
}

sub uuid {
    my $self = shift;
    if (@_ || !defined $self->{uuid}) {
        my %args = @_ % 2 == 1 ? (uuid => shift, @_) : @_;
        my $old_uuid = $self->{uuid};
        my $uuid = $self->{uuid} = delete $args{uuid} // generate_uuid;
        $self->_signal('uuid.changed', $uuid, $old_uuid) if defined $old_uuid;
    }
    $self->{uuid};
}

##############################################################################


sub entries {
    my $self = shift;
    my $entries = $self->{entries} //= [];
    if (@$entries && !blessed($entries->[0])) {
        @$entries = map { $self->_wrap_entry($_, $self->kdbx) } @$entries;
    }
    assert { !any { !blessed $_ } @$entries };
    return $entries;
}


sub entries_deeply {
    my $self = shift;
    my %args = @_;

    my $searching   = delete $args{searching};
    my $auto_type   = delete $args{auto_type};
    my $history     = delete $args{history};

    my $groups = $self->groups_deeply(%args);
    my @entries;

    return File::KDBX::Iterator->new(sub {
        if (!@entries) {
            while (my $group = $groups->next) {
                next if $searching && !$group->effective_enable_searching;
                next if $auto_type && !$group->effective_enable_auto_type;
                @entries = @{$group->entries};
                @entries = grep { $_->auto_type->{enabled} } @entries if $auto_type;
                @entries = map { ($_, @{$_->history}) } @entries if $history;
                last if @entries;
            }
        }
        shift @entries;
    });
}


sub add_entry {
    my $self = shift;
    my $entry   = @_ % 2 == 1 ? shift : undef;
    my %args    = @_;

    my $kdbx = delete $args{kdbx} // eval { $self->kdbx };

    $entry = $self->_wrap_entry($entry // [%args]);
    $entry->uuid;
    $entry->kdbx($kdbx) if $kdbx;

    push @{$self->{entries} ||= []}, $entry->remove;
    return $entry->_set_group($self)->_signal('added', $self);
}


sub remove_entry {
    my $self = shift;
    my $uuid = is_ref($_[0]) ? $self->_wrap_entry(shift)->uuid : shift;
    my %args = @_;
    my $objects = $self->{entries};
    for (my $i = 0; $i < @$objects; ++$i) {
        my $object = $objects->[$i];
        next if $uuid ne $object->uuid;
        $object->_set_group(undef);
        $object->_signal('removed') if $args{signal} // 1;
        return splice @$objects, $i, 1;
    }
}

##############################################################################


sub groups {
    my $self = shift;
    my $groups = $self->{groups} //= [];
    if (@$groups && !blessed($groups->[0])) {
        @$groups = map { $self->_wrap_group($_, $self->kdbx) } @$groups;
    }
    assert { !any { !blessed $_ } @$groups };
    return $groups;
}


sub groups_deeply {
    my $self = shift;
    my %args = @_;

    my @groups = ($args{inclusive} // 1) ? $self : @{$self->groups};
    my $algo = lc($args{algorithm} || 'ids');

    if ($algo eq ITERATION_DFS) {
        my %visited;
        return File::KDBX::Iterator->new(sub {
            my $next = shift @groups or return;
            if (!$visited{Hash::Util::FieldHash::id($next)}++) {
                while (my @children = @{$next->groups}) {
                    unshift @groups, @children, $next;
                    $next = shift @groups;
                    $visited{Hash::Util::FieldHash::id($next)}++;
                }
            }
            $next;
        });
    }
    elsif ($algo eq ITERATION_BFS) {
        return File::KDBX::Iterator->new(sub {
            my $next = shift @groups or return;
            push @groups, @{$next->groups};
            $next;
        });
    }
    return File::KDBX::Iterator->new(sub {
        my $next = shift @groups or return;
        unshift @groups, @{$next->groups};
        $next;
    });
}

sub _kpx_groups { shift->groups(@_) }


sub add_group {
    my $self    = shift;
    my $group   = @_ % 2 == 1 ? shift : undef;
    my %args    = @_;

    my $kdbx = delete $args{kdbx} // eval { $self->kdbx };

    $group = $self->_wrap_group($group // [%args]);
    $group->uuid;
    $group->kdbx($kdbx) if $kdbx;

    push @{$self->{groups} ||= []}, $group->remove;
    return $group->_set_group($self)->_signal('added', $self);
}


sub remove_group {
    my $self = shift;
    my $uuid = is_ref($_[0]) ? $self->_wrap_group(shift)->uuid : shift;
    my %args = @_;
    my $objects = $self->{groups};
    for (my $i = 0; $i < @$objects; ++$i) {
        my $object = $objects->[$i];
        next if $uuid ne $object->uuid;
        $object->_set_group(undef);
        $object->_signal('removed') if $args{signal} // 1;
        return splice @$objects, $i, 1;
    }
}

##############################################################################


sub objects_deeply {
    my $self = shift;
    my %args = @_;

    my $searching   = delete $args{searching};
    my $auto_type   = delete $args{auto_type};
    my $history     = delete $args{history};

    my $groups = $self->groups_deeply(%args);
    my @entries;

    return File::KDBX::Iterator->new(sub {
        if (!@entries) {
            while (my $group = $groups->next) {
                next if $searching && !$group->effective_enable_searching;
                next if $auto_type && !$group->effective_enable_auto_type;
                @entries = @{$group->entries};
                @entries = grep { $_->auto_type->{enabled} } @entries if $auto_type;
                @entries = map { ($_, @{$_->history}) } @entries if $history;
                return $group;
            }
        }
        shift @entries;
    });
}


sub add_object {
    my $self = shift;
    my $obj  = shift;
    if ($obj->isa('File::KDBX::Entry')) {
        $self->add_entry($obj);
    }
    elsif ($obj->isa('File::KDBX::Group')) {
        $self->add_group($obj);
    }
}


sub remove_object {
    my $self = shift;
    my $object = shift;
    my $blessed = blessed($object);
    return $self->remove_group($object, @_) if $blessed && $object->isa('File::KDBX::Group');
    return $self->remove_entry($object, @_) if $blessed && $object->isa('File::KDBX::Entry');
    return $self->remove_group($object, @_) || $self->remove_entry($object, @_);
}

##############################################################################


sub effective_default_auto_type_sequence {
    my $self = shift;
    my $sequence = $self->default_auto_type_sequence;
    return $sequence if defined $sequence;

    my $parent = $self->group or return '{USERNAME}{TAB}{PASSWORD}{ENTER}';
    return $parent->effective_default_auto_type_sequence;
}


sub effective_enable_auto_type {
    my $self = shift;
    my $enabled = $self->enable_auto_type;
    return $enabled if defined $enabled;

    my $parent = $self->group or return true;
    return $parent->effective_enable_auto_type;
}


sub effective_enable_searching {
    my $self = shift;
    my $enabled = $self->enable_searching;
    return $enabled if defined $enabled;

    my $parent = $self->group or return true;
    return $parent->effective_enable_searching;
}

##############################################################################


sub is_empty {
    my $self = shift;
    return @{$self->groups} == 0 && @{$self->entries} == 0;
}


sub is_root {
    my $self = shift;
    my $kdbx = eval { $self->kdbx } or return FALSE;
    return Hash::Util::FieldHash::id($kdbx->root) == Hash::Util::FieldHash::id($self);
}


sub is_recycle_bin {
    my $self    = shift;
    my $kdbx    = eval { $self->kdbx } or return FALSE;
    my $group   = $kdbx->recycle_bin;
    return $group && Hash::Util::FieldHash::id($group) == Hash::Util::FieldHash::id($self);
}


sub is_entry_templates {
    my $self    = shift;
    my $kdbx    = eval { $self->kdbx } or return FALSE;
    my $group   = $kdbx->entry_templates;
    return $group && Hash::Util::FieldHash::id($group) == Hash::Util::FieldHash::id($self);
}


sub is_last_selected {
    my $self    = shift;
    my $kdbx    = eval { $self->kdbx } or return FALSE;
    my $group   = $kdbx->last_selected;
    return $group && Hash::Util::FieldHash::id($group) == Hash::Util::FieldHash::id($self);
}


sub is_last_top_visible {
    my $self    = shift;
    my $kdbx    = eval { $self->kdbx } or return FALSE;
    my $group   = $kdbx->last_top_visible;
    return $group && Hash::Util::FieldHash::id($group) == Hash::Util::FieldHash::id($self);
}


sub path {
    my $self = shift;
    return $self->name if $self->is_root;
    my $lineage = $self->lineage or return;
    my @parts = (@$lineage, $self);
    shift @parts;
    return join('.', map { $_->name } @parts);
}


sub size {
    my $self = shift;
    return sum0 map { $_->size } @{$self->groups}, @{$self->entries};
}


sub depth { $_[0]->is_root ? 0 : (scalar @{$_[0]->lineage || []} || -1) }

sub _signal {
    my $self = shift;
    my $type = shift;
    return $self->SUPER::_signal("group.$type", @_);
}

sub _commit {
    my $self = shift;
    my $time = gmtime;
    $self->last_modification_time($time);
    $self->last_access_time($time);
}

sub label { shift->name(@_) }

### Name of the parent attribute expected to contain the object
sub _parent_container { 'groups' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Group - A KDBX database group

=head1 VERSION

version 0.901

=head1 DESCRIPTION

A group in a KDBX database is a type of object that can contain entries and other groups.

There is also some metadata associated with a group. Each group in a database is identified uniquely by
a UUID. An entry can also have an icon associated with it, and there are various timestamps. Take a look at
the attributes to see what's available.

=head1 ATTRIBUTES

=head2 name

The human-readable name of the group.

=head2 notes

Free form text string associated with the group.

=head2 is_expanded

Whether or not subgroups are visible when listed for user selection.

=head2 default_auto_type_sequence

The default auto-type keystroke sequence, inheritable by entries and subgroups.

=head2 enable_auto_type

Whether or not the entry is eligible to be matched for auto-typing, inheritable by entries and subgroups.

=head2 enable_searching

Whether or not entries within the group can show up in search results, inheritable by subgroups.

=head2 last_top_visible_entry

The UUID of the entry visible at the top of the list.

=head2 entries

Array of entries contained within the group.

=head2 groups

Array of subgroups contained within the group.

=head1 METHODS

=head2 entries

    \@entries = $group->entries;

Get an array of direct child entries within a group.

=head2 entries_deeply

    \&iterator = $kdbx->entries_deeply(%options);

Get an L<File::KDBX::Iterator> over I<entries> within a group. Supports the same options as L</groups>,
plus some new ones:

=over 4

=item *

C<auto_type> - Only include entries with auto-type enabled (default: false, include all)

=item *

C<searching> - Only include entries within groups with searching enabled (default: false, include all)

=item *

C<history> - Also include historical entries (default: false, include only current entries)

=back

=head2 add_entry

    $entry = $group->add_entry($entry);
    $entry = $group->add_entry(%entry_attributes);

Add an entry to a group. If C<$entry> already has a parent group, it will be removed from that group before
being added to C<$group>.

=head2 remove_entry

    $entry = $group->remove_entry($entry);
    $entry = $group->remove_entry($entry_uuid);

Remove an entry from a group's array of entries. Returns the entry removed or C<undef> if nothing removed.

=head2 groups

    \@groups = $group->groups;

Get an array of direct subgroups within a group.

=head2 groups_deeply

    \&iterator = $group->groups_deeply(%options);

Get an L<File::KDBX::Iterator> over I<groups> within a groups, deeply. Options:

=over 4

=item *

C<inclusive> - Include C<$group> itself in the results (default: true)

=item *

C<algorithm> - Search algorithm, one of C<ids>, C<bfs> or C<dfs> (default: C<ids>)

=back

=head2 add_group

    $new_group = $group->add_group($new_group);
    $new_group = $group->add_group(%group_attributes);

Add a group to a group. If C<$new_group> already has a parent group, it will be removed from that group before
being added to C<$group>.

=head2 remove_group

    $removed_group = $group->remove_group($group);
    $removed_group = $group->remove_group($group_uuid);

Remove a group from a group's array of subgroups. Returns the group removed or C<undef> if nothing removed.

=head2 objects_deeply

    \&iterator = $groups->objects_deeply(%options);

Get an L<File::KDBX::Iterator> over I<objects> within a group, deeply. Groups and entries are considered
objects, so this is essentially a combination of L</groups> and L</entries>. This won't often be useful, but
it can be convenient for maintenance tasks. This method takes the same options as L</groups> and L</entries>.

=head2 add_object

    $new_entry = $group->add_object($new_entry);
    $new_group = $group->add_object($new_group);

Add an object (either a L<File::KDBX::Entry> or a L<File::KDBX::Group>) to a group. This is the generic
equivalent of the object forms of L</add_entry> and L</add_group>.

=head2 remove_object

    $group->remove_object($entry);
    $group->remove_object($group);

Remove an object (either a L<File::KDBX::Entry> or a L<File::KDBX::Group>) from a group. This is the generic
equivalent of the object forms of L</remove_entry> and L</remove_group>.

=head2 effective_default_auto_type_sequence

    $text = $group->effective_default_auto_type_sequence;

Get the value of L</default_auto_type_sequence>, if set, or get the inherited effective default auto-type
sequence of the parent.

=head2 effective_enable_auto_type

    $text = $group->effective_enable_auto_type;

Get the value of L</enable_auto_type>, if set, or get the inherited effective auto-type enabled value of the
parent.

=head2 effective_enable_searching

    $text = $group->effective_enable_searching;

Get the value of L</enable_searching>, if set, or get the inherited effective searching enabled value of the
parent.

=head2 is_empty

    $bool = $group->is_empty;

Get whether or not the group is empty (has no subgroups or entries).

=head2 is_root

    $bool = $group->is_root;

Determine if a group is the root group of its connected database.

=head2 is_recycle_bin

    $bool = $group->is_recycle_bin;

Get whether or not a group is the recycle bin of its connected database.

=head2 is_entry_templates

    $bool = $group->is_entry_templates;

Get whether or not a group is the group containing entry template in its connected database.

=head2 is_last_selected

    $bool = $group->is_last_selected;

Get whether or not a group is the prior selected group of its connected database.

=head2 is_last_top_visible

    $bool = $group->is_last_top_visible;

Get whether or not a group is the latest top visible group of its connected database.

=head2 path

    $string = $group->path;

Get a string representation of a group's lineage. This is used as the substitution value for the
C<{GROUP_PATH}> placeholder. See L<File::KDBX::Entry/Placeholders>.

For a root group, the path is simply the name of the group. For deeper groups, the path is a period-separated
sequence of group names between the root group and C<$group>, including C<$group> but I<not> the root group.
In other words, paths of deeper groups leave the root group name out.

    Database
    -> Root         # path is "Root"
       -> Foo       # path is "Foo"
          -> Bar    # path is "Foo.Bar"

Yeah, it doesn't make much sense to me, either, but this matches the behavior of KeePass.

=head2 size

    $size = $group->size;

Get the size (in bytes) of a group, including the size of all subroups and entries, if any.

=head2 depth

    $depth = $group->depth;

Get the depth of a group within a database. The root group is at depth 0, its direct children are at depth 1,
etc. A group not in a database tree structure returns a depth of -1.

=for Pod::Coverage times

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KDBX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
