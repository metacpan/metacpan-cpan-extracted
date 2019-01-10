package File::ChangeNotify::Watcher;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.31';

use Fcntl qw( S_IMODE );
use File::ChangeNotify::Event;
use File::Find qw( find );
use File::Spec;
use Module::Runtime qw( use_module );
use Types::Standard
    qw( ArrayRef Bool ClassName CodeRef HashRef Num RegexpRef Str );
use Type::Utils -all;

# Trying to import this just blows up on Win32, and checking
# Time::HiRes::d_hires_stat() _also_ blows up on Win32.
BEGIN {
    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    eval {
        require Time::HiRes;
        Time::HiRes->import('stat');
    };
}

use Moo::Role;

has filter => (
    is      => 'ro',
    isa     => RegexpRef,
    default => sub {qr/.*/},
);

#<<<
my $dir_t = subtype as Str,
    where { -d $_ },
    message { "$_ is not a valid directory" };

my $array_of_dirs_t = subtype as ArrayRef[Str],
    where {
        map {-d} @{$_};
    },
    message {"@{$_} is not a list of valid directories"};

coerce $array_of_dirs_t,
    from $dir_t,
    via { [$_] };
#>>>

has directories => (
    is       => 'ro',
    writer   => '_set_directories',
    isa      => $array_of_dirs_t,
    required => 1,
    coerce   => 1,
);

has follow_symlinks => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has event_class => (
    is      => 'ro',
    isa     => ClassName,
    default => 'File::ChangeNotify::Event',
);

has sleep_interval => (
    is      => 'ro',
    isa     => Num,
    default => 2,
);

my $files_or_regexps_or_code_t
    = subtype as ArrayRef [ Str | RegexpRef | CodeRef ];

has exclude => (
    is      => 'ro',
    isa     => $files_or_regexps_or_code_t,
    default => sub { [] },
);

has modify_includes_file_attributes => (
    is      => 'ro',
    isa     => Bool | $files_or_regexps_or_code_t,
    default => 0,
);

has modify_includes_content => (
    is      => 'ro',
    isa     => Bool | $files_or_regexps_or_code_t,
    default => 0,
);

has _map => (
    is        => 'ro',
    writer    => '_set_map',
    isa       => HashRef,
    predicate => '_has_map',
);

sub BUILD {
    my $self = shift;

    use_module( $self->event_class );
}

## no critic ( Subroutines::ProhibitUnusedPrivateSubroutines)
sub _current_map {
    my $self = shift;

    my %map;

    find(
        {
            wanted => sub {

                # File::Find seems to use '/' as the path separator on Windows
                # for some odd reason. It really should be using File::Spec
                # internally everywhere but it doesn't.
                my $path
                    = $^O eq 'MSWin32'
                    ? File::Spec->canonpath($File::Find::name)
                    : $File::Find::name;

                if ( $self->_path_is_excluded($path) ) {
                    $File::Find::prune = 1;
                    return;
                }

                my $entry = $self->_entry_for_map($path) or return;
                $map{$path} = $entry;
            },
            follow_fast => ( $self->follow_symlinks ? 1 : 0 ),
            no_chdir    => 1,
            follow_skip => 2,
        },
        @{ $self->directories },
    );

    return \%map;
}
## use critic

sub _path_is_excluded {
    my $self = shift;
    my $path = shift;

    return $self->_path_matches( $self->exclude, $path );
}

sub _entry_for_map {
    my $self = shift;
    my $path = shift;

    my $is_dir = -d $path ? 1 : 0;

    # This should be free since the stat call was already done when checking
    # -d.
    my @stat = stat;

    return if -l $path && !$is_dir;

    unless ($is_dir) {
        my $filter = $self->filter;
        return unless ( File::Spec->splitpath($path) )[2] =~ /$filter/;
    }

    return {
        is_dir => $is_dir,
        size   => ( $is_dir ? 0 : $stat[7] ),
        $self->_maybe_file_attributes( $path, \@stat ),
        ( $is_dir ? () : $self->_maybe_content($path) ),
    };
}

