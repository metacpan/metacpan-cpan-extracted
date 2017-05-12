#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2011 -- leonerd@leonerd.org.uk

package IPC::PerlSSH::Library::FS;

use strict;
use warnings;

use IPC::PerlSSH::Library;

our $VERSION = '0.17';

=head1 NAME

C<IPC::PerlSSH::Library::FS> - a library of filesystem functions for
C<IPC::PerlSSH>

=head1 SYNOPSIS

 use IPC::PerlSSH;

 my $ips = IPC::PerlSSH->new( Host => "over.there" );

 $ips->use_library( "FS", qw( mkdir chmod writefile ) );

 $ips->call( "mkdir", "/tmp/testing" );
 $ips->call( "chmod", 0600, "/tmp/testing" );

 $ips->call( "writefile", "/tmp/testing/secret", <<EOF );
 Some secret contents of my file here
 EOF

=head1 DESCRIPTION

This module provides a library of functions for interating with the remote
filesystem. It provides wrappers for most of the perl filesystem functions,
and some useful new functions that are more convenient to call remotely.

Because of the large number of functions defined by this library, it is
recommended to only load the ones being used by the program, to avoid sending
unnecessary data when setting up SSH connections across slow links.

=cut

=head1 FUNCTIONS

=head2 Simple Functions

The following perl functions have trivial wrappers that take arguments and
return values in the same way as perl's. They throw exceptions via the
C<IPC::PerlSSH> call when they fail, rather than returning undef, because
otherwise C<$!> would be difficult to obtain.

 chown chmod lstat mkdir readlink rename rmdir stat symlink unlink utime

The following functions are imported from L<File::Path> with the following
API adjustments:

 mkpath( $path, %opts ) # %opts supports mode, user, group
 rmtree( $path, %opts ) # %opts supports safe, keep_root

=cut

init q{
   use File::Path qw( mkpath rmtree );
};

func chown =>
   q{my $uid = shift; my $gid = shift;
      chown $uid, $gid, $_ or die "Cannot chown($uid, $gid, '$_') - $!" for @_;};

func chmod =>
   q{my $mode = shift;
     chmod $mode, $_ or die "Cannot chmod($mode, '$_') - $!" for @_;};

func lstat =>
   q{my @s = lstat $_[0]; @s or die "Cannot lstat('$_[0]') - $!"; @s};

func mkdir =>
   q{mkdir $_[0] or die "Cannot mkdir('$_[0]') - $!"};

func mkpath =>
   q{my ( $path, %opts ) = @_;
     mkpath $path, \%opts or die "Cannot mkpath('$path') - $!"};

func readlink =>
   q{my $l = readlink $_[0]; defined $l or die "Cannot readlink('$_[0]') - $!"; $l};

func rename =>
   q{rename $_[0], $_[1] or die "Cannot rename('$_[0]','$_[1]') - $!"};

func rmdir =>
   q{rmdir $_[0] or die "Cannot rmdir('$_[0]') - $!"};

func rmtree =>
   q{my ( $path, %opts ) = @_;
     rmtree $path, \%opts or die "Cannot rmtree('$_[0]') - $!"};

func stat =>
   q{my @s = stat $_[0]; @s or die "Cannot stat('$_[0]') - $!"; @s};

func symlink =>
   q{symlink $_[0], $_[1] or die "Cannot symlink('$_[0]','$_[1]') - $!"};

func unlink =>
   q{unlink $_[0] or die "Cannot unlink('$_[0]') - $!"};

func utime =>
   q{my $atime = shift; my $mtime = shift;
     utime $atime, $mtime, $_ or die "Cannot utime($atime, $mtime, '$_') - $!" for @_};

=head2 Variations on C<stat()>

The following functions each returns just one element from the C<stat()> list
for efficiency when only one is required.

 stat_dev stat_ino stat_mode stat_nlink stat_uid stat_gid stat_rdev
 stat_size stat_atime stat_mtime stat_ctime stat_blksize stat_blocks

=cut

my %statfields = (
   dev     => 0,
   ino     => 1,
   mode    => 2,
   nlink   => 3,
   uid     => 4,
   gid     => 5,
   rdev    => 6,
   # size is 7 but we do that a different way
   atime   => 8,
   mtime   => 9,
   ctime   => 10,
   blksize => 11,
   blocks  => 12,
);

func( "stat_$_", "(stat(\$_[0]))[$statfields{$_}]" ) for keys %statfields;

=pod

The following stored functions wrap the perl -X file tests (documented here in
the same order as in F<perldoc perlfunc>)

 stat_readable stat_writable stat_executable stat_owned

 stat_real_readable stat_real_writable stat_real_executable
 stat_real_owned

 stat_exists stat_isempty stat_size
 
 stat_isfile stat_isdir stat_islink stat_ispipe stat_issocket
 stat_isblock stat_ischar

 stat_issetuid stat_issetgid stat_issticky

 stat_istext stat_isbinary

 stat_mtime_days stat_atime_days stat_ctime_days

=cut

# We can cheat with the filetests
my %filetests = (
   readable   => 'r',
   writable   => 'w',
   executable => 'x',
   owned      => 'o',

   real_readable   => 'R',
   real_writable   => 'W',
   real_executable => 'X',
   real_owned      => 'O',

   'exists' => 'e',
   isempty  => 'z',
   size     => 's',

   isfile   => 'f',
   isdir    => 'd',
   islink   => 'l',
   ispipe   => 'p',
   issocket => 's',
   isblock  => 'b',
   ischar   => 'c',

   issetuid => 'u',
   issetgid => 'g',
   issticky => 'k',

   istext   => 'T',
   isbinary => 'B',

   mtime_days => 'M',
   atime_days => 'A',
   ctime_days => 'C',
);

func( "stat_$_", "-$filetests{$_} \$_[0]" ) for keys %filetests;

=head2 Variation Functions

The following functions are defined as variations on the perl function of the
same name

 my @ents = $ips->call( "readdir", $dirpath, $hidden );

Return a list of the directory entries. Hidden files are skipped if $hidden is
true. F<.> and F<..> are always skipped.

=cut

func readdir =>
   q{opendir( my $dirh, $_[0] ) or die "Cannot opendir('$_[0]') - $!";
     my @ents = readdir( $dirh );
     grep { $_[1] ? $_ !~ m/^\.\.?$/ : $_ !~ m/^\./ } @ents};

=pod

 $ips->call( "remove", $path );

Calls C<rmdir> if C<$path> is a directory, or C<unlink> if not

=cut

func remove =>
   q{(lstat $_[0] && -d _) ? rmdir $_[0] : unlink $_[0] or die "Cannot remove('$_[0]') - $!"};

=head2 New Functions

The following functions are newly defined to wrap common perl idoms

 my $content = $ips->call( "readfile", $filepath );
 $ips->call( "writefile", $filepath, $newcontent );

To open a remote filehandle and interact with it over a sequence of multiple
calls, see also L<IPC::PerlSSH::Library::IO>.

=cut

func readfile =>
   q{open( my $fileh, "<", $_[0] ) or die "Cannot open('$_[0]') for reading - $!";
     local $/; <$fileh>};

func writefile =>
   q{open( my $fileh, ">", $_[0] ) or die "Cannot open('$_[0]') for writing - $!";
     print $fileh $_[1] or die "Cannot print to '$_[0]' - $!"};

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
