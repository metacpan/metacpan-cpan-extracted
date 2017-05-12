package File::Hotfolder;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.04';

use Carp;
use File::Find;
use File::Spec;
use File::Basename qw(basename);
use Linux::Inotify2;
use Scalar::Util qw(blessed);

use parent 'Exporter';
our %EXPORT_TAGS = (print => [qw(
        WATCH_DIR FOUND_FILE KEEP_FILE DELETE_FILE
        CATCH_ERROR WATCH_ERROR HOTFOLDER_ERROR 
        HOTFOLDER_ALL
    )]);
our @EXPORT = ('watch', @{$EXPORT_TAGS{'print'}});
$EXPORT_TAGS{all} = \@EXPORT;

use constant {
    WATCH_DIR   => 1,
    UNWATCH_DIR => 2,
    FOUND_FILE  => 4,
    KEEP_FILE   => 8,
    DELETE_FILE => 16,    
    CATCH_ERROR => 32,
    WATCH_ERROR => 64,
    HOTFOLDER_ALL => 128-1,
    HOTFOLDER_ERROR => 32 | 64,
};

# function interface
sub watch {
    shift if $_[0] eq 'File::Hotfolder';
    File::Hotfolder->new( @_ % 2 ? (watch => @_) : @_ );
}

# object interface
sub new {
    my ($class, %args) = @_;

    my $path = $args{watch} // ''; 
    $path = File::Spec->rel2abs($path) if $args{fullname};
    croak "Missing watch directory: $path" unless -d $path,

    my $self = bless { 
        inotify    => (Linux::Inotify2->new
                      or croak "Unable to create new inotify object: $!"),
        callback   => ($args{callback} || sub { 1 }),
        delete     => !!$args{delete},
        print      => 0+($args{print} || 0),
        filter     => _build_filter($args{filter},
                                    sub { $_[0] !~ qr{^(.*/)?\.[^/]*$} }),
        filter_dir => _build_filter($args{filter_dir}, qr{^[^.]|^.$}), 
        scan       => $args{scan},
        catch      => _build_catch($args{catch}),
        logger     => _build_logger($args{logger}),
    }, $class;

    $self->watch_recursive( $path );

    $self;
}

sub _build_catch {
    my ($catch) = @_;
    return $catch if ref $catch // '' eq 'CODE';
    return $catch ? sub { } : undef;
}

sub _build_filter {
    my $filter = $_[0] // $_[1];
    return unless $filter;
    return sub { $_[0] =~ $filter } if ref $filter eq ref qr//;
    $filter;
}

sub watch_recursive {
    my ($self, $path) = @_;

    my $args = {
        no_chdir => 1, 
        wanted => sub {
            if (-d $_) {
                $self->_watch_directory($_);
            } elsif( $self->{scan} ) {
                # TODO: check if not open or modified (lsof or fuser)
                $self->_callback($_);
            }
        },
    };

    if ($self->{filter_dir}) {
        return unless $self->{filter_dir}->(basename($path));
        $args->{preprocess} = sub {
            grep { $self->{filter_dir}->($_) } @_
        };
    }
    
    find( $args, $path );
}

sub _watch_directory {
    my ($self, $path) = @_;

    $self->log( WATCH_DIR, $path ); 

    unless ( $self->inotify->watch( 
        $path, 
        IN_CREATE | IN_CLOSE_WRITE | IN_MOVE | IN_DELETE | IN_DELETE_SELF | IN_MOVE_SELF, 
        sub {
            my $e = shift;
            my $path  = $e->fullname;
            
            if ( $e->IN_Q_OVERFLOW ) {
                $self->log( WATCH_ERROR, $path, "event queue overflowed" );
            }
            
            if ( $e->IN_ISDIR ) {
                if ( $e->IN_CREATE || $e->IN_MOVED_TO) {
                    $self->watch_recursive($path);
                } elsif ( $e->IN_DELETE_SELF || $e->IN_MOVE_SELF ) {
                    $self->log( UNWATCH_DIR, $path );
                    $e->w->cancel;
                }
            } elsif ( $e->IN_CLOSE_WRITE || $e->IN_MOVED_TO ) {
                $self->_callback($path);
            }

        }
    ) ) {
        $self->log( WATCH_ERROR, $path, "failed to create watch: $!" );
    };
}

sub _callback {
    my ($self, $path) = @_;

    if ($self->{filter} && !$self->{filter}->($path)) {
        return;
    }

    $self->log( FOUND_FILE, $path );
    
    my $status;
    if ($self->{catch}) {
        $status = eval { $self->{callback}->($path) };
        if ($@) {
            $self->log( CATCH_ERROR, $path, $@ );
            $self->{catch}->($path, $@);
            return;
        }
    } else {
        $status = $self->{callback}->($path);
    }

    if ( $status && $self->{delete} ) {
        unlink $path;
        $self->log( DELETE_FILE, $path );
    } else {
        $self->log( KEEP_FILE, $path );
    }
}

sub loop {
    1 while $_[0]->inotify->poll;
}

sub anyevent {
    my $inotify = $_[0]->inotify;
    AnyEvent->io (
        fh => $inotify->fileno, poll => 'r', cb => sub { $inotify->poll }
    );
}

sub inotify {
    $_[0]->{inotify};
}

## LOGGING

our %LOGS = (
    WATCH_DIR   , "watching %s",
    UNWATCH_DIR , "unwatching %s",
    FOUND_FILE  , "found %s",
    KEEP_FILE   , "keep %s",
    DELETE_FILE , "delete %s",
    CATCH_ERROR , "error %s: %s",
    WATCH_ERROR , "failed %s: %s",
);

