package File::Redirect::Base;

use strict;
use warnings;

use Errno;

sub mount  { die "not implemented" }
sub umount {}

sub Stat   { Errno::ENOENT() }
sub Open   { Errno::ENOENT() }
sub Close  { 0 }

1;

=pod

=head1 NAME

File::Redirect::Base - root for vfs providers

=head1 API

=over

=item mount ($class, $data, $dev_no)

Request to mount $data as pseudo-device number $dev_no. Must return object
instance that will receive all further operation requests (see below).

=item umount

Unmounts device

=item Stat $path

Return array of 12-items, in the same format as perl's CORE::stat (see perldoc -f stat)
on success, and error number integer on failure.

=item Open $path, $mode

Tries to open $path with $mode. On success must return a glob handle, f.ex. an C<IO::Scalar>
object emulating the file. On failure must return error number integer.

=item Close $handle

Optional; implements close(2) semantics - on successful operation must return 0,
error number integer otherwise.

=back

=cut
