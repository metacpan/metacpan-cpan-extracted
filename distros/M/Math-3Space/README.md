Math::3Space
------------

### About

This module implements the sort of 3D coordinate space math that would
typically be done using a 4x4 matrix, but instead uses a 3x4 matrix composed
of axis vectors (xv, yv, zv) and an origin point.  This gives up the ability
to skew the coordinate space but uses half as many multiplications per projection.

The coordinate space objects are arranged in a tree structure that allows you
to automatically project points and vectors from one space to another.
The coordinate spaces can be exported as 4x4 matrices for use with OpenGL or
other common 3D systems.

This module is implemented in XS, and requires a C compiler.

### Installing

When distributed, all you should need to do is run

    perl Makefile.PL
    make install

or better,

    cpanm Math-3Space-0.003.tar.gz

or from CPAN:

    cpanm Math::3Space

### Developing

However if you're trying to build from a fresh Git checkout, you'll need
the Dist::Zilla tool (and many plugins) to create the Makefile.PL

    cpanm Dist::Zilla
    dzil authordeps | cpanm
    dzil build

While Dist::Zilla takes the busywork and mistakes out of module authorship,
it fails to address the need of XS authors to easily compile XS projects
and run single testcases, rather than the whole test suite.  For this, you
might find the following script handy:

    ./dzil-prove t/04-transform.t  # or any other testcase

which runs "dzil build" to get a clean dist, then enters the build directory
and runs "perl Makefile.PL" to compile the XS, then "prove -lvb t/04-transform.t

### Copyright

This software is copyright (c) 2023-2024 by Michael Conrad

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
