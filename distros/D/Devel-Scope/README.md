perl-devel-scope
==================

Scope based debug!

Name
-----
Devel::Scope

[![Build Status](https://secure.travis-ci.org/xxfelixxx/perl-term-colormap.svg)](http://travis-ci.org/xxfelixxx/perl-devel-scope)
[![Coverage Status](https://coveralls.io/repos/github/xxfelixxx/perl-devel-scope/badge.svg?branch=master)](https://coveralls.io/github/xxfelixxx/perl-devel-scope?branch=master)
[![CPAN version](https://badge.fury.io/pl/Devel-Scope.svg)](https://badge.fury.io/pl/Devel-Scope)

Version
---------
Version 0.04

Synopsis
-----------
Perl library providing a debug function that prints based on the scoping level.

    use Devel::Scope qw( debug );

    debug("main"); # Main Scope

    sub foo {
        debug("inside foo"); # Function Scope
        if ( 1 ) {
            debug("if true start calculations"); # Function Scope + 1
            for my $x ( 0..3 ) {
                debug("x is set to $x"); # Function Scope + 2
                for my $y ( 0..3 ) {
                    debug("x=$x, y=$y"); # Function Scope + 3
                    for my $z ( 0 ..3 ) {
                        debug("x=$x, y=$y, z=$z"); # Function Scope + 4
                    }
                }
            }
            debug("end of calculaions");
        }
        debug("leaving foo");
    }

    ...

    DEVEL_SCOPE_DEPTH=3 perl foo.pl
