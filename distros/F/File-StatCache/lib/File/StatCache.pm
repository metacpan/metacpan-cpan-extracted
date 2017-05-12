#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2006,2007,2009 -- leonerd@leonerd.org.uk

package File::StatCache;

use strict;
use warnings;

our $VERSION = '0.06';

use Exporter;
our @ISA       = qw( Exporter );
our @EXPORT_OK = qw(
  get_stat
  stat

  get_item_mtime
);

use File::stat;

=head1 NAME

C<File::StatCache> - a caching wrapper around the C<stat()> function

=head1 DESCRIPTION

This module implements a cache of information returned by the C<stat()>
function. It stores the result of a C<stat()> syscall, to avoid putting excess
load on the host's filesystem in case many calls would be generated.

By default the cache for any given filename will time out after 10 seconds; so
any request for information on the same name after this time will result in
another C<stat()> syscall, ensuring fresh information. This timeout is stored
in the package variable C<$File::StatCache::STATTIMEOUT>, and can be
modified by other modules if required.

=cut

my %laststattime;
my %stat_cache;

# Make $STATTIMEOUT externally visible, so other modules change it
our $STATTIMEOUT = 10;

=head1 FUNCTIONS

=cut

=head2 $stats = get_stat( $path [, $now ] )

This function wraps a call to C<File::stat::stat()>, and caches the result. If
the requested file was C<stat()>ed within C<$STATTIMEOUT> seconds, it will not
be requested again, but the previous result (i.e. an object reference or
C<undef>) will be returned.

The $now parameter allows some other time than the current time to be used,
rather than re-request it from the kernel using the C<time()> function. This
allows a succession of tests to be performed in a consistent way, to avoid a
race condition.

=over 8

=item $path

The path to the filesystem item to C<stat()>

=item $now

Optional. The time to consider as the current time

=back

=cut

sub get_stat($;$)

  # This stat always returns a File::stat object.
{
    my ( $path, $now ) = @_;

    $now = time() if ( !defined $now );

    if ( !exists $laststattime{$path} ) {

        # Definitely new
        my $itemstat = File::stat::stat($path);
        $laststattime{$path} = $now;
        if ( !defined $itemstat ) {
            return undef;
        }
        return $stat_cache{$path} = $itemstat;
    }

    if ( $now - $laststattime{$path} > $STATTIMEOUT ) {

        # Haven't checked it in a while - check again
        my $itemstat = File::stat::stat($path);
        $laststattime{$path} = $now;
        if ( !defined $itemstat ) {
            delete $stat_cache{$path};
            return undef;
        }
        return $stat_cache{$path} = $itemstat;
    }

    if ( !exists $stat_cache{$path} ) {

        # Recently checked, and it didn't exist
        return undef;
    }

    # Recently checked; exists
    return $stat_cache{$path};
}

sub _stat($)

  # The real call from outside - return an object or list as appropriate
{
    my ($path) = @_;

    my $stat = get_stat($path);

    if ( defined $stat ) {
        return $stat unless wantarray;

        # Need to construct the full annoying 13-element list
        return (
            $stat->dev,   $stat->ino,   $stat->mode,  $stat->nlink,
            $stat->uid,   $stat->gid,   $stat->rdev,  $stat->size,
            $stat->atime, $stat->mtime, $stat->ctime, $stat->blksize,
            $stat->blocks,
        );
    }
    else {
        return wantarray ? () : undef;
    }
}

=head2 $stats = stat( $path )

=head2 @stats = stat( $path )

This is a drop-in replacement for either the perl core C<stat()> function or
the C<File::stat::stat> function, depending whether it is called in list or
scalar context. It behaves identically to either of these functions, except
that it returns cached results if the cached value is recent enough.

Note that in the case of failure (i.e. C<undef> in scalar context, empty in
list context), the value of C<$!> is not reliable as the reason for error.
Error results are not currently cached.

=over 8

=item $path

The path to the filesystem item to C<stat()>

=back

=cut

# Need to work around perl's warning of "Subroutine stat redefined at..."

no warnings;
*stat = \&_stat;
use warnings;

=head2 get_item_mtime( $path [, $now ] )

This function is equivalent to

 (scalar get_stat( $path, $now ))->mtime

=over 8

=item $path

The path to the filesystem item to C<stat()>

=item $now

Optional. The time to consider as the current time

=back

=cut

sub get_item_mtime($;$) {
    my ( $path, $now ) = @_;

    my $itemstat = get_stat( $path, $now );
    return $itemstat->mtime if defined $itemstat;
    return undef;
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 LIMITATIONS

=over 4

=item *

The shortcut tests (e.g. C<-f>, C<-r>, etc..) will not work with this module.

=item *

The "last results" filename C<_> cannot be used; the following code will not
work with this module:

  my @stats = stat( _ );

=back

=head1 BUGS

=over 4

=item *

The value of C<$!> is not preserved for per-file failures. When C<undef> or
the empty list are returned, the C<$!> value may not indicate the reason for
this particular failure.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut
