# NAME

Math::PRBS - Generate Pseudorandom Binary Sequences using an iterator-based Linear Feedback Shift Register

# SYNOPSIS

    use Math::PRBS;
    my $x3x2  = Math::PRBS->new( taps => [3,2] );
    my $prbs7 = Math::PRBS->new( prbs => 7 );
    my ($i, $value) = $x3x2t->next();
    my @p7 = $prbs7->generate_all();
    my @ints = $prbs7->generate_all_int();

# DESCRIPTION

This module will generate various Pseudorandom Binary Sequences (PRBS).  This module creates a iterator object, and you can use that object to generate the sequence one value at a time, or _en masse_.

The generated sequence is a series of 0s and 1s which appears random for a certain length, and then repeats thereafter.  (You can also convert the bitstream into a sequence of integers using the `generate_int` and `generate_all_int` methods.)

It is implemented using an XOR-based Linear Feedback Shift Register (LFSR), which is described using a feedback polynomial (or reciprocal characteristic polynomial).  The terms that appear in the polynomial are called the 'taps', because you tap off of that bit of the shift register for generating the feedback for the next value in the sequence.

# INSTALLATION

To install this module, use your favorite CPAN client.

For a manual install, type the following:

    perl Makefile.PL
    make
    make test
    make install

(On Windows machines, you may need to use "dmake" or "gmake" instead of "make", depending on your setup.)

# AUTHOR

Peter C. Jones `<petercj AT cpan DOT org>`

Please report any bugs or feature requests thru the web interface at
[https://github.com/pryrt/Math-PRBS/issues](https://github.com/pryrt/Math-PRBS/issues)

<div>
    <a href="https://metacpan.org/pod/Math::PRBS"><img src="https://img.shields.io/cpan/v/Math-PRBS.svg?colorB=00CC00" alt="" title="metacpan"></a>
    <a href="http://matrix.cpantesters.org/?dist=Math-PRBS"><img src="http://cpants.cpanauthors.org/dist/Math-PRBS.png" alt="" title="cpan testers"></a>
    <a href="https://github.com/pryrt/Math-PRBS/releases"><img src="https://img.shields.io/github/release/pryrt/Math-PRBS.svg" alt="" title="github release"></a>
    <a href="https://github.com/pryrt/Math-PRBS/issues"><img src="https://img.shields.io/github/issues/pryrt/Math-PRBS.svg" alt="" title="issues"></a>
    <a href="https://ci.appveyor.com/project/pryrt/math-prbs"><img src="https://ci.appveyor.com/api/projects/status/cj6cbq7u9velb8wx?svg=true" alt="" title="appveyor build status"></a>
    <a href="https://travis-ci.org/pryrt/Math-PRBS"><img src="https://travis-ci.org/pryrt/Math-PRBS.svg?branch=master" alt="" title="travis build status"></a>
    <a href="https://coveralls.io/github/pryrt/Math-PRBS?branch=master"><img src="https://coveralls.io/repos/github/pryrt/Math-PRBS/badge.svg?branch=master" alt="" title="test coverage"></a>
</div>

# COPYRIGHT

Copyright (C) 2016,2018 Peter C. Jones

# LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
