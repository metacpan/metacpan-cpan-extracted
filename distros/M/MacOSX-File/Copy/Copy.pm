package MacOSX::File::Copy;

=head1 NAME

MacOSX::File::Copy - copy() on MacOS X

=head1 SYNOPSIS

  use MacOSX::File::Copy;
  copy($srcpath, $dstpath [,$buffersize]);
  move($srcpath, $dstpath);

=head1 DESCRIPTION

MacOSX::File::Copy provides copy() and move() as in File::Copy.  Unlike
File::Copy (that also comes with MacOS X), MacOSX::File::Copy preserves
resouce fork and Finder attirbutes.  Consider this as a perl version
of CpMac and MvMac which comes with MacOS X developer kit.

=cut

use 5.006;
use strict;
use warnings;
use Carp;

our $RCSID = q$Id: Copy.pm,v 0.70 2005/08/09 15:47:00 dankogai Exp $;
our $VERSION = do { my @r = (q$Revision: 0.70 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
our $DEBUG;

=head2 EXPORT

copy() and move()

=cut

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
		 copy
		 move
		 );

bootstrap MacOSX::File::Copy $VERSION;
use MacOSX::File;

our $MINBUFFERSIZE     = 4096;
our $DEFAULTBUFFERSIZE = $MINBUFFERSIZE * 1024;
our $MAXBUFFERSIZE     = $DEFAULTBUFFERSIZE * 64;

# Preloaded methods go here.

use Errno;
use File::Basename;

=over 4

=item copy($from, $to, [$maxbufsize, $preserve])

copies file from path $from to path $to, just like
File::Copy::copy().  Returns 1 on success and 0 otherwise.  On error
$MacOSX::File::OSErr is set when appropriate.

copy() can optionally take maximum buffer size as an argument.  This
value sets the limit of copy buffer.  If less value is required copy()
automagically allocates smaller amount of memory.  When in doubt just
leave it as default.

The last argument, $preserve tells copy() whether it should preserve
file attributes from the source file like like C</bin/cp -p>.  Default
is 0.

=cut

sub copy($$;$$){
    my ($src, $dst, $mbs, $preserve) = @_;
    $mbs ||= $DEFAULTBUFFERSIZE;
    $mbs < $MINBUFFERSIZE and $mbs = $MINBUFFERSIZE;
    $mbs > $MAXBUFFERSIZE and $mbs = $MAXBUFFERSIZE;
    $preserve ||= 0;

    my ($srcdev, $srcino, $srcmode, $srcuid, $srcgid, $srcatime, $srcmtime)
	= (lstat($src))[0,1,2,4,5,8,9];
    unless(-f _){
	$MacOSX::File::OSErr = -43; # fnfErr;
	$! = &Errno::ENOENT;
	return;
    }
    my ($dstdev, $dstino) = (lstat($dst))[0,1];
    if (-e _){ # target exists
	# before unlinking $dst, we check if $src and $dst are identical
	$srcino == $dstino and $srcdev == $dstdev
	    and carp "$src and $dst are identical";
	unlink $dst or return;
    }
    if (my $err = xs_copy($src, $dst, $mbs, $preserve)){
	return;
    }else{
	if ($preserve){
	    # These are included in FSCatalogInfo
	    # chown $srcuid, $srcgid, $src;
	    # chmod ($srcmode & 07777), $src;
	    # utime $srcatime, $srcmtime, $src;
	}
	return 1;
    }
}

sub attic($){
    my $path = shift;
    return dirname($path) . '/._' . basename($path);
}

sub dev($){
    my $path = shift;
    return (lstat($path))[0];
}

#
# This one is now xs_free because experiments have proven
# that simple rename() works
#

=item move($from, $to)

moves file from path $from to path $to, just like File::Copy::move().
Within same volume it uses rename().  If not it simply copy() then
unlink().  

This subroutine uses no xs.

=back

=cut

sub move($$){
    my ($src, $dst) = @_;
    my $srca = attic($src);
    my $dstdir = dirname($dst);
    my $srcdev = dev($src);
    my $dstdev = dev($dstdir);
    $DEBUG and warn "dev($src) = $srcdev, dev($dstdir) = $dstdev";
    if ($srcdev == $dstdev){
	$DEBUG and warn "Move within same volume";
	rename $src, $dst;
	if (-f $srca){
	    my $dsta = attic($dst);
	    $DEBUG and warn "$srca found. rename this to $dsta";
	    rename $srca, $dsta or return 1;
	}
	return 1;
    }else{
	$DEBUG and warn "Cross-volume move";
	copy($src, $dst) and unlink $src, $srca;
    }
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 AUTHOR

Dan Kogai <dankogai@dan.co.jp>

=head1 BUGS

Files w/ Unicode names now copies with no problem.  FSSpec-based operations
are completely gone.  Now this module does pure-FSRef operation.  As a
result, MoreFiles is now removed from distribution.

=head1 APPENDIX -- How Darwin handles HFS+

  Here is a simple diagram of how Darwin presents HFS+ volume

               HFS+                  Darwin
  ---------------------------------------------------
  Filename:    Unicode (UCS2)        UTF-8
  Path Delim:  :                     /
               /                     :

  To implement file copy myself, I had to implement this
filename-mapping myself since file copy is done on Carbon, 
not Darwin.  Here is how.

 1.  Get FSRef of destination DIRECTORY
 2.  convert all occurance of ':' to '/' in destination BASENAME
     Since basename is still in UTF-8, it will not clobber anything.
 3.  convert the resulting basename to Unicode
 4.  Now Feed them to FSCreateFileUnicode()

  See Copy/filecopy.c for details

=head1 SEE ALSO

L<File::Copy>

F</Developer/Tool/CpMac>

F</Developer/Tool/MvMac>

=head1 COPYRIGHT

Copyright 2002 Dan Kogai <dankogai@dan.co.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
