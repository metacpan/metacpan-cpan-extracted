package Lazy::Lockfile;

use strict;
use Fcntl qw/ :DEFAULT :flock /;
use POSIX qw/ :errno_h /;
use File::Basename;

use vars qw( $VERSION );
( $VERSION ) = '1.22';

=head1 NAME

Lazy::Lockfile - File based locking for the lazy.

=head1 SYNOPSIS

 use Lazy::Lockfile;

 my $lockfile = Lazy::Lockfile->new() || die "Couldn't get lock!";
 ...
 # Lock is released when $lockfile goes out of scope or your program exits.

=head1 DESCRIPTION

Lazy::Lockfile is a module designed for simple locking through the use of
lockfiles, requiring very little effort on the part of the developer. Once the
object is instanced, the lock will be held as long as object exists. When the
object is destroyed, the lock is released.

Locks are based around the existence of a named file, not around the use of
L<flock> (though flock is used to synchronize access to the lock file). 
Lazy::Lockfile is (usually) smart enough to detect stale lockfiles from PIDs no
longer running by placing the PID of the process holding the lock inside the
lockfile.

=head1 NOTES

Lazy::Lockfile is not safe for use on NFS volumes.

Lazy::Lockfile is not tested to interact correctly with other file locking
systems when used on the same lockfile.

Lazy::Lockfile uses kill (with signal zero) to determine if the lockfile is
stale. This works on most systems running as most users but there are likely
instances where this will fail. If this applies to your system, you can use the
L<no_pid> option to disable the check.

If Lazy::Lockfile encounters a malformed lockfile (empty, containing other
text, etc), it will treat it as a corrupt file and overwrite it, assuming the
lock. The author believes this behavior should be changed (and malformed files
should be left untouched), but has kept this behavior for backwards
compatibility.

=head1 USAGE

All of the magic in Lazy::Lockfile is done through the constructor and
destructor.

=head1 METHODS

=head2 new

Constructor for Lazy::Lockfile.

=head3 Parameters

Accepts a single optional parameter, a hashref containing the following
options:

=head4 location

Specifies the full path to the location of the lockfile. Defaults to:

 '/tmp/' . (fileparse($0))[0] . '.pid'

i.e., the name of the program being run, with a ".pid" extension, in /tmp/.

=head4 no_pid

If true, instead of writing the PID file, a value of "0" is written instead.
When read by another instance of Lazy::Lockfile attempting to acquire the lock,
no PID check will be performed and the lock will be assumed to be active as
long as the file exists. Defaults to false.

=head4 delete_on_destroy

If true, sets the "delete on destroy" flag. This flag defaults to true, which
causes the lockfile to be removed when the object is destroyed. Generally,
this is the desired behavior. When set to false, this flag prevents the
lockfile from being removed automatically when the object is destroyed. See
also C<delete_on_destroy>.

=head3 Compatibility

For compatibility with older versions of Lazy::Lockfile (pre-1.0), a single
optional parameter is accepted, the path to the lockfile. This parameter
functions the same as the 'location' parameter described above.

As stated above, malformed lockfiles will be overwritten, though this may be
subject to change in a future version.

=head3 Return value

If the lock can not be obtained, undef is returned (and $! will contain useful
information). Otherwise, the lock is exclusive to this process, as long as the
object exists.

=head3 Example

 my $lockfile = Lazy::Lockfile->new( { location => "/var/lock", no_pid => 1 } )
     || die "Couldn't get lock!";

=cut

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    my $lockfile_location;

    # Yargh, backwards compatibility ahoy!
    if ( ref $params ne 'HASH' ) {
        $lockfile_location = $params;
        $params = {};
    } else {
        if ( !defined $params ) {
            $params = {};
        }
        $lockfile_location = $params->{'location'};
    }

    if ( ( !defined $lockfile_location ) || ( $lockfile_location eq '' ) ) {
        $lockfile_location = '/tmp/' . (fileparse($0))[0] . '.pid';
    }

    my $lock_tries = 0;
    my ( $lock, $file_pid );

    # If we return here, sysopen will set $! for us.
    sysopen( $lock, $lockfile_location, O_RDWR | O_CREAT | O_NOFOLLOW, 0644 ) or return;
    while ( $lock_tries++ < 5 ) {
        if ( flock( $lock, LOCK_NB | LOCK_EX ) ) {
            last;
        }
        sleep( 1 );
    }
    if ( $lock_tries > 5 ) {
        close( $lock );
        $! = EWOULDBLOCK;
        return;
    }
    seek( $lock, 0, 0 );
    $file_pid = <$lock>;

    if ( defined $file_pid ) {
        ( $file_pid ) = $file_pid =~ /^(\d+)/;
    }
