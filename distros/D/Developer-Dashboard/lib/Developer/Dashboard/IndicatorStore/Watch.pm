package Developer::Dashboard::IndicatorStore::Watch;

use strict;
use warnings;
our $VERSION = '6.31';

use Errno qw(EILSEQ);
use IO::Select;
use POSIX ();
use Socket qw(SO_TYPE SOL_SOCKET);

use constant EVENT_MASK => 0x00000fce;

# new(%args)
# Creates an optional native watcher, or an injected backend for deterministic
# tests. Backends may use a descriptor with initialize/add_watch callbacks or
# configure a path set and expose a nonblocking unchanged callback.
# Input: optional backend hash implementing one supported callback contract.
# Output: watcher object, or undef when the optional native backend is absent.
sub new {
    my ( $class, %args ) = @_;
    my $backend = exists $args{backend} ? $args{backend} : _native_backend();
    return if !defined $backend;
    die "Watcher backend must be a hash reference\n" if ref($backend) ne 'HASH';
    my @required = ref( $backend->{configure_paths} ) eq 'CODE'
      ? qw(configure_paths unchanged close)
      : qw(initialize add_watch close);
    for my $method (@required) {
        die "Watcher backend is missing '$method'\n" if ref( $backend->{$method} ) ne 'CODE';
    }
    return bless {
        backend    => $backend,
        handle     => undef,
        select     => undef,
        signature  => undef,
        paths      => [],
        last_error => undef,
    }, $class;
}

# event_mask()
# Returns the inotify event mask used to observe write and namespace mutations.
# Input: none.
# Output: unsigned event bit mask for writes, attributes, create, delete, and rename events.
sub event_mask { return EVENT_MASK }

# configure($signature, $paths)
# Installs a complete watch set for an ordered filesystem inventory. Repeated
# identical configurations keep the descriptor; a changed inventory replaces
# it so obsolete directory watches cannot accumulate.
# Input: stable inventory signature string and array reference of directory paths.
# Output: true when every requested directory is watched, false with last_error
#         populated when descriptor or watch setup fails.
sub configure {
    my ( $self, $signature, $paths ) = @_;
    die "Watcher inventory signature must be a non-reference string\n"
      if !defined $signature || ref($signature);
    die "Watcher paths must be an array reference\n" if ref($paths) ne 'ARRAY';
    my %seen;
    my @unique_paths = grep { defined $_ && !ref($_) && $_ ne '' && !$seen{$_}++ } @{$paths};
    my $same_paths = @unique_paths == @{$self->{paths}}
      && !grep { $unique_paths[$_] ne $self->{paths}[$_] } 0 .. $#unique_paths;
    return 1
      if $self->{handle}
      && defined $self->{signature}
      && $self->{signature} eq $signature
      && $same_paths;

    return 0 if !$self->close;
    $self->{last_error} = undef;
    my $handle;
    if ( ref( $self->{backend}{configure_paths} ) eq 'CODE' ) {
        my $error;
        ( $handle, $error ) = $self->{backend}{configure_paths}->( \@unique_paths );
        if ( defined $error || !defined $handle ) {
            $self->{handle} = $handle if defined $handle;
            return $self->_disable( $error || 'Unable to configure platform filesystem notifications' );
        }
    }
    else {
        $handle = $self->{backend}{initialize}->();
        if ( !$handle ) {
            return $self->_disable('Unable to initialize filesystem watch descriptor');
        }

        for my $path (@unique_paths) {
            $! = 0;
            my $watch = $self->{backend}{add_watch}->( $handle, $path, EVENT_MASK );
            if ( !defined $watch || $watch < 0 ) {
                my $error = "Unable to watch directory '$path'";
                $error .= ": $!" if $!;
                $self->{handle} = $handle;
                return $self->_disable($error);
            }
            if ( $watch == 0 ) {
                $self->{handle} = $handle;
                return $self->_disable("Unable to watch directory '$path': invalid watch descriptor");
            }
        }
    }

    $self->{handle} = $handle;
    $self->{select} = IO::Select->new($handle)
      if ref( $self->{backend}{configure_paths} ) ne 'CODE';
    $self->{signature} = $signature;
    $self->{paths}     = \@unique_paths;
    return 1;
}

