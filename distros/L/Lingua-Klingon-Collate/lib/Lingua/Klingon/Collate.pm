package Lingua::Klingon::Collate;
# vim:set tw=72 sw=2:

use 5.005;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::Klingon::Collate ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
    strxfrm
    strunxfrm
    strcoll
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);
$VERSION = '1.03';

my %xfrm = (
    a   => 'a',
    b   => 'b',
    ch  => 'c',
    D   => 'd',
    e   => 'e',
    gh  => 'f',
    H   => 'g',
    I   => 'h',
    j   => 'i',
    l   => 'j',
    m   => 'k',
    n   => 'l',
    ng  => 'm',
    o   => 'n',
    p   => 'o',
    q   => 'p',
    Q   => 'q',
    r   => 'r',
    S   => 's',
    t   => 't',
    tlh => 'u',
    u   => 'v',
    v   => 'w',
    w   => 'x',
    y   => 'y',
    "'" => 'z',
);

my %unxfrm = reverse %xfrm;

my $letter = qr/tlh|ch|gh|ng(?!h)|[abDeHIjlmnopqQrStuvwy']/;
my $nonletter = qr/[^a-zA-Z']/;


sub strcoll ($$) {
  strxfrm($_[0]) cmp strxfrm($_[1]);
}


sub strxfrm {
  # TODO use Lingua::Klingon::Segment for this
  my @result;

  for my $string (wantarray ? @_ : $_[0]) {
    # only transform letters; leave all the rest as it is
    (my $copy = $string) =~ s/($letter)/$xfrm{$1}/g;
    push @result, $copy;
  }

  wantarray ? @result : $result[0];
}


sub strunxfrm {
  my @result;

  for my $string (wantarray ? @_ : $_[0]) {
    (my $copy = $string) =~ s/([a-z])/$unxfrm{$1}/g;
    push @result, $copy;
  }

  wantarray ? @result : $result[0];
}


1;
__END__

=head1 NAME

Lingua::Klingon::Collate - Sort words in Klingon sort order

=head1 VERSION

This document refers to version 1.03 of Lingua::Klingon::Collate,
released on 2004-05-17.

=head1 SYNOPSIS

  use Lingua::Klingon::Collate;
  my @sorted_words;
  @sorted_words = sort { Lingua::Klingon::Collate::strcoll($a, $b) }
                       @words;
  # alternatively
  @sorted_words = sort Lingua::Klingon::Collate::strcoll @words;

or

  use Lingua::Klingon::Collate ':all';
  my @sorted_words;
  @sorted_words = sort { strcoll($a, $b) } @words;
  # alternatively
  @sorted_words = sort strcoll @words;

or

  use Lingua::Klingon::Collate qw( strcoll strxfrm strxfrm );
  my @sorted_words;

  # using strcoll
  @sorted_words = sort strcoll @words;

  # using strxfrm and a Schwartzian Transform
  @sorted_words = map  { $_->[1] }
                  sort { $a->[0] cmp $b->[0] }
                  map  { [ strxform($_), $_ ] }
                  @words;

  # using strxfrm, native sort, and strunxfrm
  # (need to use unary + in front of strxfrm so that it is not
  # treated as the sort sub argument to sort)
  @sorted_words = strunxfrm
                  sort
                  +strxfrm
                  @words;

  
=head1 DESCRIPTION

=head2 Overview

Lingua::Klingon::Collate is a module which allows you to sort words in
Klingon sort order (for example, 'ngan' should sort after 'nob' since
'ng' comes after 'n' in Klingon sort order and counts as one letter).

You can either transform all words into a representation that allows you
to use the normal sort command, or use a subroutine that will transform
a word "on the fly".

Generally, if you are sorting many words, it will be quicker to
transform each word individually and sort the transformed words. You can
either keep a record of which original word matches which transformed
word (as in the example using the Schwartzian Transform), or untransform
the words after sorting (as in the example using strunxfrm).

This module is based on the C library functions strxfrm(3) and
strcoll(3). There is no standard C library function strunxfrm(3).

=head2 Exports

Lingua::Klingon::Collate exports no functions by default, in order to
avoid namespace pollution. However, all functions listed here can be
imported explicitly by naming them, or they can be imported all together
by using the tag ':all'.

=head2 strcoll

This subroutine takes two strings and compares them according to Klingon
sort order. It returns 0 if the two words are equal, a negative number
if the first word sorts before the second one, and a positive number of
the first word sorts after the second one. (This is the same behaviour
as Perl's C<cmp> operator.)

  $result = strcoll('ngan', 'nob'); # $result is positive

This subroutine can also be used as a sort subroutine:

  @sorted_words = sort strcoll @words;

Note that while arguments may contain spaces, punctuation, and other
non-letters, the sort order of these characters relative to letters is
undefined. (For example, it is undefined whether "cha vIlegh" sorts
before or after "cha' vIlegh", since the order of apostrophe and space
is undefined.) However, "cha' vIlegh" sorts after "cha' Dalegh", since
'v' > 'D' and all characters up to that point were equal.

=head2 strxfrm

This subroutine takes one or more strings as input and transforms them
into a representation such that using the default sort on two outputs of
this subroutine is equivalent to sorting the corresponding inputs with
C<strcoll>.

The transformed string currently represents all Klingon characters by
one lower-case letter each; however, this is an implementation detail
and is not guaranteed. (For example, upper-case letters rather than
lower-case ones could conceivably be used in the future.)

However, in order to ensure correct sorting under non-ASCII character
sets such as EBCDIC, the only restriction that this module currently
places on the character set is that the code points for letters increase
monotonically from ord('a') to ord('z') and from ord('A') to ord('Z').

This subroutine can be used to pre-process strings in order to sort them
more efficiently.

In list context, it returns a list of transformed strings in the same
order as the input strings. In scalar context, it returns the
transformed version of the first input string.

The result of applying C<strxfrm> to a string that is not made up of
valid Klingon words is undefined.

=head2 strunxfrm

This subroutine takes one or more strings as input and performs the
inverse transformation from C<strxfrm>. Inputs should, therefore, be
valid outputs of C<strxfrm>.

This subroutine can be used if you wish to sort strings without keeping
track of which string maps to which transformed version, by sorting the
transformed versions and untransforming them afterwards.

In list context, this subroutine returns a list of strings in standard
orthography in the same order as the input strings. In scalar context,
it returns the untransformed version of the first input string.

The result of applying C<strunxfrm> to a string that is not a valid,
defined output of C<strxfrm> is undefined.

=head1 SEE ALSO

L<strcoll(3)>, L<strxfrm(3)>

=head1 FEEDBACK

If you use this module, I'd appreciate it if you drop me a line at the
email address in L</AUTHOR>, just so that I have an idea of how many
people use this module at all. Also, if you have any comments, feel free
to email me.

=head1 AUTHOR

Philip Newton, E<lt>pne@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003, 2004 by Philip Newton.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

=over 4

=item *

Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer. 

=item *

Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution. 

=item *

Neither the name of Philip Newton nor the names of its contributors may
be used to endorse or promote products derived from this software
without specific prior written permission.

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
