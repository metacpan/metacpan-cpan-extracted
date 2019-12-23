# NAME

IO-stringy - I/O on in-core objects like strings and arrays

# SYNOPSIS

```perl
use strict;
use warnings;

use IO::AtomicFile; # Write a file which is updated atomically
use IO::InnerFile; # define a file inside another file
use IO::Lines; # I/O handle to read/write to array of lines
use IO::Scalar; # I/O handle to read/write to a string
use IO::ScalarArray; # I/O handle to read/write to array of scalars
use IO::Wrap; # Wrap old-style FHs in standard OO interface
use IO::WrapTie; # Tie your handles & retain full OO interface

# ...
```

# DESCRIPTION

This toolkit primarily provides modules for performing both traditional
and object-oriented i/o) on things _other_ than normal filehandles;
in particular, [IO::Scalar](https://metacpan.org/pod/IO%3A%3AScalar), [IO::ScalarArray](https://metacpan.org/pod/IO%3A%3AScalarArray),
and [IO::Lines](https://metacpan.org/pod/IO%3A%3ALines).

In the more-traditional IO::Handle front, we
have [IO::AtomicFile](https://metacpan.org/pod/IO%3A%3AAtomicFile)
which may be used to painlessly create files which are updated
atomically.

And in the "this-may-prove-useful" corner, we have [IO::Wrap](https://metacpan.org/pod/IO%3A%3AWrap),
whose exported wraphandle() function will clothe anything that's not
a blessed object in an IO::Handle-like wrapper... so you can just
use OO syntax and stop worrying about whether your function's caller
handed you a string, a globref, or a FileHandle.

# AUTHOR

Eryq (`eryq@zeegee.com`).
President, ZeeGee Software Inc (`http://www.zeegee.com`).

# CONTRIBUTORS

Dianne Skoll (`dfs@roaringpenguin.com`).

# COPYRIGHT & LICENSE

Copyright (c) 1997 Erik (Eryq) Dorfman, ZeeGee Software, Inc. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
