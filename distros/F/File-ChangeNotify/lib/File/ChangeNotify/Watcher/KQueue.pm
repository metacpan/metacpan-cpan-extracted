package File::ChangeNotify::Watcher::KQueue;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.31';

use File::Find qw( find );
use IO::KQueue;
use Types::Standard qw( HashRef Int );
use Type::Utils qw( class_type );

use Moo;

has absorb_delay => (
    is      => 'ro',
    isa     => Int,
    default => 100,
);

has _kqueue => (
    is       => 'ro',
    isa      => class_type('IO::KQueue'),
    default  => sub { IO::KQueue->new },
    init_arg => undef,
);

# We need to keep hold of filehandles for all the directories *and* files in the
# tree. KQueue events will be automatically deleted when the filehandles go out
# of scope.
has _files => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub { {} },
    init_arg => undef,
);

with 'File::ChangeNotify::Watcher';

sub sees_all_events {0}

sub BUILD {
    my $self = shift;

    $self->_watch_dir($_) for @{ $self->directories };

    $self->_set_map( $self->_current_map )
        if $self->modify_includes_file_attributes
        || $self->modify_includes_content;

    return;
}

sub wait_for_events {
    my $self = shift;

    while (1) {
        my @events = $self->_interesting_events;
        return @events if @events;
    }
}

around new_events => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig(0);
};

sub _interesting_events {
    my $self    = shift;
    my $timeout = shift;

    my @kevents = $self->_kqueue->kevent( defined $timeout ? $timeout : () );

    # Events come in groups, wait for a short period to absorb any extra ones
    # that might happen immediately after the ones we've detected.
    push @kevents, $self->_kqueue->kevent( $self->absorb_delay )
        if $self->absorb_delay;

    my ( $old_map, $new_map );
    if (   $self->modify_includes_file_attributes
        || $self->modify_includes_content ) {
        $old_map = $self->_map;
        $new_map = $self->_current_map;
    }

    my @events;
    for my $kevent (@kevents) {
        my $path = $kevent->[KQ_UDATA];
        next if $self->_path_is_excluded($path);

        my $flags = $kevent->[KQ_FFLAGS];

        ## no critic (ControlStructures::ProhibitCascadingIfElse)

        # Delete - this works reasonably well with KQueue
        if ( $flags & NOTE_DELETE ) {
            delete $self->_files->{$path};
            push @events, $self->_event( $path, 'delete' );
        }

        # Rename - represented as deletes and creates
        elsif ( $flags & NOTE_RENAME ) {

            # Renamed dirs
            # Use the stored filehandle (it survives renaming) to identify a dir
            # and remove any filehandles we're storing to its contents
            my $fh = $self->_files->{$path};
            if ( -d $fh ) {
                for my $stored_path ( keys %{ $self->_files } ) {
                    next unless index( $stored_path, $path ) == 0;
                    delete $self->_files->{$stored_path};
                    push @events, $self->_event( $stored_path, 'delete' );
                }
            }

            # Renamed files
            else {
                delete $self->_files->{$path};
                push @events, $self->_event( $path, 'delete' );
            }
        }

        # Modify/Create - writes to files indicate modification, but we get
        # writes to dirs too, which indicates a file (or dir) was created or
        # removed from the dir. Deletes are picked up by delete events, but to
        # find created files we have to scan the dir again.
        elsif ( $flags & NOTE_WRITE ) {

            if ( -f $path ) {
                push @events,
                    $self->_event( $path, 'modify', $old_map, $new_map );
            }
            elsif ( -d $path ) {
                push @events,
                    map { $self->_event( $_, 'create' ) }
                    $self->_watch_dir($path);
            }
        }
        elsif ( $flags & NOTE_ATTRIB ) {
            push @events,
                $self->_event( $path, 'modify', $old_map, $new_map );
        }
    }

    $self->_set_map($new_map)
        if $self->_has_map;

    return @events;
}

sub _event {
    my $self    = shift;
    my $path    = shift;
    my $type    = shift;
    my $old_map = shift;
    my $new_map = shift;

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

sub _watch_dir {
    my $self = shift;
    my $dir  = shift;

    my @new_files;

    # use find(), finddepth() doesn't support pruning
    $self->_find(
        $dir,
        sub {
            my $path = $File::Find::name;

            # Don't monitor anything below excluded dirs
            return $File::Find::prune = 1
                if $self->_path_is_excluded($path);

            # Skip file names that don't match the filter
            return unless $self->_is_included_file($path);

            # Skip if we're watching it already
            return if $self->_files->{$path};

            $self->_watch_path($path);
            push @new_files, $path;
        }
    );

    return @new_files;
}

sub _is_included_file {
    my $self = shift;
    my $path = shift;

    return 1 if -d $path;

    my $filter   = $self->filter;
    my $filename = ( File::Spec->splitpath($path) )[2];

    return 1 if $filename =~ m{$filter};
    return 0;
}

sub _find {
    my $self   = shift;
    my $dir    = shift;
    my $wanted = shift;

    find(
        {
            wanted      => $wanted,
            no_chdir    => 1,
            follow_fast => ( $self->follow_symlinks ? 1 : 0 ),
            follow_skip => 2,
        },
        $dir,
    );
}

sub _watch_path {
    my $self = shift;
    my $path = shift;

    ## no critic (InputOutput::RequireBriefOpen)

    # Don't panic if we can't open a file
    open my $fh, '<', $path or warn "Can't open '$path': $!";
    return unless $fh && defined fileno $fh;

    # Store this filehandle (this will automatically nuke any existing events
    # assigned to the file)
    $self->_files->{$path} = $fh;

    my $filter = NOTE_DELETE | NOTE_WRITE | NOTE_RENAME | NOTE_REVOKE;
    $filter |= NOTE_ATTRIB
        if $self->_path_matches(
        $self->modify_includes_file_attributes,
        $path
        );

    $self->_kqueue->EV_SET(
        fileno($fh),
        EVFILT_VNODE,
        EV_ADD | EV_CLEAR,
        $filter,
        0,
        $path,
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

File::ChangeNotify::Watcher::KQueue - KQueue-based watcher subclass

=head1 DESCRIPTION

This class implements watching using L<IO::KQueue>, which must be installed
for it to work. This is a BSD alternative to Linux's Inotify and other
event-based systems.

=head1 CAVEATS

Although this watcher is more efficient and accurate than the
C<File::ChangeNotify::Watcher::Default> class, in order to monitor files and
directories, it must open filehandles to each of them. Because many BSD
systems have relatively low defaults for the maximum number of files each
process can open, you may find you run out of file descriptors.

On FreeBSD, you can check (and alter) your system's settings with C<sysctl> if
necessary. The important keys are: C<kern.maxfiles> and
C<kern.maxfilesperproc>.  You can see how many files your system current has
open with C<kern.openfiles>.

On OpenBSD, the C<sysctl> keys are C<kern.maxfiles> and C<kern.nfiles>.
Per-process limits are set in F</etc/login.conf>. See L<login.conf(5)> for
details.

=head1 AUTHOR

Dan Thomas, E<lt>dan@cpan.orgE<gt>

=cut