sub _maybe_file_attributes {
    my $self = shift;
    my $path = shift;
    my $stat = shift;

    # The Default watcher always requires the mtime, regardless of whether or
    # not we're including stat info in the modify events.
    unless ( $self->_always_requires_mtime ) {
        return
            unless $self->_path_matches(
            $self->modify_includes_file_attributes,
            $path,
            );
    }

    return ( stat => $self->_stat( $path, $stat ) );
}

sub _stat {
    my $self = shift;
    my $path = shift;
    my $stat = shift;

    my @stat = $stat ? @{$stat} : stat $path;
    return {
        attributes => {
            permissions => S_IMODE( $stat[2] ),
            uid         => $stat[4],
            gid         => $stat[5],
        },
        mtime => $stat[9],
    };
}

sub _always_requires_mtime {0}

sub _maybe_content {
    my $self = shift;
    my $path = shift;

    return
        unless $self->_path_matches( $self->modify_includes_content, $path );

    open my $fh, '<', $path or die "Cannot open $path for reading: $!";
    binmode $fh, ':bytes' or die qq{Cannot binmode $path as ':bytes': $!};
    my $content = do {
        local $/ = undef;
        <$fh>;
    };
    close $fh or die "Cannot close $path: $!";

    return ( content => $content );
}

sub new_events {
    my $self = shift;

    return $self->_interesting_events;
}

## no critic ( Subroutines::ProhibitUnusedPrivateSubroutines)
sub _modify_event_maybe_file_attribute_changes {
    my $self    = shift;
    my $path    = shift;
    my $old_map = shift;
    my $new_map = shift;

    return
        unless $self->_path_matches(
        $self->modify_includes_file_attributes,
        $path,
        );

    my $old_attr = $old_map->{$path}{stat}{attributes};
    my $new_attr = $new_map->{$path}{stat}{attributes};

    for my $k ( keys %{$new_attr} ) {

        # Any possible info retrieved from stat will be numeric, so we can
        # always use numeric comparison safely.
        return ( attributes => [ $old_attr, $new_attr ] )
            if $old_attr->{$k} != $new_attr->{$k};
    }

    return;
}

sub _modify_event_maybe_content_changes {
    my $self    = shift;
    my $path    = shift;
    my $old_map = shift;
    my $new_map = shift;

    return
        unless $self->_path_matches( $self->modify_includes_content, $path );
    return (
        content => [ $old_map->{$path}{content}, $new_map->{$path}{content} ]
    );
}

sub _path_matches {
    my $self    = shift;
    my $matches = shift;
    my $path    = shift;

    return $matches if !ref $matches;

    foreach my $matcher ( @{$matches} ) {
        if ( my $ref = ref $matcher ) {
            if ( $ref eq 'Regexp' ) {
                return 1 if $path =~ /$matcher/;
            }
            elsif ( $ref eq 'CODE' ) {
                local $_ = $path;
                return 1 if $matcher->($path);
            }
        }
        else {
            return 1 if $path eq $matcher;
        }
    }

    return;
}

sub _remove_directory {
    my $self = shift;
    my $dir  = shift;

    $self->_set_directories(
        [ grep { $_ ne $dir } @{ $self->directories } ] );
}
## use critic

1;

# ABSTRACT: Role consumed by all watchers

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ChangeNotify::Watcher - Role consumed by all watchers

=head1 VERSION

version 0.31

=head1 SYNOPSIS

    my $watcher =
        File::ChangeNotify->instantiate_watcher
            ( directories => [ '/my/path', '/my/other' ],
              filter      => qr/\.(?:pm|conf|yml)$/,
              exclude     => ['t', 'root', qr(/(?!\.)[^/]+$),
		              sub { -e && ! -r }],
            );

    if ( my @events = $watcher->new_events ) { ... }

    # blocking
    while ( my @events = $watcher->wait_for_events ) { ... }

