package Encode::BOCU1::XS;

use 5.008006;
use strict;
use warnings;

use base qw(Encode::Encoding);
__PACKAGE__->Define('bocu1');

use Encode::Alias;
define_alias( qr/^bocu.1$/i => '"bocu1"');
define_alias( qr/^bocu$/i => '"bocu1"');

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Encode::BOCU1::XS', $VERSION);

1;
__END__

=head1 NAME

Encode::BOCU1::XS - Perl extension for encoding / decoding BOCU-1 string.
                    Works as part of Encode.pm

=head1 SYNOPSIS

use Encode::BOCU1::XS;

$string = 'UTF-8 text to convert...'
Encode::from_to($string,'utf8','bocu1');

$string = 'BOCU-1 data to convert...'
Encode::from_to($string,'bocu1','shiftjis');

=head1 DESCRIPTION

BOCU-1 is a MIME-compatible application of the Binary Ordered Compression for Unicode
[BOCU] base algorithm developed and patented by IBM.

Encode::BOCU1::XS enables to convert any encoding systems supported by Encode.pm
from/to BOCU-1 through UTF-8.
It uses a lot less CPU than Encode::BOCU1, the original pure-perl module.

=head1 SEE ALSO

http://www.unicode.org/notes/tn6/
http://icu.sourceforge.net/docs/papers/binary_ordered_compression_for_unicode.html

=head1 COPYRIGHT AND LICENSE

Source files found under IBM_CODES/ directory
 * bocu1.h (constants and macros)
 * bocu1.c (encoder and decoder functions)
 * bocu1tst.c (test code with main() function)
from "Sample C Code" on http://www.unicode.org/notes/tn6/ are

Copyright (C) 2002, International Business Machines Corporation and others.
All Rights Reserved.

The "Sample C Code" is under the X license (ICU version).
ICU License : http://dev.icu-project.org/cgi-bin/viewcvs.cgi/*checkout*/icu/license.html

BOCU "Binary-Ordered Compression For Unicode" is a patent-protected technology of IBM.
(US Patent 6737994)

The XS glue code is written by Naoya Tozuka and 
Copyright (C) 2006, Naoya Tozuka E<lt>naoyat@naochan.comE<gt>.
As with the original C code, this port is licensed under the X license (ICU version).
also distributed under the ICU License.

=cut