# Would it be better to detect the broken file and return a different error?
#    if ( ( !defined $file_pid ) && ( $file_pid eq '' ) ) 
#        flock( $lock, LOCK_UN );
#        close( $lock );
#        $! = EFTYPE;
#        return;
#    }
    if (
        ( ( defined $file_pid ) && ( $file_pid ne '' ) )
        &&
        ( ( $file_pid == 0 ) || ( kill( 0, $file_pid ) || $!{EPERM} ) )
    ) {
        flock( $lock, LOCK_UN );
        close( $lock );
        $! = EEXIST;
        return;
    }

    seek( $lock, 0, 0 );
    truncate( $lock, 0 );
    if ( $params->{'no_pid'} ) {
        print $lock "0\n";
    } else {
        print $lock "$$\n";
    }
    flock( $lock, LOCK_UN );
    close( $lock );
    bless $self, $class;
    $self->{'lockfile_location'} = $lockfile_location;

    if ( defined $params->{'delete_on_destroy'} ) {
        $self->{'delete_on_destroy'} = $params->{'delete_on_destroy'} ? 1 : 0;
    } else {
        $self->{'delete_on_destroy'} = 1;
    }

    return $self;
}

=head2 name

Returns the file name of the lockfile.

=cut

sub name {
    my ( $self ) = @_;
    return $self->{'lockfile_location'};
}

=head2 delete_on_destroy

Gets or sets the "delete on destroy" flag.

If called without a parameter (or with undef), delete_on_destroy will return
the current state of the "delete on destroy" flag. If called with a parameter,
this flag will be set.

=cut

sub delete_on_destroy {
    my ( $self, $new_setting ) = @_;

    if ( !defined $new_setting ) {
        return $self->{'delete_on_destroy'};
    } else {
        $self->{'delete_on_destroy'} = $new_setting ? 1 : 0;
        return;
    }
}

=head2 unlock

Explicitly removes the lockfile, just as if the object were destroyed. Once
this has been called, delete_on_destroy will be set to false, since the lock
has already been deleted. Once this method is called, there is not much use
left for the object, so the user may as well delete it now.

unlock should be used when the lockfile needs to be removed deterministically
while the program is running. If you simply remove all references to the
Lazy::Lockfile object, the lock will be freed when garbage collection is run,
which is not guaranteed to happen until the program exits (though it will
likely happen immediately).

Returns a true value if the lockfile was found and removed, false otherwise.

=cut

sub unlock {
    my ( $self ) = @_;
    my $retval = $self->DESTROY;
    $self->delete_on_destroy(0);
    return $retval;
}

# Make sure the lockfile contains our pid before we delete it...
# do we need this?
sub DESTROY {
    my ( $self ) = @_;
    my $retval = 0;
    if ( ( $self ) && ( $self->{'lockfile_location'} ) && ( $self->{'delete_on_destroy'} ) ) {
        my ( $lock, $file_pid );
        my $lock_tries = 0;
        open( $lock, '<', $self->{'lockfile_location'} ) || return 0;
        while ( $lock_tries++ < 5 ) {
            if ( flock( $lock, LOCK_NB | LOCK_EX ) ) {
                last;
            }
            sleep( 1 );
        }
        if ( $lock_tries > 5 ) { close( $lock ); return 0; }
        seek( $lock, 0, 0 );
        $file_pid = <$lock>;
        chomp( $file_pid ) if defined $file_pid;
        if ( ( defined $file_pid ) && ( ( $file_pid == 0 ) || ( $file_pid == $$ ) ) ) {
            $retval = unlink $self->{'lockfile_location'};
        }
        close( $lock );
    }
    return $retval;
}

=head1 CHANGES

=head2 2014-10-30, 1.22 - jeagle

Add missing dependency.

=head2 2014-09-14, 1.21 - jeagle

Re-package to make it easier to convert to RPM, etc.

=head2 2012-04-01, 1.20 - jeagle

Updated documentation, thanks Alister W.

=head2 2011-01-05, 1.19 - jeagle

Change to unit tests to appease cpantesters.

=head2 2011-01-04, 1.18 - jeagle

Implement suggestion by srezic to check PIDs belonging to other users
(RT#69185).

Clean up documentation.

=head2 2010-06-22, 1.17 - jeagle

Update L<unlock> to return a useful status.

=head2 2010-06-22, 1.16 - jeagle

Version bumps for migration to CPAN.

=head2 2009-12-03, 1.14 - jeagle

Fix a bug causing lockfiles with no_pid to not be deleted on destroy/unlink.

=head2 2009-12-03, 1.13 - jeagle

Add the unlock method, to allow for deterministic lockfile removal at runtime.

=head2 2009-11-30, 1.12 - jeagle

Update documentation to clarify delete_on_destroy parameter default setting.

=head2 2009-07-06, 1.11 - jeagle

Fix error thrown when running with taint checking enabled.

=head2 2009-07-06, 1.10 - jeagle

Fix a bug with lockfile location being overwritten with the default.

=head2 2009-07-06, 1.9 - jeagle

Add new parameter, no_pid, which disabled active lockfile checks.

Allow constructor to accept multiple parameters via hashref.

=head2 2009-06-10, 0.4 - jeagle

Introduce the delete_on_destroy flag.

=head2 2009-06-03, 0.3 - jeagle

Open pid file with O_NOFOLLOW, to avoid symlink attacks.

Change default pid file location from /var/tmp to /tmp.

Correct dates in CHANGES section.

Add useful error indicators, documentation on error detection.

=head2 2009-04-27, 0.2 - jeagle

Fix a bug with unspecified lockfile paths trying to create impossible file
names.

=head2 2009-04-06, v0.1 - jeagle

Initial release.

=cut

1;