=head1 DESCRIPTION

A C<File::ChangeNotify::Watcher> monitors a directory for changes made to any
file. You can provide a regular expression to filter out files you are not
interested in. It handles the addition of new subdirectories by adding them to
the watch list.

Note that the actual granularity of what each watcher class reports may
vary. Implementations that hook into some sort of kernel event interface
(Inotify, for example) have much better knowledge of exactly what changes are
happening than one implemented purely in userspace code (like the Default
class).

By default, events are returned in the form of L<File::ChangeNotify::Event>
objects, but this can be overridden by providing an "event_class" attribute to
the constructor.

You can block while waiting for events or do a non-blocking call asking for
any new events since the last call (or since the watcher was
instantiated). Different watchers will implement blocking in different ways,
and the Default watcher just does a sleep loop.

=head1 METHODS

=head2 File::ChangeNotify::Watcher::Subclass->new(...)

This method creates a new watcher. It accepts the following arguments:

=over 4

=item * directories => $path

=item * directories => \@paths

This argument is required. It can be either one or many paths which
should be watched for changes.

=item * filter => qr/.../

This is an optional regular expression that will be used to check if a
file is of interest. This filter is only applied to files.

By default, all files are included.

=item * exclude => [...]

An optional arrayref of paths to exclude. This arrayref can contain plain
strings, regular expressions, or subroutine references. If you provide a
string it should contain the complete path to be excluded.

If you provide a sub, it should return a true value for paths to be excluded
e.g. C<< exclude => [ sub { -e && ! -r } ], >>. The path will be passed as the
first argument to the subroutine as well as in a localized C<$_>.

The paths can be either directories or specific files. If the exclusion
matches a directory, all of its files and subdirectories are ignored.

=item * modify_includes_file_attributes

This can either be a boolean or an arrayref.

If it is an arrayref then it should contain paths for which you want
information about changes to the file's attributes. This arrayref can contain
plain strings, regular expressions, or subroutine references. If you provide a
string it should contain the complete path to be excluded.

When this matches a file, then modify events for that file will include
information about the file's before and after permissions and ownership when
these change.

See the L<File::ChangeNotify::Event> documentation for details on what this
looks like.

=item * modify_includes_content

This can either be a boolean or an arrayref.

If it is an arrayref then it should contain paths for which you want to see
past and current content for a file when it is modified. This arrayref can
contain plain strings, regular expressions, or subroutine references. If you
provide a string it should contain the complete path to be excluded.

When this matches a file, then modify events for that file will include
information about the file's before and after content when it changes.

See the L<File::ChangeNotify::Event> documentation for details on what this
looks like.

=item * follow_symlinks => $bool

By default, symlinks are ignored. Set this to true to follow them.

If this symlinks are being followed, symlinks to files and directories
will be followed. Directories will be watched, and changes for
directories and files reported.

=item * sleep_interval => $number

For watchers which call C<sleep> to implement the C<<
$watcher->wait_for_events >> method, this argument controls how long
it sleeps for. The value is a number in seconds.

The default is 2 seconds.

=item * event_class => $class

This can be used to change the class used to report events. By
default, this is L<File::ChangeNotify::Event>.

=back

=head2 $watcher->wait_for_events

This method causes the watcher to block until it sees interesting
events, and then return them as a list.

Some watcher subclasses may implement blocking as a sleep loop, while
others may actually block.

=head2 $watcher->new_events

This method returns a list of any interesting events seen since the
last time the watcher checked.

=head2 $watcher->sees_all_events

If this is true, the watcher will report on all events.

Some watchers, like the Default subclass, are not smart enough to
track things like a file being created and then immediately deleted,
and can only detect changes between snapshots of the file system.

Other watchers, like the Inotify subclass, see all events that happen
and report on them.

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
