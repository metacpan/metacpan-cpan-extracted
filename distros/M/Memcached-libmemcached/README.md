# Memcached-libmemcached

[![Build Status](https://secure.travis-ci.org/timbunce/Memcached-libmemcached.png)](http://travis-ci.org/timbunce/Memcached-libmemcached/)

Memcached::libmemcached is a very thin, highly efficient, wrapper around the
libmemcached library.

It gives full access to the rich functionality offered by libmemcached.
libmemcached is fast, light on memory usage, thread safe, and provides full
access to server side methods.

 - Synchronous and Asynchronous support.
 - TCP and Unix Socket protocols.
 - A half dozen or so different hash algorithms.
 - Implementations of the new cas, replace, and append operators.
 - Man pages written up on entire API.
 - Implements both modulo and consistent hashing solutions. 

# INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test           (see TESTING below)
    make install

Note that the "perl Makefile.PL" step will configure and build a private copy
of libmemcached from source. So don't be surprised to see pages of output
during that step.

If you'd like to have the commandline tools that come with libmemcached installed, invoke Makefile.PL as:

    perl Makefile.PL --bin
    
See http://libmemcached.org for details.


# TESTING

The "make test" command can run some tests without using a memcached server.
Others are skipped unless a memcached server can be found.
By default the tests look for a memcached server at the standard port on localhost.

To use one or more other servers set the PERL_LIBMEMCACHED_TEST_SERVERS
environment variable to a comma separated list of hostname:port values.

Most tests require just one server but some require at least 5 servers.

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Memcached::libmemcached

You can also look for information at:

    RT, CPAN's request tracker
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Memcached-libmemcached

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Memcached-libmemcached

    CPAN Ratings
        http://cpanratings.perl.org/d/Memcached-libmemcached

    Search CPAN
        http://search.cpan.org/dist/Memcached-libmemcached


# COPYRIGHT AND LICENCE

Copyright (C) 2008, 2013 Tim Bunce

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

# DEVELOPER TOOLS

Debugging

    make realclean # if perl Makefile.PL already run
    perl Makefile.PL -g

Profiling

    make realclean # if perl Makefile.PL already run
    perl Makefile.PL -pg

Test coverage analysis

    make realclean # if perl Makefile.PL already run
    perl Makefile.PL -cov
    make
    make testcover

Install commandline tools from libmemcached

    perl Makefile.PL -bin
    make 
    make install

