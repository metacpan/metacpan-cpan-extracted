package Filesys::Notify::Win32::ReadDirectoryChanges;
use 5.020;

use Moo 2;
use feature 'signatures';
no warnings 'experimental::signatures';

use File::Spec;
use Win32::API;
use Win32API::File 'CreateFile', 'CloseHandle', ':FILE_FLAG_', 'FILE_LIST_DIRECTORY', 'OPEN_EXISTING', 'FILE_SHARE_WRITE', 'FILE_SHARE_READ', 'GENERIC_READ';
use threads; # we launch a thread for each watched tree to keep the logic simple
use Thread::Queue;
use Encode 'decode';

our $VERSION = '0.03';
our $is_cygwin = $^O eq 'cygwin';

=head1 NAME

Filesys::Notify::Win32::ReadDirectoryChanges - read/watch directory changes

=head1 SYNOPSIS

  my $watcher = Filesys::Notify::Win32::ReadDirectoryChanges->new();
  for my $dir (@ARGV) {
      $watcher->watch_directory( path => $dir, subtree => 1 );
  };
  $watcher->wait(sub {
      my( $event ) = @_;
      say $event->{action}, ":", $event->{path};
  });

This module allows to watch multiple directories for changes and invokes a
callback for every change.

This module spawns a thread for each watched directory. Each such thread
synchronously reads file system changes and communicates them to the main
thread through a L<Thread::Queue>.

=head1 METHODS

=head2 C<< ->new %options >>

  my $w = Filesys::Notify::Win32::ReadDirectoryChanges->new(
      directories => \@ARGV,
      subtree => 1,
  );

Creates a new watcher object.

=cut

sub BUILD($self, $args) {
    if( my $dirs = delete $args->{directory}) {
        $dirs = [$dirs] if ! ref $dirs;
        for my $d (@$dirs) {
            $self->watch_directory( path => $d );
        }
    }
}

has 'subtree' => (
    is => 'ro',
);

has 'watchers' => (
    is => 'lazy',
    default => sub{ +{} },
);

=head2 C<< ->queue >>

  my $q = $w->queue;

Returns the L<Thread::Queue> object where the filesystem events get
passed in. Use this for integration with your own event loop.

=cut

has 'queue' => (
    is => 'lazy',
    default => sub { Thread::Queue->new() },
);

Win32::API::More->Import( 'kernel32', 'BOOL ReadDirectoryChangesW(
  HANDLE                          hDirectory,
  LPVOID                          lpBuffer,
  DWORD                           nBufferLength,
  BOOL                            bWatchSubtree,
  DWORD                           dwNotifyFilter,
  LPDWORD                         lpBytesReturned,
  LPVOID                          lpOverlapped,
  LPVOID                          lpCompletionRoutine
)' )
    or die Win32::FormatMessage(Win32::GetLastError());
Win32::API->Import( 'kernel32.dll', 'CancelIoEx', 'NN','N' )
    or die $^E;

our @action = (
        'unknown',
        'added',
        'removed',
        'modified',
        'old_name',
        'new_name',
);

sub _unpack_file_notify_information( $buf ) {
# typedef struct _FILE_NOTIFY_INFORMATION {
#   DWORD NextEntryOffset;
#   DWORD Action;
#   DWORD FileNameLength;
#   WCHAR FileName[1];
# } FILE_NOTIFY_INFORMATION, *PFILE_NOTIFY_INFORMATION;

    my @res;
    my $ofs = 0;
    my $last_name;
    my $last_action;
    do {
        my ($next, $action, $fn ) = unpack 'VVV/a', $buf;
        $ofs = $next;
        $fn = decode( 'UTF-16le', $fn );
        push @res, { action => $action[ $action ], path => $fn };

        if( $action == 5 and $last_action == 4 ) {
            # Create a synthetic event in addition
            push @res, {
                action => 'renamed',
                old_name => $last_name,
                new_name => $fn,
                path     => $last_name,
                hint => 'synthetic',
            };
        }
        $last_name = $fn;
        $last_action = $action;

        $buf = substr($buf, $next);
    } while $ofs > 0;
    @res
}

sub _ReadDirectoryChangesW( $hDirectory, $watchSubTree, $filter ) {
    my $buffer = "\0" x 65500;
    my $returnBufferSize = 0;
    my $r = ReadDirectoryChangesW(
        $hDirectory,
        $buffer,
        length($buffer),
        !!$watchSubTree,
        $filter,
        $returnBufferSize,
        undef,
        undef);
    if( $r ) {
        return substr $buffer, 0, $returnBufferSize;
    } else {
        return undef
    }
}

# Add ReadDirectoryChangesExW support
# Consider sub backfillExtendedInformation($fn,$info) {
# }

