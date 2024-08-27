IO::SocketAlarm
---------------

### About

This module uses a background thread to send UNIX signals to the main process when
I/O status changes on an file descriptor.

### Installing

When distributed, all you should need to do is run

    perl Makefile.PL
    make install

or better,

    cpanm IO-SocketAlarm-0.001.tar.gz

or from CPAN:

    cpanm IO::SocketAlarm

### Developing

However if you're trying to build from a fresh Git checkout, you'll need
the Dist::Zilla tool (and many plugins) to create the Makefile.PL

    cpanm Dist::Zilla
    dzil listdeps | cpanm
    dzil build

While Dist::Zilla takes the busywork and mistakes out of module authorship,
it fails to address the need of XS authors to easily compile XS projects
and run single testcases, rather than the whole test suite.  For this, you
might find the following script handy:

    ./dzil-prove t/01-load.t  # or any other testcase

which runs "dzil build" to get a clean dist, then enters the build directory
and runs "perl Makefile.PL" to compile the XS, then "prove -lvb t/01-load.t".

### Copyright

This software is copyright (c) 2024 by IntelliTree Solutions

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
