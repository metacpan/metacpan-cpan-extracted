NAME

File::Archive - Figure out what is in an archive file 

SYNOPSIS

  use File::Archive;
  $arch = File::Archive->new($filename);
  $name = $arch->filename;
  $filelist = $arch->catalog;
  $contents = $arch->member($file);

DESCRIPTION

Given an archive file of some kind, these methods 
will determine what type of archive it is, and tell
you what files are contained in that archive. It
will also give you the contents of a particular file
contained in that archive. 

This was written for the Scripts section of CPAN,
so that users could upload tarballs, rather than just
single-file scripts. 

Files can look like something.tar, something.tar.gz,
something.tar.Z, or just something.

PREREQUISITES

  Compress::Zlib
  Archive::Tar version 0.2 or later

BUGS

Still not able to do anything with something.Z compressed
files. I can't quite figure out the docs on Compress::Zlib
Hopefully, someone can point me in the right direction. I
don't think that this is a huge deal, since I would expect
people to use gzip instead.

TO DO

Might also want to think about doing .zip files as well.

AUTHOR

Rich Bowen, <rbowen@rcbowen.com> 
And Kurt for the inspiration to get it done.

---------------------------------------------------
Revision history for Perl extension File::Archive.

0.1  Thu Sep  2 20:56:11 1999
	- original version; created by h2xs 1.19

0.2  Thu Sep  2 21:46:00 1999
	- Added new, filename, type

0.3  Thu Sep  2 22:35:00 1999
	- Added catalog method. Return contents of the file

0.41 Thu Sep  2 23:01:00 1999
	- Started on member method. Added some docs.

0.5  Thu Sep  3 00:04:00 1999
	- Got member method almost working. something.Z files don't
	work yet. But maybe that's OK, since real people use gzip,
	particularly on single files.

0.53 Thu Dec 9 1999
	- Changed it to require at least version 0.20 of Archive::Tar,
	since an important function call seems to have changed name
	between 0.07 and 0.20. Unfortunately, it seems that the various
	members of the CPAN-Testers that tested my code all had
	0.07 installed.