# unchanged($signature)
# Polls the active backend. Any filesystem event invalidates the cached snapshot;
# the caller must run its portable directory and file-signature check.
# Input: expected inventory signature string.
# Output: true only for an active matching watch set with no queued events.
sub unchanged {
    my ( $self, $signature ) = @_;
    return 0 if !$self->{handle} || !defined $self->{signature};
    return 0 if !defined $signature || ref($signature) || $signature ne $self->{signature};
    if ( ref( $self->{backend}{unchanged} ) eq 'CODE' ) {
        my ( $unchanged, $error ) = $self->{backend}{unchanged}->( $self->{handle} );
        return $self->_disable($error) if defined $error;
        return $self->_disable('Platform filesystem notification backend returned no state')
          if !defined $unchanged;
        $self->{last_error} = undef;
        return $unchanged ? 1 : 0;
    }
    return 0 if !$self->{select};
    return 1 if !_handle_readable( $self->{select}, $self->{handle} );

    my $events = '';
    my $read = sysread( $self->{handle}, $events, 65_536 );
    if ( !defined $read ) {
        return $self->_disable("Unable to read filesystem watch events: $!");
    }
    if ( $read == 0 ) {
        return $self->_disable('Filesystem watch descriptor closed unexpectedly');
    }
    $self->{last_error} = undef;
    return 0;
}

# _handle_readable($select, $handle)
# Reports whether a watched handle has input waiting, without blocking.
# On Windows, select() only works on real sockets, so IO::Select->can_read
# never fires for a pipe handle even with data queued (the t/88 client
# hang, same class); pipe readiness comes from PeekNamedPipe on the
# handle's real Win32 HANDLE instead. A select-like object that is not
# a genuine IO::Select keeps its own can_read: its readiness does not
# go through the operating-system select, so there is nothing to work
# around, and test doubles that force readability keep working. When
# the Windows primitive is unavailable the caller falls back to
# can_read, the pre-existing behaviour, never a new failure.
# Input: IO::Select (or select-like) object and the watched handle.
# Output: true when input is waiting, false when the handle is quiet.
sub _handle_readable {
    my ( $select, $handle ) = @_;
    return 0 if !defined $select || !defined $handle;
    if ( $^O eq 'MSWin32' && ref($select) eq 'IO::Select' ) {
        my $readable = _windows_handle_readable( $select, $handle );
        return $readable if defined $readable;
    }
    my @readable = $select->can_read(0);
    return @readable ? 1 : 0;
}

# _windows_handle_readable($select, $handle)
# Windows readiness for one watched handle. A getsockopt probe (Server.pm,
# t/17 devnull case) tells a socket from a pipe: a socket answers SO_TYPE
# and keeps the select path, a pipe does not and is polled with
# PeekNamedPipe. A PeekNamedPipe failure means the pipe is broken, so the
# handle counts as readable and the caller's read reports the real
# end-of-file or error diagnostic instead of silently missing the event.
# Input: IO::Select object and the watched handle.
# Output: 1 when input is waiting, 0 when quiet, undef when the Windows
#         primitive is unavailable.
sub _windows_handle_readable {
    my ( $select, $handle ) = @_;
    if ( defined getsockopt( $handle, SOL_SOCKET, SO_TYPE ) ) {
        my @readable = $select->can_read(0);
        return @readable ? 1 : 0;
    }
    my $peek = _windows_peek_named_pipe();
    return undef if !defined $peek;
    my $os_handle = eval { Win32API::File::GetOsFHandle($handle) };
    return undef if $@ || !defined $os_handle;
    my $avail = _windows_pipe_available( $peek, $os_handle );
    return 1 if !defined $avail;
    return $avail > 0 ? 1 : 0;
}

