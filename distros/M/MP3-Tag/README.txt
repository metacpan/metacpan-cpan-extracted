                           MP3::Tag
============================================================

This is a perl module to read/write ID3v1, ID3v1.1 and ID3v2.3
tags of mp3-files. (Other tags hopefully to follow).

To install the MP3::TAG module you simply do:

perl Makefile.PL
make
make test
make install   (as root)

If you find some errors while doing this, please send me
an email describing the problems.

You need to have the modules Compress::Zlib and File::Basename
installed. If you are missing one of these (perl Makefile.PL 
should warn you) you can find them on CPAN (www.cpan.org).

In the directory examples, you find 4 examples, how to use
the module. You can read the documentation of this
module with 

man MP3::Tag
man MP3::Tag::ID3v1
man MP3::Tag::ID3v2
man MP3::Tag::ID3v2_Data

More information about this project, new releases and so on, can
be found at:         

http://tagged.sourceforge.net

Success with this

  Thomas

  <thg@users.sourceforge.net>


                           tk-tag.pl
==============================================================

In the directory tk-tag you can find a graphical interface
for MP3::Tag. See the README file in that directory.


                           Copyright
==============================================================

Copyright (c) 2000-2004 Thomas Geffert.  All rights reserved. 
This program is free software; you can redistribute it and/or
modify it under the terms of the Artistic License, distributed
with Perl.
