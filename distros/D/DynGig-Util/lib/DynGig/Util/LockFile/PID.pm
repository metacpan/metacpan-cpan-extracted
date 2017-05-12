=head1 NAME

DynGig::Util::LockFile::PID - pid lock with an advisory file

=cut
package DynGig::Util::LockFile::PID;

use warnings;
use strict;
use Carp;

use Cwd qw();
use Fcntl qw( :flock );

=head1 SYNPOSIS

 use DynGig::Util::LockFile::PID;
 
 my $file = '/lock/file/path';
 my $lock = DynGig::Util::LockFile::PID->new( $file );
 my $pid = $lock->lock();

 if ( $pid )
 {
     if ( my $child = fork() )
     {
         my $handle = $lock->handle();
         syswrite $handle, $child;
         exit 0;
     }

     ## child safely does critical stuff
 }
 else
 {
     my $pid = DynGig::Util::LockFile::PID->check( $file );

     die "another instance $pid already running\n" if $pid;
 }

=cut
sub new
{
    my ( $class, $file ) = @_;

    croak 'invalid/undefined lock file' unless $file
        && defined ( $file = Cwd::abs_path( $file ) )
        && ( ! -e $file || -f $file );

    my $mode = -f $file ? '+<' : '+>';
    my $this;

    croak "open $file: $!" unless open $this, $mode, $file;

    bless \$this, ref $class || $class;
}

=head1 DESCRIPTION

=head2 lock()

Attempts to acquire lock. Returns pid if successful. Returns undef otherwise.

=cut
sub lock
{
    my $this = shift @_;
    my $handle = $$this;
    my $pid;

    return $pid unless flock $handle, LOCK_EX | LOCK_NB;

    sysseek $handle, 0, 0;
    sysread $handle, $pid, 64;

    if ( $pid && $pid eq $$ )
    {
    }
    elsif ( $pid && $pid =~ /^\d+$/ && kill 0, $pid )
    {
        $pid = undef;
    }
    else
    {
        sysseek $handle, 0, 0;
        truncate $handle, 0;
        syswrite $handle, ( $pid = $$ );
    }
 
    flock $handle, LOCK_UN;
    return $pid;
}

=head2 handle()

Returns the handle of the lock file.

=cut
sub handle
{
    my $this = shift;
    my $handle = $$this;

    sysseek $handle, 0, 0;
    return $handle;
}

=head2 check( $filename )

Returns ID of process that owns the lock. Returns 0 if not locked.

=cut
sub check
{
    my ( $class, $file ) = @_;

    croak 'lock file not defined' unless defined $file;

    my ( $handle, $pid );

    return open( $handle, '<', $file ) && read( $handle, $pid, 1024 )
        && $pid =~ /^\d+$/ && $pid && kill 0, $pid ? $pid : 0;
}

=head1 SEE ALSO

Fcntl

=head1 NOTE

See DynGig::Util

=cut

1;

__END__
