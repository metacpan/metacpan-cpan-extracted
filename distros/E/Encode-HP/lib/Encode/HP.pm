package Encode::HP;
use 5.007003;
our $VERSION = '0.03';
use Encode;
use XSLoader;
XSLoader::load(__PACKAGE__,$VERSION);

Encode::define_alias( qr/\bgreek8$/i    => '"hp-greek8"' );
Encode::define_alias( qr/\br(oman)?8$/i => '"hp-roman8"' );
Encode::define_alias( qr/\br(oman)?9$/i => '"hp-roman9"' );
Encode::define_alias( qr/\bthai8$/i     => '"hp-thai8"'  );
Encode::define_alias( qr/\bturkish8$/i  => '"hp-turkish8"' );

1;
__END__

=head1 NAME
 
Encode::HP - Extra sets of HP encodings

=head1 VERSION

This document describes version 0.03 of Encode::HP, released September 15, 2013.

=head1 SYNOPSIS

    use Encode;
    use Encode::HP;

    # Greek8
    $greek8 = encode("hp-greek8", $utf8);
    $utf8 = decode("hp-greek8", $greek8);

=head1 DESCRIPTION

Perl 5.7.3 and later ship with with C<hp-roman8> encoding, however, there are
additional HP encodings that are unsupported but may be encountered; hence,
this CPAN module tries to provide the rest of them.

=head1 ENCODINGS

This version includes the following encoding tables:

  Canonical        Alias
  -----------------------------------------------------------------------------
  hp-greek8        /\bgreek8$/i
  hp-roman9        /\br(oman)?9$/i
  hp-thai8         /\bthai8$/i
  hp-turkish8      /\bturkish8$/i

This version also adds the following alises:

  Canonical        Alias
  -----------------------------------------------------------------------------
  hp-roman8        /\br(oman)?8$/i

=head1 UNSUPPORTED ENCODINGS

The following are unsupported due to the lack of mapping data.

  '8'  - arabic8, hebrew8, and kana8 
  '15' - japanese15, korean15, and roi15

If you have this information or access to an HP-UX system, please consider
providing this data. Information on how to generate this data from an HP-UX
system is available here:

L<http://sourceware.org/bugzilla/show_bug.cgi?id=5464>.

=head1 SEE ALSO

glibc charmaps: L<https://sourceware.org/git/?p=glibc.git;a=tree;f=localedata/charmaps>

Generating a charmap from HP-UX: L<http://sourceware.org/bugzilla/show_bug.cgi?id=5464>

L<Encode>

=head1 ACKNOWLEDGEMENTS

Maps for C<hp-greek8>, C<hp-roman9>, C<hp-thai8>, and C<hp-turkish8> are
generated from glibc charmaps.

=head1 AUTHORS

John Wang E<lt>johncwang@gmail.comE<gt>, L<http://johnwang.com> 

=head1 COPYRIGHT

Copyright 2013 by John Wang E<lt>johncwang@gmail.comE<gt>.

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