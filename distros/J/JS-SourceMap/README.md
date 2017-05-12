# JS SourceMaps for Perl

Since everyone deploys minified/combined wads of JS goo, debugging
errors in the field can be a bitch.  The idea behind sourcemaps is to
provide a way for web developers to debug their code once deployed.
Sourcemaps provide a compact index into the minified source that lets
you map the file/line/col given to you in a JS runtime error thrown by
your minified JS back into the real file/line/col in your source code.

A decent albeit dated tutorial can be found here:
    https://www.html5rocks.com/en/tutorials/developertools/sourcemaps/

The use case for this module is a server-side component in Perl that
receives JS runtime error information somehow from a web application's
JS front end.  You generally have the source map available on the
server already but there is a `discover` function in `JS::SourceMap`
that will search JS code for a pointer to its source map as per
convention.  You'll have to fetch the URL that `discover` finds
yourself, though.

This module is inspired by https://github.com/mattrobenolt/python-sourcemap
It hews fairly closely to that implementation.  I brought over all of
the same test inputs (t/fixtures) and all of the tests that
made sense (no iterators in Perl).

## Source

Module github repo: https://github.com/StAlphonsos/perl-sourcemap
Feel free to open issues there if you find them.  The module is also
available on CPAN.

## Installation

It's the usual deal:

    $ perl Makefile.PL
    $ make
    $ make test
    $ [ `uname` != OpenBSD ] && alias doas=sudo # doesn't everyone do this?
    $ doas make install

## Usage

Please read the JS::SourceMap POD, but in a nutshell:

    #!/usr/bin/perl
    # args: mapfile line col
    # output: line col sourcefile
    use JS::SourceMap;

    $map = JS::SourceMap::load(shift(@ARGV)) or die "bad map";
    $token = $map->lookup(@ARGV) or die "line/col out of bounds";
    print sprintf("%d %d %s\n",$token->src_line,$token->src_col,$token->src);

The web is a scary place.  Enjoy.
