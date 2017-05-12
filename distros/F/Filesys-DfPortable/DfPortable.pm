package Filesys::DfPortable;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Carp;
require Exporter;
require DynaLoader;
require 5.006;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(dfportable);
$VERSION = '0.85';
bootstrap Filesys::DfPortable $VERSION;

sub dfportable {
my ($dir, $block_size) = @_;
my ($used, $fused);
my ($per, $fper);
my ($user_blocks, $user_used);
my ($user_files, $user_fused);
my %fs = ();


	(defined($dir)) ||
		(croak "Usage: dfportable\(\$dir\) or dfportable\(\$dir\, \$block_size)");

	#### If no requested block size then we will return the values in bytes
	($block_size) ||
		($block_size = 1);

	my ($frsize, $blocks, $bfree, $bavail, $files, $ffree, $favail) = _dfportable($dir);

	#### Some system or XS failure, something like /proc, or bad $dir
	if($frsize == 0 || $blocks == 0) {
		return();
	}

	#### Change to requested or default block size
	if($block_size > $frsize) {
		my $result = $block_size / $frsize;
		$blocks /= $result;
		($bfree != 0) &&
			($bfree /= $result);
		#### Keep bavail -
		($bavail < 0) &&
			($result *= -1);

		($bavail != 0) &&
			($bavail /= $result);
	}

	elsif($block_size < $frsize) {
		my $result = $frsize / $block_size;
		$blocks *= $result;
		$bfree *= $result;
		#### Keep bavail -
		($bavail < 0) &&
			($result *= -1);
		$bavail *= $result;
	}

	$used = $blocks - $bfree;

	#### There is a reserved amount for the su
	#### or there are disk quotas
        if($bfree > $bavail) {
                $user_blocks = $blocks - ($bfree - $bavail);
                $user_used = $user_blocks - $bavail;
                if($bavail < 0) {
                        #### over 100%
                        my $tmp_bavail = $bavail;
                        $per = ($tmp_bavail *= -1) / $user_blocks;
                }
                                                                                                         
                else {
			if($user_used == 0) {
				$per = 0;
			}

			else {
                        	$per = $user_used / $user_blocks;
			}
                }
        }
                                                                                                         
        #### No reserved amount or quotas
        else {
                if($used == 0)  {
                        $per = 0;
                }
                                                                                                         
                else {
                        $per = $used / $blocks;
			$user_blocks = $blocks;
			$user_used = $used;
                }
        }

	#### round
        $per *= 100;
        $per += .5;
                                                                                                         
        #### over 100%
        ($bavail < 0) &&
                ($per += 100);

        $fs{per}     = int($per);
	$fs{blocks}  = $blocks;
	$fs{bfree}   = $bfree;
	$fs{bavail}  = $bavail;
	$fs{bused}   = $used;



	#### Handle inodes if system supports them
	if(defined $files && $files > 0) {
		$fused = $files - $ffree;
                #### There is a reserved amount
                if($ffree > $favail) {
                        $user_files = $files - ($ffree - $favail);
                        $user_fused = $user_files - $favail;
                        if($favail < 0)  {
                                #### over 100%
                                my $tmp_favail = $favail;
                                $fper = ($tmp_favail *= -1) / $user_files;
                        }
                                                                                                             
                        else {
				if($user_fused == 0) {
					$fper = 0;
				}

				else {
                                	$fper = $user_fused / $user_files;
				}
                        }
                }
                                                                                                             
                #### su and user amount are the same
                else {
                        if($fused == 0) {
                                $fper = 0;
                        }
                                                                                                             
                        else {
                                $fper = $fused / $files;
                        }
                                                                                                             
                        $user_files = $files;
                        $user_fused = $fused;
                }

                #### round
                $fper *= 100;
                $fper += .5;
                                                                                                             
                #### over 100%
                ($favail < 0) &&
                        ($fper += 100);

		$fs{fper}        = int($fper);
                $fs{files}       = $files;
                $fs{ffree}       = $ffree;
                $fs{favail}      = $favail;
                $fs{fused}       = $fused;
                #$fs{user_fused} = $user_fused;
                #$fs{user_files} = $user_files;
        }
                                                                                                             
        #### No valid inode info. Probably Windows or NFS
	#### Instead of undefing, just have the user call exists().
        #else {
        #        $fs{fper}        = undef;
        #        $fs{files}       = undef;
        #        $fs{ffree}       = undef;
        #        $fs{favail}      = undef;
        #        $fs{fused}       = undef;
        #        $fs{user_fused}  = undef;
        #        $fs{user_files}  = undef;
        #}
                                                                                                             

	return(\%fs);
}

