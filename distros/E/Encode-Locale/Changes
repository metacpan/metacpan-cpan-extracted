## 2015-06-09  Release 1.05

Mats Peterson (1):
      Use GetACP() to get the ANSI code page like before

Thomas Sibley (1):
      Conditionalize the Win32::Console recommendation



## 2015-01-12  Release 1.04

Ed J (5):

* Actually include all the tests in the MANIFEST
* use Test::More and warnings
* Tidy t/alias.t
* t/arg.t TODO some actual ARGV testing
* Use Win32::GetConsoleCP/GetConsoleOutputCP if available

Gisle Aas (3):

* Documentation spell fix
* SEE ALSO Term::Encoding [RT#98138]

David Steinbrunner (1):

* typo fix



## 2012-01-11  Release 1.03

Documentation spelling fixes and tweaks to improve testing on Windows.


## 2011-03-28  Release 1.02

Added supporting hacks for GB18030 and roman8. [RT#66373] [RT#67010]


## 2011-02-22  Release 1.01

Avoid compilation warnings (RT#65975).  Thanks to Goro Fuji.


## 2011-01-23  Release 1.00

Documentation tweaks.


## 2010-10-23  Release 0.04

Look up the ANSI code page on Windows and alias this one as the "locale"
encoding.

Providide the reinit() function to be called if something is changed
in the locale and you need to re-initialize the encodings set up by
this module.

Improved documentation.


## 2010-10-20  Release 0.03

Changed the default for decode_argv() to match Encode's default.
It became too strange to tell people to pass FB_DEFAULT to get the
non-default behaviour.

Changed $ENCODING_FS into $ENCODING_LOCALE_FS (as already documented below),
but not implemented as such.

Workaround for test failure where the Encode does not know about the "646"
encoding alias.

Documentation tweaks.


## 2010-10-13  Release 0.02

...where I realized that I could not get away with a single locale encoding.
Now `Encode::Locale` provides 4 encoding names that often will map to the same
underlying encoding.  I've used the following names:

    locale        $ENCODING_LOCALE
    locale_fs     $ENCODING_LOCALE_FS
    console_in    $ENCODING_CONSOLE_IN
    console_out   $ENCODING_CONSOLE_OUT

The first one is the encoding specified by the POSIX locale (or the equivalent
on Windows).  This can be set by the user.  The second one (`locale_fs`) is the
encoding that should be used when interfacing with the file system, that is the
encoding of file names.  For some systems (like Mac OS X) this is fixed system
wide and the same for all users.  Last; some systems allow the input and output
encoding for data aimed at the console to differ so there are separate entries
for these.  For classic POSIX systems all 4 of these will all denote the same
encoding.

This release also introduce the function env() as a Unicode interface to the
%ENV hash (the process environment variables).  We don't want to decode the ENV
%values in-place because this also affects what the child processes
observes.  The %ENV hash should always contain byte strings.


## 2010-10-11  Release 0.01

Initial release
