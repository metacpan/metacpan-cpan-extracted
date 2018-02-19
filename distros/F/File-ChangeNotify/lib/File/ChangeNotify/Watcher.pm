package File::ChangeNotify::Watcher;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.28';

use Class::Load qw( load_class );
use File::ChangeNotify::Event;
use Types::Standard qw( ArrayRef Bool ClassName CodeRef Num RegexpRef Str );
use Type::Utils -all;

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

sub BUILD {
    my $self = shift;

    load_class( $self->event_class() );
}

sub new_events {
    my $self = shift;

    return $self->_interesting_events();
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _path_is_excluded {
    my $self = shift;
    my $path = shift;

    foreach my $excluded ( @{ $self->exclude } ) {
        if ( my $ref = ref $excluded ) {
            if ( $ref eq 'Regexp' ) {
                return 1 if $path =~ /$excluded/;
            }
            elsif ( $ref eq 'CODE' ) {
                local $_ = $path;
                return 1 if $excluded->($path);
            }
        }
        else {
            return 1 if $path eq $excluded;
        }
    }

    return;
}

sub _remove_directory {
    my $self = shift;
    my $dir  = shift;

    $self->_set_directories(
        [ grep { $_ ne $dir } @{ $self->directories() } ] );
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

version 0.28

=head1 SYNOPSIS

    my $watcher =
        File::ChangeNotify->instantiate_watcher
            ( directories => [ '/my/path', '/my/other' ],
              filter      => qr/\.(?:pm|conf|yml)$/,
              exclude     => ['t', 'root', qr(/(?!\.)[^/]+$),
		              sub { -e && ! -r }],
            );

    if ( my @events = $watcher->new_events() ) { ... }

    # blocking
    while ( my @events = $watcher->wait_for_events() ) { ... }

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

The watcher can operate in a blocking/callback style, or you can simply ask it
for a list of new events as needed.

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

An optional list of paths to exclude. This list can contain plain strings,
regular expressions, or subroutine references. If you provide a string it
should contain the complete path to be excluded.

If you provide a sub, it should return a true value for paths to be excluded
e.g. C<< exclude => [ sub { -e && ! -r } ], >>. The path will be passed as the
first argument to the subroutine as well as in a localized C<$_>.

The paths can be either directories or specific files. If the exclusion
matches a directory, all of its files and subdirectories are ignored.

=item * follow_symlinks => $bool

By default, symlinks are ignored. Set this to true to follow them.

If this symlinks are being followed, symlinks to files and directories
will be followed. Directories will be watched, and changes for
directories and files reported.

=item * sleep_interval => $number

For watchers which call C<sleep> to implement the C<<
$watcher->wait_for_events() >> method, this argument controls how long
it sleeps for. The value is a number in seconds.

The default is 2 seconds.

=item * event_class => $class

This can be used to change the class used to report events. By
default, this is L<File::ChangeNotify::Event>.

=back

=head2 $watcher->wait_for_events()

This method causes the watcher to block until it sees interesting
events, and then return them as a list.

Some watcher subclasses may implement blocking as a sleep loop, while
others may actually block.

=head2 $watcher->new_events()

This method returns a list of any interesting events seen since the
last time the watcher checked.

=head2 $watcher->sees_all_events()

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

This software is Copyright (c) 2009 - 2018 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