1;
__END__

=head1 NAME

Filesys::DfPortable - Perl extension for filesystem disk space information.

=head1 SYNOPSIS


  use Filesys::DfPortable;

  my $ref = dfportable("C:\\"); # Default block size is 1, which outputs bytes
  if(defined($ref)) {
     print"Total bytes: $ref->{blocks}\n";
     print"Total bytes free: $ref->{bfree}\n";
     print"Total bytes avail to me: $ref->{bavail}\n";
     print"Total bytes used: $ref->{bused}\n";
     print"Percent full: $ref->{per}\n"
  }


  my $ref = dfportable("/tmp", 1024); # Display output in 1K blocks
  if(defined($ref)) {
     print"Total 1k blocks: $ref->{blocks}\n";
     print"Total 1k blocks free: $ref->{bfree}\n";
     print"Total 1k blocks avail to me: $ref->{bavail}\n";
     print"Total 1k blocks used: $ref->{bused}\n";
     print"Percent full: $ref->{per}\n"
  }



=head1 DESCRIPTION

This module provides a portable way to obtain filesystem disk space
information. 

The module should work with all versions of Windows (95 and up),
and with all flavors of Unix that implement the C<statvfs> or the C<statfs>
calls. This would include Linux, *BSD, HP-UX, AIX, Solaris, Mac OS X, Irix,
Cygwin, etc ...

This module differs from Filesys::Df in that it has added support
for Windows, but does not support open filehandles as a argument.

C<dfportable()> requires a directory argument that represents the filesystem
you want to query. There is also an optional block size argument so that
you can tailor the size of the values returned. The default block size
is 1, this will cause the function to return the values in bytes.
If you never use the block size argument, then you can think of any
instance of "blocks" in this document to really mean "bytes". 

C<dfportable()> returns a reference to a hash. The keys available in 
the hash are as follows:

{blocks} = Total blocks on the filesystem.

{bfree} = Total blocks free on the filesystem.

{bavail} = Total blocks available to the user executing the Perl 
application. This can be different than C<{bfree}> if you have per-user 
quotas on the filesystem, or if the super user has a reserved amount.
C<{bavail}> can also be a negative value because of this. For instance
if there is more space being used then you have available to you.

{bused} = Total blocks used on the filesystem.

{per} = Percent of disk space used. This is based on the disk space
available to the user executing the application. In other words, if
the filesystem has 10% of its space reserved for the superuser, then
the percent used can go up to 110%.

You can obtain inode information through the module as well. But you
must call C<exists()> on the C<{files}> key to make sure the information is
available. Some filesystems may not return inode information, for
example Windows, and some NFS filesystems.

Here are the available inode keys:

{files} = Total inodes on the filesystem.

{ffree} = Total inodes free on the filesystem.

{favail} = Total inodes available to the user executing the application.
See the rules for the C<{bavail}> key.

{fused} = Total inodes used on the filesystem.

{fper} = Percent of inodes used on the filesystem. See rules for the C<{per}>
key.

If the C<dfportable()> call fails for any reason, it will return
C<undef>. This will probably happen if you do anything crazy like try
to get information for /proc, or if you pass an invalid filesystem name,
or if there is an internal error. C<dfportable()> will C<croak()> if you pass
it a undefined value.

Requirements:
Your system must contain C<statvfs()>, C<statfs()>, C<GetDiskFreeSpaceA()>, or C<GetDiskFreeSpaceEx()>.
You must be running Perl 5.6 or higher.

=head1 AUTHOR

Ian Guthrie
IGuthrie@aol.com

Copyright (c) 2006 Ian Guthrie. All rights reserved.
               This program is free software; you can redistribute it and/or
               modify it under the same terms as Perl itself.

=head1 SEE ALSO

statvfs(2), statfs(2), df(1), GetDiskFreeSpaceA, GetDiskFreeSpaceEx, Filesys::Df

perl(1).

=cut