# This is what each thread runs, in a named subroutine so
# we don't accidentially close over some variable
sub _watcher($winpath,$orgpath,$hPath,$subtree,$queue) {
    my $running = 1;
    while($running) {
        # 0x1b means 'DIR_NAME|FILE_NAME|LAST_WRITE|SIZE' = 2|1|0x10|8
        my $res = _ReadDirectoryChangesW($hPath, $subtree, 0x1b);

        if( ! defined $res ) {
            my $err = Win32::GetLastError();
            if( $err != 995 ) { # 995 means ReadDirectoryChangesW got cancelled and we should quit
                warn $orgpath;
                warn $winpath;
                warn $^E;
            }
            last
        };

        for my $i (_unpack_file_notify_information($res)) {
            $i->{path} = $winpath . $i->{path};
            if( $is_cygwin ) {
                my $p = $i->{path};
                $i->{path} = Cygwin::win_to_posix_path( $p );
            };
            if( $i->{action} eq 'renamed') {
                for( qw(old_name new_name)) {
                    $i->{$_} = $winpath . $i->{$_};
                    if( $is_cygwin ) {
                        $i->{$_} = Cygwin::win_to_posix_path( $i->{$_} );
                    };
                };
            };
            $queue->enqueue($i);
        };
    }
};

sub build_watcher( $self, %options ) {
    my $orgpath = delete $options{ path };
    my $winpath = $is_cygwin ? Cygwin::posix_to_win_path($orgpath) : $orgpath;
    my $subtree = !!( $options{ subtree } // $self->subtree );
    $winpath .= "\\" if $winpath !~ /\\\z/;
    my $queue = $self->queue;
    my $hPath = CreateFile( $winpath, FILE_LIST_DIRECTORY()|GENERIC_READ(), FILE_SHARE_READ() | FILE_SHARE_WRITE(), [], OPEN_EXISTING(), FILE_FLAG_BACKUP_SEMANTICS(), [] )
        or die $^E;
    $orgpath =~ s![\\/]$!!;
    my $thr = threads->new( \&_watcher, $winpath, $orgpath, $hPath, $subtree, $queue);
    return { thread => $thr, handle => $hPath };
}

=head2 C<< ->watch_directory >>

  $w->watch_directory( path => $dir, subtree => 1 );

Add a directory to the list of watched directories.

=cut

sub watch_directory( $self, %options ) {
    my $dir = delete $options{ path };
    if( $self->watchers->{$dir}) {
        $self->unwatch_directory( path => $dir );
    }
    $self->watchers->{ $dir } = $self->build_watcher(
        queue => $self->queue,
        path => $dir,
        %options
    );
}

=head2 C<< ->unwatch_directory >>

  $w->unwatch_directory( path => $dir );

Remove a directory from the list of watched directories. There still may
come in some events stored for that directory previously in the queue.

=cut

sub unwatch_directory( $self, %options ) {
    my $dir = delete $options{ path };
    if( my $t = delete $self->watchers->{ $dir }) {
        CancelIoEx($t->{handle},0);
        CloseHandle($t->{handle});
        my $thr = delete $t->{thread};
        eval { $thr->join; }; # sometimes the thread is not yet joinable?!
    }
}

sub DESTROY($self) {
    if( my $w = $self->{watchers}) {
        for my $t (keys %$w) {
            $self->unwatch_directory( path => $t )
        }
    };
}

=head2 C<< ->wait $CB >>

  $w->wait(sub {
      my ($event) = @_;
      say $event->{action};
      say $event->{path};
  });

Synchronously wait for file system events.

=cut

sub wait( $self, $cb) {
    while( 1 ) {
        my @events = $self->queue->dequeue;
        for (@events) {
            if( defined $_ ) {
                $cb->($_);
            } else {
                # somebody did ->queue->enqueue(undef) to stop us
                last;
            }
        };
    };
}

1;

=head1 EVENTS

The following events are created by ReadDirectoryChangesW resp. this module

=over 4

=item B<added>

  {
      action   => 'added',
      path     => 'old-name.example',
  }

A new file was created

=item B<removed>

  {
      action   => 'removed',
      path     => 'old-name.example',
  }

A file was removed

=item B<modified>

  {
      action   => 'modified',
      path     => 'old-name.example',
  }

A file was modified

=item B<old_name>

  {
      action   => 'old_name',
      path     => 'old-name.example',
  }

First half of a rename

=item B<new_name>

  {
      action   => 'new_name',
      path     => 'new-name.example',
  }

Second half of a rename

=item B<renamed>

Whenever the event B<old_name> is followed immediately by B<new_name>,
a third, synthetic event is generated, C<renamed>.

  {
      action   => 'renamed',
      path     => 'old-name.example',
      old_name => 'old-name.example',
      new_name => 'new-name.example',
  }

=back

=head1 HELP WANTED

In theory, this module should also work on Cygwin, but for some reason, it
seems that there is memory corruption on Cygwin. If you happen to be handy
with a debugger and familiar with Cygwin, your help is appreciated.

=head1 SEE ALSO

L<Filesys::Notify::Simple> - simple cross-platform directory watcher

L<File::ChangeNotify> - complex cross-platform directory watcher

L<Win32::ChangeNotify> - Win32 directory watcher using the ChangeNotify API

Currently, no additional information like that available through
L<https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-readdirectorychangesexw|ReadDirectoryChangesExW>
is collected. But a wrapper/emulation could provide that information whenever
RDCE is unavailable (on Windows versions before Windows 10).

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Filesys-Notify-Win32-ReadDirectoryChanges>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2022 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