# Cached PeekNamedPipe import, attempted once; a failed import is never
# retried, so a missing Win32 primitive degrades to can_read exactly once.
my $_WINDOWS_PEEK;
my $_WINDOWS_PEEK_FAILED;

# _windows_peek_named_pipe()
# Imports PeekNamedPipe from kernel32 once and caches the function object.
# Input: none.
# Output: imported function object, or undef when the import fails.
sub _windows_peek_named_pipe {
    return $_WINDOWS_PEEK if defined $_WINDOWS_PEEK;
    return undef if $_WINDOWS_PEEK_FAILED;
    my $peek = eval {
        require Win32API::File;
        require Win32::API;
        my $imported = Win32::API->new( 'kernel32', 'PeekNamedPipe', 'QPIPPP', 'I' );
        die "Could not import PeekNamedPipe from kernel32\n" if !defined $imported;
        $imported;
    };
    if ( !$peek ) {
        $_WINDOWS_PEEK_FAILED = 1;
        return undef;
    }
    $_WINDOWS_PEEK = $peek;
    return $peek;
}

# _windows_pipe_available($peek, $handle)
# Reports how many bytes are waiting on one Windows pipe, without blocking.
# Input: imported PeekNamedPipe function object and one real Win32 HANDLE.
# Output: byte count, or undef when the pipe is broken or the call fails.
sub _windows_pipe_available {
    my ( $peek, $handle ) = @_;
    return undef if !defined $handle;
    $^E = 0;
    my $bytes_read  = pack 'L', 0;
    my $total_avail = pack 'L', 0;
    my $bytes_left  = pack 'L', 0;
    my $ok = $peek->Call( $handle, '', 0, $bytes_read, $total_avail, $bytes_left );
    return undef if !$ok;
    return unpack 'L', $total_avail;
}

# last_error()
# Returns the diagnostic for the most recent watcher setup or read failure.
# Input: none.
# Output: error string or undef when the watcher is healthy or merely observed
#         a normal filesystem event.
sub last_error {
    my ($self) = @_;
    return $self->{last_error};
}

# close()
# Releases the active watcher descriptor and clears its inventory identity.
# Input: none.
# Output: true when no descriptor remains or it closed successfully; false with
#         last_error populated when backend closure fails.
sub close {
    my ($self) = @_;
    my $handle = delete $self->{handle};
    delete $self->{select};
    delete $self->{signature};
    $self->{paths} = [];
    if ( !$handle ) {
        $self->{last_error} = undef;
        return 1;
    }
    my ( $closed, $close_error ) = $self->{backend}{close}->($handle);
    if ( !$closed ) {
        if ( defined $close_error && length "$close_error" ) {
            $self->{last_error} = $close_error;
        }
        elsif ( 0 + $! ) {
            $self->{last_error} = "Unable to close filesystem watch descriptor: $!";
        }
        else {
            $self->{last_error} = 'Unable to close filesystem watch descriptor';
        }
        return 0;
    }
    $self->{last_error} = undef;
    return 1;
}

# _disable($message)
# Closes a partially configured watcher and preserves the setup/read failure
# that caused the optimization to be rejected.
# Input: explicit diagnostic string.
# Output: false, signaling callers to use the portable validator.
sub _disable {
    my ( $self, $message ) = @_;
    $self->{last_error} = $message;
    my $handle = delete $self->{handle};
    delete $self->{select};
    delete $self->{signature};
    $self->{paths} = [];
    if ($handle) {
        my ( $closed, $close_error ) = $self->{backend}{close}->($handle);
        if ( !$closed ) {
            my $detail;
            if ( defined $close_error && length "$close_error" ) {
                $detail = $close_error;
            }
            elsif ( 0 + $! ) {
                $detail = "$!";
            }
            else {
                $detail = 'unknown close failure';
            }
            $self->{last_error} .= "; descriptor close failed: $detail";
        }
    }
    return 0;
}

# _native_backend()
# Selects the operating-system watcher adapter, requiring the built XS
# extension only on supported native platforms.
# Input: none.
# Output: native backend callbacks, or undef when unsupported or optional
#         platform modules are unavailable.
sub _native_backend {
    return _linux_backend() if $^O eq 'linux';
    return _macos_backend() if $^O eq 'darwin';
    return _windows_backend() if $^O eq 'MSWin32';
    return;
}

# _linux_backend()
# Builds an XS inotify backend for Linux kernels.
# Input: none.
# Output: descriptor backend callbacks, or undef when XS is unavailable.
sub _linux_backend {
    return if !_native_xs_available();
    return {
        initialize => sub {
            my $fd = _xs_inotify_init();
            return if !defined $fd || $fd < 0;

            # Validate the descriptor before wrapping it: perlio grows its
            # fd refcount table to cover the descriptor number before the
            # open can fail with EBADF, so wrapping a bogus fd such as
            # 999,999,999 asks for a ~4 GB table and dies out of memory
            # on a small box (t/669 on ARM64). dup() is a raw syscall
            # that never touches perlio, so it tests validity safely;
            # the duplicate is closed at once. A failed dup dies with
            # the same diagnostic the wrap itself would have produced.
            my $probe = POSIX::dup($fd);
            if ( !defined $probe ) {
                die "Unable to wrap inotify descriptor $fd: $!";
            }
            POSIX::close($probe);
            open my $handle, '<&=', $fd
              or die "Unable to wrap inotify descriptor $fd: $!";
            return $handle;
        },
        add_watch => sub {
            my ( $handle, $path, $mask ) = @_;
            my $native_path = $path;
            if ( !utf8::downgrade( $native_path, 1 ) ) {
                $! = EILSEQ;
                return -1;
            }
            return _xs_inotify_add_watch( fileno($handle), $native_path, $mask );
        },
        close => sub {
            my ($handle) = @_;
            return CORE::close($handle);
        },
    };
}

# _macos_backend()
# Builds an FSEvents adapter when optional Mac::FSEvents is installed. The
# stream watches the inventory and is polled nonblockingly by its fd.
# Input: none.
# Output: path-configuring event backend, or undef when the module is unavailable.
sub _macos_backend {
    my $loaded = eval { require Mac::FSEvents; 1 };
    if ( !$loaded ) {
        my $error = $@;
        return if $error =~ /Can't locate Mac\/FSEvents\.pm in \@INC/;
        die $error;
    }
    return {
        configure_paths => sub {
            my ($paths) = @_;
            return ( undef, 'No existing directories were provided to FSEvents' ) if !@{$paths};
            my ( $stream, $handle );
            my $configured = eval {
                $stream = Mac::FSEvents->new(
                    {
                        path        => $paths,
                        latency     => 0,
                        watch_root  => 1,
                        file_events => 1,
                    }
                );
                $handle = $stream->watch;
                die "FSEvents did not return a readable event stream\n" if !$handle;
                1;
            };
            if ( !$configured ) {
                my $error = $@;
                if ( $stream && $stream->can('stop') ) {
                    my $stopped = eval { $stream->stop };
                    $error .= "; FSEvents cleanup failed: " . ( $@ || 'stop returned false' )
                      if !$stopped;
                }
                return ( undef, "Unable to configure macOS FSEvents: $error" );
            }
            return ( { stream => $stream, handle => $handle, select => IO::Select->new($handle) }, undef );
        },
        unchanged => sub {
            my ($watch) = @_;
            return ( undef, 'FSEvents watch handle is malformed' )
              if ref($watch) ne 'HASH' || !$watch->{stream} || !$watch->{select};
            return ( 1, undef ) if !_handle_readable( $watch->{select}, $watch->{handle} );
            my $read = eval { $watch->{stream}->read_events; 1 };
            return ( undef, "Unable to read macOS FSEvents: $@" ) if !$read;
            return ( 0, undef );
        },
        close => sub {
            my ($watch) = @_;
            return ( 0, 'FSEvents watch handle is malformed during close' )
              if ref($watch) ne 'HASH' || !$watch->{stream};
            my $stopped = eval { $watch->{stream}->stop };
            return ( 0, "Unable to stop macOS FSEvents: " . ( $@ || 'stop returned false' ) )
              if !$stopped;
            return ( 1, undef );
        },
    };
}

