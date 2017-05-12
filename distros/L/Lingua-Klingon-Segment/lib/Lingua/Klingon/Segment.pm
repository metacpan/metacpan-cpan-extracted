package Lingua::Klingon::Segment;
# vim:set tw=72 sw=2:

use 5.005;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $keep_accents);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::Klingon::Segment ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
    syllabify
    spell
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);
$VERSION = '1.03';

my $letter = qr/tlh|ch|gh|ng(?!h)|[abDeHIjlmnopqQrStuvwy']/;
my $consonant = qr/tlh|ch|gh|ng(?!h)|[bDHjlmnpqQrStvwy']/;
my $vowel = qr/[aeIou]/;
my $head = $consonant;
my $tail = qr/rgh|w'|y'|$consonant/o;


sub syllabify {
  my @syllables;
  foreach my $word ($_[0] =~ /($letter+)/go) {
    push @syllables, $word =~ /\G($head$vowel$tail?)(?=(?:$head$vowel$tail?)*$)/goc;
  }
  @syllables;
}


sub spell {
  my @letters;
  @letters = $_[0] =~ /($letter)/go;
  @letters;
}


1;
__END__

=head1 NAME

Lingua::Klingon::Segment - Segment Klingon words into syllables and letters

=head1 VERSION

This document refers to version 1.03 of Lingua::Klingon::Segment, released
on 2004-05-17.

=head1 SYNOPSIS

  use Lingua::Klingon::Segment;

  my @syllables = Lingua::Klingon::Segment::syllabify('monghom');
  # @syllables = qw(mon ghom)

  my @letters = Lingua::Klingon::Segment::spell('monghom');
  # @letters = qw(m o n gh o m)

or

  use Lingua::Klingon::Segment ':all';

  my @syllables = syllabify('mongHom');
  # @syllables = qw(mong Hom)

  my @letters = spell('mongHom');
  # @letters = qw(m o ng H o m)

or

  use Lingua::Klingon::Segment qw( syllabify );

  my @syllables = syllabify('vavoy');
  # @syllables = qw(va voy)

=head1 DESCRIPTION

=head2 Overview

Lingua::Klingon::Segment is a module which allows you to decompose
Klingon words into syllables and letters.

=head2 Exports

Lingua::Klingon::Segment exports no functions by default, in order to
avoid namespace pollution. However, all functions listed here can be
imported explicitly by naming them, or they can be imported all together
by using the tag ':all'.

=head2 syllabify

This subroutine splits a given word or phrase into syllables. It returns
the list of syllables that make up that word or phrase.

If the input is a multi-word phrase, the output is the list of all
syllables in that phrase, regardless of which word they came from (for
example, the output of "syllabify 'jISop vIneH'" is qw(jI Sop vI neH).

In scalar context, returns the number of syllables in the input.

=head2 spell

This subroutine splits a given word or phrase into letters. It returns
the list of letters that make up that word or phrase (counting all
Klingon letters as one, including 'ch', 'gh', 'ng', and 'tlh').

If the input is a multi-word phrase, the output is the list of all
Klingon letters in that phrase. Non-letters such as spaces or
punctuation are not included.

If the input includes words which are not Klingon words, the output is
undefined.

In scalar context, returns the number of Klingon letters in the input.

=head1 BUGS

None currently known. If you find any, please email me.

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