sub _build_logger {
    my ($logger) = @_;

    if ( not defined $logger ) {
        sub {
            my (%args) = @_;
            my $fh = $args{event} & HOTFOLDER_ERROR ? *STDERR : *STDOUT;
            say $fh $args{message};
        }
    } elsif (blessed $logger && $logger->can('log')) {
        sub {
            my (%args) = @_;
            $logger->log( 
                level   => $args{event} & HOTFOLDER_ERROR ? 'error' : 'info',
                message => $args{message}
            );
        }
    } elsif (ref $logger // '' eq 'CODE') {
        $logger;
    } else {
        croak "logger must be code or provide a log method!";
    }
}

sub log {
    my ($self, $event, $path, $error) = @_;
    if ( $event & $self->{print} ) {
        $self->{logger}->( 
            event   => $event,
            path    => $path,
            message => sprintf($LOGS{$event}, $path, $event),
        );
    }
}

1;
__END__

=head1 NAME

File::Hotfolder - recursive watch directory for new or modified files

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/nichtich/File-Hotfolder.png)](https://travis-ci.org/nichtich/File-Hotfolder)
[![Coverage Status](https://coveralls.io/repos/nichtich/File-Hotfolder/badge.png?branch=master)](https://coveralls.io/r/nichtich/File-Hotfolder?branch=master)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/File-Hotfolder.png)](http://cpants.cpanauthors.org/dist/File-Hotfolder)

=end markdown

=head1 SYNOPSIS

    use File::Hotfolder;

    # object interface
    File::Hotfolder->new(
        watch    => '/some/directory',  # which directory to watch
        callback => sub {               # what to do with each new/modified file
            my $path = shift;
            ...
        },
        delete   => 1,                  # delete each file if callback returns true
        filter   => qr/\.json$/,        # only watch selected files
        print    => WATCH_DIR           # show which directories are watched
                    | HOTFOLDER_ERROR,  # show all errors (CATCH_ERROR | WATCH_ERROR)
        catch    => sub {               # catch callback errors
            my ($path, $error) = @_;
            ...
        }
    )->loop;

    # function interface
    watch( '/some/directory', callback => sub { say shift } )->loop;

    # watch a given directory and delete all new or modified files
    watch( $ARGV[0] // '.', delete  => 1, print => DELETE_FILE )->loop;

    # watch directory, delete all new/modified non-txt files, print all files
    watch( '/some/directory',
        callback => sub { $_[0] !~ /\.txt$/ },
        delete  => 1,
        print   => DELETE_FILE | KEEP_FILE
    );
    
=head1 DESCRIPTION

This module uses L<Linux::Inotify2> to recursively watch a directory for new or
modified files. A callback is called on each file with its path.

Deletions and new subdirectories are not reported but new subdirectories will
be watched as well.

=head1 CONFIGURATION

=over

=item watch

Base directory to watch. The C<WATCH_DIR> event is logged for each watched
(sub)directory and the C<UNWATCH_DIR> event if directories are deleted. The
C<WATCH_ERROR> event is logged if watching a directory failed and if the watch
queue overflowed.

=item callback

Callback for each new or modified file. The callback is not called during a
write but after a file has been closed. The C<FOUND_FILE> event is logged
before executing the callback.

=item delete

Delete the modified file if a callback returned a true value (disabled by
default). A C<DELETE_FILE> will be logged after deletion or a C<KEEP_FILE>
event otherwise.

=item fullname

Return absolute path names. By default pathes are relative to the base
directory given with option C<watch>.

=item filter

Filter file pathes with regular expression or code reference before passing to
callback. Set to ignore all hidden files (starting with a dot) by default.  Use
C<0> to disable.

=item filter_dir

Filter directory names with regular expression before watching. Set to ignore
hidden directories (starting with a dot) by default. Use C<0> to disable.

=item print

Which events to log. Unless parameter C<logger> is specified, events are
printed to STDOUT or STDERR. Possible event types are exported as constants
C<WATCH_DIR>, C<UNWATCH_DIR>, C<FOUND_FILE>, C<DELETE_FILE>, C<KEEP_FILE>,
C<CATCH_ERROR>, and C<WATCH_ERROR>. The constant C<HOTFOLDER_ERROR> combines
C<CATCH_ERROR> and C<WATCH_ERROR> and the constant C<HOTFOLDER_ALL> combines
all event types.

=item logger

Where to log events to. If given a code reference, the code is called with
three named parameters:

    logger => sub { # event => $event, path => $path, message => $message
        my (%args) = @_;
        ...
    },

If given an object instance a logging method is created and called at the
object's C<log> method with argument C<level> and C<message> as expected by
L<Log::Dispatch>:

    logger => Log::Dispatch->new( ... ),

The C<level> is set to C<error> for C<HOTFOLDER_ERROR> events and C<info> for
other events.

=item catch

Error callback for failing callbacks (event C<CATCH_ERROR>). Disabled by
default, so a dying callback will terminate the program. 

=item scan

First call the callback for all existing files. This does not guarantee that
found files have been closed.

=back

=head1 METHODS

=head2 loop

Watch with a manual event loop. This method never returns.

=head2 anyevent

Watch with L<AnyEvent>. Returns a new AnyEvent watch.

=head2 inotify

Returns the internal L<Linux::Inotify2> object. Future versions of this module
may use another notify module (L<Win32::ChangeNotify>, L<Mac::FSEvents>,
L<Filesys::Notify::KQueue>...), so this method may return C<undef>.

=head1 SEE ALSO

L<File::ChangeNotify>, L<Filesys::Notify::Simple>

L<AnyEvent>

=head1 COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2015-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
