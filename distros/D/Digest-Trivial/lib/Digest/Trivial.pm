package Digest::Trivial;

use strict;
use warnings;
no  warnings 'syntax';

use Exporter ();
use AutoLoader;

our @ISA     = qw (Exporter);
our @EXPORT  = qw (trivial_x trivial_s);
our $VERSION = '2010011301';

require XSLoader;
XSLoader::load ('Digest::Trivial', $VERSION);

1;

__END__

=pod

=head1 NAME

Digest::Trivial - Trivial but fast ways to map strings to small integers

=head1 SYNOPSIS

  use Digest::Trivial;

  say trivial_x "hello, world";       #   12
  say trivial_s "hello, world";       #  136

=head1 DESCRIPTION

The module provides 2 methods that take a string as input, and return
an integer (the digest) between 0 and 255 inclusive. The goal is to
provide functions with algorithms, that are I<< fast >>, I<< repeatable
>>, and map to all possible integers in the range roughly evenly. They
aren't cryptically secure; the returned integer is easily guessable,
and it's trivial to create a string that maps to a certain integer.

The following functions are available:

=over 4

=item C<< trivial_x >>

Calculates the digest by C<< xor >>ring the code points, returning the
resulting value. 

=item C<< trivial_s >>

Calculates the digest by adding the code points, returning the
sum module 256.

=back

=head2 Caveats

There are a few things to consider.

=over 4

=item *

Since adding and C<< xor >>ring are symmetric operations, two strings
that only differ by the order in which the characters appear in the
string will be mapped to the same number.

=item *

The functions look at the strings I<< byte >>wise. That is, a string
may be mapped to a different integer depending whether it's UTF-8
encoded or not.

=item *

If there are no non-ASCII characters present in the string, C<< trivial_x >>
will not return an integer above 127. Since C<< xor >>ring a value with
itself returns 0, C<< trivial_x >> effectively takes the digest of the
characters that appear an odd times in the string.

=back

=head2 Exports

By default, C<< Digest::Trivial >> exports both C<< trivial_x >> and
C<< trivial_s >>. Use an explicite (possibly empty) import list if
you want a subset of the default.

=head1 IMPLEMENTATION

The algorithms have been implemented in XS for efficiency reasons.

=head1 BUGS

If the argument of C<< trivial_s >> or C<< trivial_x >> contains a 
C<< NUL >> byte, only the part of the string preceeding the C<< NUL >>
byte is used to calculate the digest.

=head1 SEE ALSO

C<< Digest::MD5 >>, C<< Digest::MD4 >>, C<< Digest::SHA1 >>, etc.

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<< git://github.com/Abigail/Digest--Trivial.git >>.

=head1 AUTHOR

Abigail, L<< mailto:digest-trivial@abigail.be >>.

=head1  COPYRIGHT and LICENSE

Copyright (C) 2009 by Abigail.
  
Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:
        
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 INSTALLATION

To install this module, run, after unpacking the tar-ball, the
following commands:

   perl Makefile.PL
   make
   make test
   make install

You will need a C compiler to install the module.

=cut
