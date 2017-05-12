#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk

package File::lchown;

use strict;
use warnings;

our $VERSION = '0.02';

use Exporter 'import';
our @EXPORT_OK = qw(
   lchown
   lutimes
);

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

=head1 NAME

C<File::lchown> - modify attributes of symlinks without dereferencing them

=head1 SYNOPSIS

 use File::lchown qw( lchown lutimes );

 lchown $uid, $gid, $linkpath or die "Cannot lchown() - $!";

 lutimes $atime, $mtime, $linkpath or die "Cannot lutimes() - $!";

=head1 DESCRIPTION

The regular C<chown> system call will dereference a symlink and apply
ownership changes to the file at which it points. Some OSes provide system
calls that do not dereference a symlink but instead apply their changes
directly to the named path, even if that path is a symlink (in much the same
way that C<lstat> will return attributes of a symlink rather than the file at
which it points).

=cut

=head1 FUNCTIONS

=cut

=head2 $count = lchown $uid, $gid, @paths

Set the new user or group ownership of the specified paths, without
dereferencing any symlinks. Passing the value C<-1> as either the C<$uid> or
C<$gid> will leave that attribute unchanged. Returns the number of files
successfully changed.

=cut

=head2 $count = lutimes $atime, $mtime, @paths

Set the access and modification times on the specified paths, without
dereferencing any symlinks. Passing C<undef> as both C<$atime> and C<$mtime>
will update the times to the current system time.

Note that for both C<lchown> and C<lutimes>, if more than one path is given,
if later paths succeed after earlier failures, then the value of C<$!> will
not be reliable to indicate the nature of the failure. If you wish to use
C<$!> to report on failures, make sure only to pass one path at a time.

=cut

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 TODO

=over 4

=item *

Implement sub-second precision on C<lutimes>, most likely by taking floats or
two-element ARRAY refs, similar to C<Time::HiRes> uses.

=back

=head1 SEE ALSO

=over 4

=item *

C<lchown(2)> - change ownership of a file

=item *

C<lutimes(2)> - change file timestamps

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
