package Encode::IBM;
 
use 5.008;
use strict;
use Encode;
use Encode::IBM::835SOSI;
use Encode::IBM::835SOSI::TSGH;
use Encode::IBM::947SOSI;
use Encode::IBM::939SOSI;

BEGIN {
    our $VERSION = '0.11';

    local $@;
    eval {
        require XSLoader;
        XSLoader::load(__PACKAGE__, $VERSION);
        1;
    } or do {
        require DynaLoader;
        push our @ISA, 'DynaLoader';
        __PACKAGE__->bootstrap($VERSION);
    };
};

1;

__END__

=head1 NAME
 
Encode::IBM - IBM-specific encoding mappings

=head1 VERSION

This document describes version 0.11 of Encode::IBM, released
January 7, 2008.

=head1 SYNOPSIS

    use Encode;
    use Encode::IBM;
    binmode( STDIN, ':encoding(ibm-835)' );
    binmode( STDOUT, ':encoding(ibm-947-sosi)' );

=head1 DESCRIPTIONS

This module provides encoding extensions of IBM-specific mappings.
The sources are from the ICU mapping repository:

    http://oss.software.ibm.com/cvs/icu/charset/data/ucm/

=head1 ENCODINGS

    ibm-835
    ibm-937
    ibm-939
    ibm-947

    ibm-835-sosi
    ibm-939-sosi
    ibm-947-sosi

=head1 SEE ALSO

L<Encode>

=head1 COPYRIGHT

Copyright 2004, 2005, 2006, 2007, 2008 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