# _windows_backend()
# Builds Unicode-aware Win32 directory-change notifications using XS calls.
# Each watched directory owns a native notification handle.
# Input: none.
# Output: path-configuring event backend, or undef when XS is unavailable.
sub _windows_backend {
    return if !_native_xs_available();
    return {
        configure_paths => sub {
            my ($paths) = @_;
            return ( undef, 'No existing directories were provided to Windows notifications' ) if !@{$paths};
            my @handles;
            for my $path ( @{$paths} ) {
                my $handle = _xs_win32_find_first_change($path);
                if ( !defined $handle ) {
                    my $code = _xs_win32_last_error();
                    my $error = "FindFirstChangeNotificationW failed for '$path' (GetLastError=$code)";
                    for my $active_handle (@handles) {
                        if ( !_xs_win32_close_change($active_handle) ) {
                            my $close_code = _xs_win32_last_error();
                            # ERROR_INVALID_HANDLE (6): the handle is already
                            # gone (its directory was deleted), so there is
                            # nothing left to clean up; a dead handle is not
                            # a cleanup failure.
                            next if $close_code == 6;
                            $error .= "; cleanup failed (GetLastError=$close_code)";
                        }
                    }
                    return ( undef, $error );
                }
                push @handles, $handle;
            }
            return ( { handles => \@handles }, undef );
        },
        unchanged => sub {
            my ($watch) = @_;
            return ( undef, 'Windows notification handle set is malformed' )
              if ref($watch) ne 'HASH' || ref( $watch->{handles} ) ne 'ARRAY';
            my $changed = 0;
            for my $handle ( @{ $watch->{handles} } ) {
                my $state = _xs_win32_wait($handle);
                next if defined $state && $state == 258;
                if ( !defined $state || $state == 0xffffffff ) {
                    my $code = _xs_win32_last_error();
                    # ERROR_INVALID_HANDLE (6): the watched directory was
                    # deleted (tempdir cleanup) and the notification handle
                    # died with it. That is a change, not a watcher failure:
                    # report the snapshot invalid and let the caller's
                    # portable validation see the directory is gone, instead
                    # of disabling the watcher with a native error.
                    return ( 0, undef ) if $code == 6;
                    return ( undef, "WaitForSingleObject failed (GetLastError=$code)" );
                }
                if ( $state == 0 ) {
                    if ( !_xs_win32_next_change($handle) ) {
                        my $code = _xs_win32_last_error();
                        return ( 0, undef ) if $code == 6;
                        return ( undef, "FindNextChangeNotification failed (GetLastError=$code)" );
                    }
                    $changed = 1;
                    next;
                }
                return ( undef, "WaitForSingleObject returned unexpected status $state" );
            }
            return ( $changed ? 0 : 1, undef );
        },
        close => sub {
            my ($watch) = @_;
            return ( 0, 'Windows notification handle set is malformed during close' )
              if ref($watch) ne 'HASH' || ref( $watch->{handles} ) ne 'ARRAY';
            my $closed = 1;
            my @errors;
            for my $handle ( @{ $watch->{handles} } ) {
                if ( !_xs_win32_close_change($handle) ) {
                    my $code = _xs_win32_last_error();
                    # ERROR_INVALID_HANDLE (6): the handle is already gone
                    # (its directory was deleted), so there is nothing left
                    # to close; a dead handle is not a close failure.
                    next if $code == 6;
                    $! = $code;
                    push @errors, "FindCloseChangeNotification failed (GetLastError=$code)";
                    $closed = 0;
                }
            }
            return ( $closed, @errors ? join( '; ', @errors ) : undef );
        },
    };
}

