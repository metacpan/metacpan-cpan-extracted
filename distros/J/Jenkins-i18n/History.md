# History

This document tries to explain why some design decisions were taken during this
project development.

## UTF-8 support

The script `translation-tool.pl` considers converting UTF-8 files to
ASCII, but does that in a improper way using regular expressions.

This might be due the history of Java Unicode support.

In the past releases of Java, there were CLI like
[native2ascii](https://docs.oracle.com/javase/7/docs/technotes/tools/solaris/native2ascii.html),
but it seems such need was deprecated in newer versions of Java (and OpenJDK).

See also https://bugs.openjdk.java.net/browse/JDK-8074431 explaining the
subject.

On the other hand, it seems to that Jenkins should be able to support reading
those properties files in UTF-8 by default nowadays, but that isn't decided so
far.

