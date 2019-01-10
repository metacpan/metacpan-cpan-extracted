package File::ChangeNotify::Watcher::Inotify;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.31';

use File::Find qw( find );
use Linux::Inotify2 1.2;
use Types::Standard qw( Bool Int );
use Type::Utils qw( class_type );

use Moo;

has is_blocking => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has _inotify => (
    is      => 'ro',
    isa     => class_type('Linux::Inotify2'),
    default => sub {
        Linux::Inotify2->new
            or die "Cannot construct a Linux::Inotify2 object: $!";
    },
    init_arg => undef,
);

has _mask => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    builder => '_build_mask',
);

with 'File::ChangeNotify::Watcher';

sub sees_all_events {1}

sub BUILD {
    my $self = shift;

    $self->_inotify->blocking( $self->is_blocking );

    # If this is done via a lazy_build then the call to
    # ->_watch_directory ends up causing endless recursion when it
    # calls ->_inotify itself.
    $self->_watch_directory($_) for @{ $self->directories };

    $self->_set_map( $self->_current_map )
        if $self->modify_includes_file_attributes
        || $self->modify_includes_content;

    return;
}

sub wait_for_events {
    my $self = shift;

    $self->_inotify->blocking(1);

    while (1) {
        my @events = $self->_interesting_events;
        return @events if @events;
    }
}

around new_events => sub {
    my $orig = shift;
    my $self = shift;

    $self->_inotify->blocking(0);

    return $self->$orig(@_);
};

sub _interesting_events {
    my $self = shift;

    # This may be a blocking read, in which case it will not return until
    # something happens. For Catalyst, the restarter will end up calling
    # ->wait_for_events again after handling the changes.
    my @events = $self->_inotify->read;

    my ( $old_map, $new_map );
    if (   $self->modify_includes_file_attributes
        || $self->modify_includes_content ) {
        $old_map = $self->_map;
        $new_map = $self->_current_map;
    }

    my $filter = $self->filter;

    my @interesting;
    for my $event (@events) {

        # An excluded path will show up here if ...
        #
        # Something created a new directory and that directory needs to be
        # excluded or when the exclusion excludes a file, not a dir.
        next if $self->_path_is_excluded( $event->fullname );

        ## no critic (ControlStructures::ProhibitCascadingIfElse)
        if ( $event->IN_CREATE && $event->IN_ISDIR ) {
            $self->_watch_directory( $event->fullname );
            push @interesting, $event;
            push @interesting,
                $self->_fake_events_for_new_dir( $event->fullname );
        }
        elsif ( $event->IN_DELETE_SELF ) {
            $self->_remove_directory( $event->fullname );
        }
        elsif ( $event->IN_ATTRIB ) {
            next
                unless $self->_path_matches(
                $self->modify_includes_file_attributes,
                $event->fullname
                );
            push @interesting, $event;
        }

        # We just want to check the _file_ name
        elsif ( $event->name =~ /$filter/ ) {
            push @interesting, $event;
        }
    }

    $self->_set_map($new_map)
        if $self->_has_map;

    return map {
              $_->can('path')
            ? $_
            : $self->_convert_event( $_, $old_map, $new_map )
    } @interesting;
}

sub _build_mask {
    my $self = shift;

    my $mask
        = IN_MODIFY | IN_CREATE | IN_DELETE | IN_DELETE_SELF | IN_MOVE_SELF
        | IN_MOVED_TO;
    $mask |= IN_DONT_FOLLOW unless $self->follow_symlinks;
    $mask |= IN_ATTRIB if $self->modify_includes_file_attributes;

    return $mask;
}

sub _watch_directory {
    my $self = shift;
    my $dir  = shift;

    # A directory could be created & then deleted before we get a
    # chance to act on it.
    return unless -d $dir;

    find(
        {
            wanted => sub {
                my $path = $File::Find::name;

                if ( $self->_path_is_excluded($path) ) {
                    $File::Find::prune = 1;
                    return;
                }
                $self->_add_watch_if_dir($path);
            },
            follow_fast => ( $self->follow_symlinks ? 1 : 0 ),
            no_chdir    => 1,
            follow_skip => 2,
        },
        $dir
    );
}

sub _add_watch_if_dir {
    my $self = shift;
    my $path = shift;

    return if -l $path && !$self->follow_symlinks;

    return unless -d $path;
    return if $self->_path_is_excluded($path);

    $self->_inotify->watch( $path, $self->_mask );
}

sub _fake_events_for_new_dir {
    my $self = shift;
    my $dir  = shift;

    return unless -d $dir;

    my @events;
    File::Find::find(
        {
            wanted => sub {
                my $path = $File::Find::name;

                return if $path eq $dir;
                if ( $self->_path_is_excluded($path) ) {
                    $File::Find::prune = 1;
                    return;
                }

                push @events,
                    $self->event_class->new(
                    path => $path,
                    type => 'create',
                    );
            },
            follow_fast => ( $self->follow_symlinks ? 1 : 0 ),
            no_chdir    => 1
        },
        $dir
    );

    return @events;
}

sub _convert_event {
    my $self    = shift;
    my $event   = shift;
    my $old_map = shift;
    my $new_map = shift;

    my $path = $event->fullname;
    my $type
        = $event->IN_CREATE || $event->IN_MOVED_TO ? 'create'
        : $event->IN_MODIFY || $event->IN_ATTRIB   ? 'modify'
        : $event->IN_DELETE ? 'delete'
        :                     'unknown';

    my @extra;
    if (
        $type eq 'modify'
        && (   $self->modify_includes_file_attributes
            || $self->modify_includes_content )
    ) {

        @extra = (
            $self->_modify_event_maybe_file_attribute_changes(
                $path, $old_map, $new_map
            ),
            $self->_modify_event_maybe_content_changes(
                $path, $old_map, $new_map
            ),
        );
    }

    return $self->event_class->new(
        path => $path,
        type => $type,
        @extra,
    );
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Inotify-based watcher subclass

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ChangeNotify::Watcher::Inotify - Inotify-based watcher subclass

=head1 VERSION

version 0.31

=head1 DESCRIPTION

This class implements watching by using the L<Linux::Inotify2>
module. This only works on Linux 2.6.13 or newer.

This watcher is much more efficient and accurate than the
C<File::ChangeNotify::Watcher::Default> class.

=head1 SUPPORT

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=File-ChangeNotify> or via email to L<bug-file-changenotify@rt.cpan.org|mailto:bug-file-changenotify@rt.cpan.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for File-ChangeNotify can be found at L<https://github.com/houseabsolute/File-ChangeNotify>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 - 2019 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
