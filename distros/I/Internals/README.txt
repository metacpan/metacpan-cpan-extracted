
    ===================
      "Internals" 1.1
    ===================


Copyright (c) 2001 by Steffen Beyer.
All rights reserved.

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, i.e., under the
terms of the "Artistic License" or the "GNU General Public License".

Please refer to the files "Artistic.txt" and "GNU_GPL.txt"
in this distribution for details!


Installation:
-------------

Just install as usual:

perl Makefile.PL
make
make install


What does it do:
----------------

This module allows you to write-protect and write-enable
your Perl variables, objects and data structures.

Moreover, the reference count of any Perl variable can
be read and set.

You can never pass the object directly on which to
perform the desired action, you always have to pass
a reference to the variable or data structure in
question.

This comes in handy for objects and anonymous data
structures, where you only have a reference anyway!

BEWARE: This module is DANGEROUS!

DO NOT attempt to unlock Perl's built-in variables!

DO NOT manipulate reference counts unless you know
exactly what you're doing!

ANYTHING might happen! Hell might break loose! :-)

YOU HAVE BEEN WARNED!

