Some functionality in EBook::Tools is only available with additional
helper applications.  This is a quick guide to what they are and how
to find them.


====
Tidy
====

This tool is used to clean up HTML files, making them conformant to a
given HTML/XHTML specification.  The main development page for Tidy
is:

http://tidy.sourceforge.net/

A MSWin32 executable (and GUI) are available from:

http://www.paehl.com/open_source/?HTML_Tidy_for_Windows


==========
ConvertLit
==========

ConvertLit is a program for downconverting and extracting MS Reader
(.lit) e-books.  Source code and MSWin32 executable can be found at:

http://www.convertlit.com/download.php

A MSWin32 GUI for ConvertLit can be found at:

http://dukelupus.pri.ee/convertlit.php

=========
Kindlegen
=========

Kindlegen is the replacement for Mobigen, a command-line executable
originally provided by Mobipocket and now by Amazon for creating
Mobipocket .mobi/.prc files.

It is made available from Amazon Kindle's Publishing Program page at:

http://www.amazon.com/gp/feature.html?docId=1000234621

The old mobigen executable (see below) will still be found, but using
Kindlegen is recommended.


=========
MobiDeDRM
=========

MobiDeDRM is a Python script for downconverting Mobipocket e-books,
written by 'Dark Reverser'.  The last published version was
MobiDeDRM-0.02.py, but patches are available to take that up to
MobiDeDRM-0.04.py.  Due to legal troubles, there is no official home
page for this, but more information may be found at:

http://www.mobileread.com/forums/showthread.php?t=20341

and

http://www.mobileread.com/forums/showthread.php?t=31095

and you may have some luck searching for it on pastebin.com


=======
Mobigen
=======

Mobigen is an obsolete command-line executable provided by Mobipocket
for creating Mobipocket .mobi/.prc files as an alternative to their
GUI for doing the same.  Use of Kindlegen (see above) in its place is
strongly recommended, as Mobigen is known to produce incorrect results
when given Unicode text.

It is made available from the Mobipocket Developer Center at:

http://www.mobipocket.com/dev/

The direct link to the MSWin32 executable is:

http://www.mobipocket.com/soft/prcgen/mobigen.zip

Although it isn't currently linked to from the Mobipocket Developer
Center page, there is also a Linux executable available:

http://www.mobipocket.com/soft/prcgen/mobigen_linux.tar.gz
