#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2011 -- leonerd@leonerd.org.uk

package IPC::PerlSSH::Library::IO;

use strict;
use warnings;

use IPC::PerlSSH::Library;

our $VERSION = '0.17';

=head1 NAME

C<IPC::PerlSSH::Library::IO> - a library of file IO functions for
C<IPC::PerlSSH>

=head1 SYNOPSIS

 use IPC::PerlSSH;

 my $ips = IPC::PerlSSH->new( Host => "over.there" );

 $ips->use_library( "IO", qw( open fchmod write close ) );

 my $fd = $ips->call( "open", ">", "secret.txt" );
 $ips->call( "fchmod", $fd, 0600 );
 $ips->call( "write", $fd, "s3kr1t\n" );
 $ips->call( "close" );

=head1 DESCRIPTION

This module provides a library of functions for interacting with remote IO
filehandles. It provides simple wrappers around the perl IO functions, taking
or returning file descriptor numbers instead of filehandle objects. This
allows filehandles to remain open in the remote perl instance, across many
C<call>s.

Because the filehandles remain open, the program must take care to call
C<close> at the appropriate time, so as not to leak file descriptors in the
remote perl.

=cut

init q[
use IO::Handle;

our %handles;

sub store_handle
{
   my $fh = shift;
   my $fd = $fh->fileno;
   $handles{$fd} = $fh;
   return $fd;
}

sub get_handle
{
   my $fd = shift;
   $fd > 2 or die "Cannot operate on STD{IN|OUT|ERR}\n";
   return $handles{$fd} || die "No handle on fileno $fd\n";
}
];

=head1 FUNCTIONS

=cut

=head2 open

Open a new filehandle in the remote perl and return its FD number.

 my $fd = $ips->call( "open", $mode, @args )

The filehandle is put into unbuffered mode, such that subsequent C<write>
calls will send the data directly to the underlying operating system.

The C<$mode> argument supports the full range of perl open modes, including
pipe opens with C<-|>. If using a pipe open, you can close the file handle
with C<pclose> instead of C<close> to obtain the child process exit status.

In the case of pipe opens, L<IPC::PerlSSH::Library::Run> provides a selection
of functions that may be more convenient for executing a child program on the
remote perl, if interaction during its execution is not required.

In the case of simple C<open> / C<read> / C<close> or C<open> / C<write> /
C<close> sequences, see also the L<IPC::PerlSSH::Library::FS> functions
C<readfile> and C<writefile>.

=cut

func open => q{
   my ( $mode, @args ) = @_;
   open( my $fh, $mode, @args ) or die "Cannot open() - $!\n";
   $fh->autoflush;
   store_handle( $fh );
};

=head2 close

Close a remote filehandle.

 $ips->call( "close", $fd )

=cut

func close => q{
   our %handles;
   undef $handles{shift()};
};

=head2 pclose

Close a remote filehandle which was part of a pipe-open, and return the child
process exit status.

 $exitstatus = $ips->call( "pclose", $fd )

=cut

func pclose => q{
   our %handles;
   my $fd = shift;
   my $fh = get_handle( $fd );
   undef $handles{$fd};
   close $fh;
   return $?;
};

=head2 read

Perform a single read call on a remote filehandle.

 my $data = $ips->call( "read", $fd, $length )

Returns empty string on EOF.

=cut

func read => q{
   my $fh = get_handle( shift );
   defined( $fh->read( my $data, $_[0] ) ) or die "Cannot read() - $!\n";
   return $data;
};

=head2 getline

Read a single line from the remote filehandle.

 my $line = $ips->call( "getline", $fd );

Returns empty string on EOF.

=cut

func getline => q{
   my $fh = get_handle( shift );
   defined( my $line = $fh->getline() ) or die "Cannot getline() - $!\n";
   return $line;
};

=head2 write

Perform a single write call on a remote filehandle.

 $ips->call( "write", $fd, $data )

Note this is called C<write> to match the system call, rather than C<print>.

=cut

func write => q{
   my $fh = get_handle( shift );
   defined( $fh->print( $_[0] ) ) or die "Cannot write() - $!\n";
};

=head2 tell

Return the current file position on a remote filehandle.

 my $pos = $ips->call( "tell", $fd )

=cut

func tell => q{
   my $fh = get_handle( shift );
   return tell($fh);
};

=head2 seek

Seek to the given position in the remote filehandle and return the new
position.

 my $newpos = $ips->call( "seek", $fd, $pos, $whence )

You may find it useful to import the C<SEEK_*> constants from the C<Fcntl>
module.

=cut

func seek => q{
   my $fh = get_handle( shift );
   seek( $fh, $_[0], $_[1] ) or die "Cannot seek() - $!\n";
   return tell($fh);
};

=head2 truncate

Truncates the file to the given length.

 $ips->call( "truncate", $fd, $len );

=cut

func truncate => q{
   my $fh = get_handle( shift );
   $fh->truncate( $_[0] ) or die "Cannot truncate() - $!\n";
};

=head2 fstat

Returns the status of the file (see L<perldoc -f stat>).

 my ( $dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime,
      $mtime, $ctime, $blksize, $blocks ) = $ips->call( "fstat", $fd )

=cut

func fstat => q{
   my $fh = get_handle( shift );
   my @s = stat( $fh ) or die "Cannot stat() - $!\n";
   @s;
};

=head2 fchmod

Change the permissions on the remote filehandle.

 $ips->call( "fchmod", $fd, 0755 )

Note the order of arguments does not match perl's C<chmod()>.

Only works on versions of remote F<perl> 5.8.8 and above.

=cut

func fchmod => q{
   die "Perl too old for fchmod()" if $] < 5.008008;
   my $fh = get_handle( shift );
   chmod( $_[0], $fh ) or die "Cannot chmod() - $!\n";
};

=head2 fchown

Changes the owner (and group) of the remote filehandle.

 $ips->call( "fchown", $uid, $gid )

Note the order of arguments does not match perl's C<chown()>.

Only works on versions of remote F<perl> 5.8.8 and above.

=cut

func fchown => q{
   die "Perl too old for fchown()" if $] < 5.008008;
   my $fh = get_handle( shift );
   chown( $_[0], $_[1], $fh ) or die "Cannot chown() - $!\n";
};

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
