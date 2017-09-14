# Example Extractor in Java

This directory contains a sample message extractor written in Java.

Interfacing Java with Perl is considerably more complicated than interfacing
a scripting language with Perl.  Consequently, the code you find here will
probably not win a prize and the implementation has a couple of caveats.

## Installing Inline::Java

Installing `Inline::Java` is a little bit different.  You have to
invoke `sudo cpan install Inline::Java::Class` and not just 
`sudo cpan install Inline::Java`.

If the Java compiler cannot be found during the installation, try playing
around with the environment variable `JAVA_HOME`.  The location is
hard-coded into the installed module.  Once everything works, the
environment variable is ignored.

## Possible Exceptions

You can call all methods of the Perl object from inside Java but any return
value but a scalar will probably throw an exception.  You can prevent this
by implementing wrapper classes like it is done for the keyword definitions.
See the Java source file for details.

## Singleton

Only one Java extractor can be instantiated from Perl at a time.  This is
ugly but does notr really pose a problem.

If you find more problems, contact the author or open an issue.