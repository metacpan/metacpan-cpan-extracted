package Mac::FSEvents;

use 5.008008;
use strict;
use base 'Exporter';

use Mac::FSEvents::Event;

our $VERSION = '0.14';

our @EXPORT_OK   = qw(NONE WATCH_ROOT);
our %EXPORT_TAGS = ( flags => \@EXPORT_OK );

my @maybe_export_ok = qw(IGNORE_SELF FILE_EVENTS);

require XSLoader;
XSLoader::load('Mac::FSEvents', $VERSION);

my %const_args;

# generate subs for each constant
foreach my $constant ( @EXPORT_OK ) {
    my ( undef, $value ) = constant($constant);

    $const_args{ lc $constant } = $value if $constant ne "NONE";

    no strict 'refs';
    *$constant = sub {
        return $value;
    };
}

# check that these flags are defined
foreach my $constant ( @maybe_export_ok ) {
    my ( undef, $value ) = constant($constant);

    if ( defined($value) ) {
        $const_args{ lc $constant } = $value;

        no strict 'refs';
        *$constant = sub {
            return $value;
        };
        push @EXPORT_OK, $constant;
    }
}

sub new {
    my $self = shift;

    my $args;
    if ( @_ == 1 && ref $_[0] eq 'HASH' ) {
        $args = shift;
    }
    elsif ( @_ == 1 ) {
        $args = { path => shift };
    }
    else {
        $args = { @_ };
    }

    die "path argument to new() must be supplied" unless $args->{path};
    die "path argument to new() must be plain string or arrayref"
        if ref $args->{path} and ref $args->{path} ne 'ARRAY';

    # Build the flags
    for my $const_name ( keys %const_args ) {
        if ( $args->{ $const_name } ) {
            $args->{flags} |= $const_args{ $const_name };
            delete $args->{ $const_name };
        }
    }

    # Normalize path to arrayref
    if ( !ref $args->{path} ) {
        $args->{path} = [ $args->{path} ];
    }

    return __PACKAGE__->_new( $args );
}

sub DESTROY {
    my $self = shift;

    # Make sure thread has stopped
    $self->stop;

    # C cleanup
    $self->_DESTROY();
}

1;
__END__

=head1 NAME

Mac::FSEvents - Monitor a directory structure for changes

=head1 SYNOPSIS

  use Mac::FSEvents;

  my $fs = Mac::FSEvents->new(
      path          => '/',         # required, the path(s) to watch
                                    # optionally specify an arrayref of multiple paths
      latency       => 2.0,         # optional, time to delay before returning events
      since         => 451349510,   # optional, return events from this eventId
      watch_root    => 1,           # optional, fire events if the watched path changes
      ignore_self   => 1,           # optional, ignore events from this process
      file_events   => 1,           # optional, fire events on files instead of dirs
  );
  ### OR
  my $fs = Mac::FSEvents->new( '/' ); # Only specify the path

  my $fh = $fs->watch;

  # Select on this filehandle, or use an event loop:
  my $sel = IO::Select->new($fh);
  while ( $sel->can_read ) {
      my @events = $fs->read_events;
      for my $event ( @events ) {
          printf "Directory %s changed\n", $event->path;
      }
  }

  # or use blocking polling:
  while ( my @events = $fs->read_events ) {
      ...
  }

  # stop watching
  $fs->stop;

=head1 DESCRIPTION

This module implements the FSEvents API present in Mac OSX 10.5 and later.
It enables you to watch a large directory tree and receive events when any
changes are made to directories or files within the tree.

Event monitoring occurs in a separate C thread from the rest of your application.

=head1 METHODS

=over 4

=item B<new> ( { ARGUMENTS } )

=item B<new> ( ARGUMENTS )

=item B<new> ( PATH )

Create a new watcher. C<ARGUMENTS> is a hash or hash reference with the following keys:

=over 8

=item path

Required. A plain string or arrayref of strings of directories to watch. All
subdirectories beneath these directories are watched.

=item latency

Optional.  The number of seconds the FSEvents service should wait after hearing
about an event from the kernel before passing it along.  Specifying a larger value
may result in fewer callbacks and greater efficiency on a busy filesystem.  Fractional
seconds are allowed.

Default: 2.0

=item since

Optional.  A previously obtained event ID may be passed as the since argument.  A
notification will be sent for every event that has happened since that ID.  This can
be useful for seeing what has changed while your program was not running.

=item ignore_self

(Only available on OS X 10.6 or greater)

Don't send events triggered by the current process. Useful if you are also modifying
files in the watch list.

=item file_events

(Only available on OS X 10.7 or greater)

Send events for files. By default, only directory-level events are generated,
and may be coelesced if they happen simultaneously. With this flag, an event
will be generated for every change to a file.

=item watch_root

Request notifications if the location of the paths being watched change. For example,
if there is a watch for C</foo/bar>, and it is renamed to C</foo/buzz>, an event will
be generated with the C<root_changed> flag set.

=item flags

Optional.  Sets the flags provided to L<FSEventStreamCreate>.  In order to
import the flag constants, you must provide C<:flags> to C<use Mac::FSEvents>.

This method of setting flags is discouraged in favor of using the constructor argument,
above.

The following flags are supported:

=over 8

=item NONE

No flags. The default.

=item WATCH_ROOT

Set by the C<watch_root> constructor argument.

=item IGNORE_SELF

Set by the C<ignore_self> constructor argument.

=item FILE_EVENTS

Set by the C<file_events> constructor argument.

=back

=back

=item B<watch>

Begin watching.  Returns a filehandle that may be used with select() or the event loop
of your choice.

=item B<read_events>

Returns an array of pending events.  If using an event loop, this method should be
called when the filehandle becomes ready for reading.  If not using an event loop,
this method will block until an event is available.

Events are returned as L<Mac::FSEvents::Event> objects.

B<NOTE:> Event paths are real file system paths, with all the symbolic links
resolved. If you are watching a path with a symbolic link, use L<Cwd/abs_path>
if you need to make comparisons against the event's path.

=item B<stop>

Stop watching.

=back

=head1 SEE ALSO

http://developer.apple.com/documentation/Darwin/Conceptual/FSEvents_ProgGuide

=head1 AUTHOR

Andy Grundman, E<lt>andy@hybridized.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Andy Grundman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=begin Pod::Coverage

=over

=item constant

=back

=end Pod::Coverage

=cut