# _native_xs_available()
# Loads the shared XS extension through the existing native-extension bootstrap.
# Input: none.
# Output: true when the extension exposes the watcher native entry points.
sub _native_xs_available {
    require Developer::Dashboard::HtmlEscape;
    return 0 if !$Developer::Dashboard::HtmlEscape::XS_LOADED;
    return __PACKAGE__->can('_xs_inotify_init')
      && __PACKAGE__->can('_xs_win32_find_first_change') ? 1 : 0;
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::IndicatorStore::Watch - optional filesystem event adapter

=head1 PURPOSE

Provides a small, nonblocking event watcher used to validate stable indicator
and configuration filesystem snapshots when a native backend is available. The
native Linux adapter uses inotify through the distribution's XS extension.
Tests and other platform adapters can inject a path-configuring
backend with nonblocking poll and close callbacks. Unsupported systems use the
caller's portable metadata/content validator instead of disabling snapshot
reuse.

=head1 WHY IT EXISTS

The stable collector-sync path checks directory inventories and high-resolution
status-file signatures so that another process's writes are observed on the
next request. For large inventories, those checks repeat directory reads and
metadata syscalls. An event can prove that a portable full validation is needed;
an event-free matching watch set can safely skip those checks after its snapshot
has been established. Events are treated conservatively: the adapter does not
interpret filenames or event masks, so overflow, rename, delete, and write
events all invalidate the fast path.

=head1 WHEN TO USE

Use this adapter only as an optimization hint around a previously validated
filesystem snapshot. Callers must retain portable validation when the backend
is unavailable, a watch cannot be installed, the inventory signature changes,
or any event is observed. Configuration snapshots use directory metadata plus
SHA-256 of exact config files on unsupported systems; this detects additions,
removals, and in-place edits without requiring Linux-specific APIs.

=head1 HOW TO USE

  my $watch = Developer::Dashboard::IndicatorStore::Watch->new;
  if ($watch) {
      $watch->configure( $signature, \@directories );
      my $unchanged = $watch->unchanged($signature);
  }

Unsupported systems do not load native APIs. Linux uses XS for inotify, macOS
optionally uses Mac::FSEvents, and Windows uses XS with wide-character
directory notification APIs. If the extension is unavailable, the constructor
returns undef; failures in available native calls remain visible.

=head1 WHAT USES IT

Developer::Dashboard::IndicatorStore may use the adapter for its stable
collector synchronization. The repository tests use an injected backend to
exercise event and error handling without relying on a particular operating
system.

=head1 EXAMPLES

Example 1: build the optional native backend when available.

  my $watch = Developer::Dashboard::IndicatorStore::Watch->new;

Example 2: establish an inventory snapshot.

  $watch->configure( $inventory_signature, [ $root, @indicator_directories ] );

Example 3: invalidate and use the ordinary validator after any event.

  if ( !$watch->unchanged($inventory_signature) ) {
      validate_directory_inventory_and_file_signatures();
  }

Example 4: run its deterministic contract test in the Docker dev container.

  d2 docker compose exec dev prove -Iblib/arch -Iblib/lib -Ilib -lv t/669-problem48-inotify-watch.t

=head1 SAFETY

The adapter executes no shell commands and reads no status-file content. It
does not treat a failed or event-bearing watch as unchanged. Linux paths are
passed to libc only when they can be represented without lossy byte
conversion. macOS uses FSEvents when Mac::FSEvents is installed; Windows uses
wide-character directory notifications through XS. Each optional backend falls
back to the caller's portable validator when unavailable.

=cut
