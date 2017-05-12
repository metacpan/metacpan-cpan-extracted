package Lingua::Klingon::Recode;
# vim:set tw=72 sw=2 cin cink-=0#:

use 5.005;
use strict;
use Carp;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::Klingon::Recode ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
    recode
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);
$VERSION = '1.02';

# convert from encoding FOO to uhmal gnj
my %from = (
    'tlhIngan' => {
      'a' => 'a',
      'b' => 'b',
      'ch' => 'c',
      'D' => 'd',
      'e' => 'e',
      'gh' => 'f',
      'H' => 'g',
      'I' => 'h',
      'j' => 'i',
      'l' => 'j',
      'm' => 'k',
      'n' => 'l',
      'ng' => 'm',
      'o' => 'n',
      'p' => 'o',
      'q' => 'p',
      'Q' => 'q',
      'r' => 'r',
      'S' => 's',
      't' => 't',
      'tlh' => 'u',
      'u' => 'v',
      'v' => 'w',
      'w' => 'x',
      'y' => 'y',
      "'" => 'z',
    },
    'tlhingan' => {
      'a' => 'a',
      'b' => 'b',
      'ch' => 'c',
      'd' => 'd',
      'e' => 'e',
      'gh' => 'f',
      'h' => 'g',
      'i' => 'h',
      'j' => 'i',
      'l' => 'j',
      'm' => 'k',
      'n' => 'l',
      'ng' => 'm',
      'o' => 'n',
      'p' => 'o',
      'q' => 'p',
      # 'q' => 'q', # this gets lost :(
      'r' => 'r',
      's' => 's',
      't' => 't',
      'tlh' => 'u',
      'u' => 'v',
      'v' => 'w',
      'w' => 'x',
      'y' => 'y',
      "'" => 'z',
    },
    'XIFAN' => {
      'A' => 'a',
      'B' => 'b',
      'C' => 'c',
      'D' => 'd',
      'E' => 'e',
      'G' => 'f',
      'H' => 'g',
      'I' => 'h',
      'J' => 'i',
      'L' => 'j',
      'M' => 'k',
      'N' => 'l',
      'F' => 'm',
      'O' => 'n',
      'P' => 'o',
      'K' => 'p',
      'Q' => 'q',
      'R' => 'r',
      'S' => 's',
      'T' => 't',
      'X' => 'u',
      'U' => 'v',
      'V' => 'w',
      'W' => 'x',
      'Y' => 'y',
      'Z' => 'z',
      "'" => 'z',
    },
);

# the same mapping serves both
$from{'XIFANZ'} = $from{'XIFAN'};

# convert from uhmal gnj to encoding FOO
my %to;
$to{'tlhIngan'} = { reverse %{$from{'tlhIngan'}} };
$to{'tlhingan'} = { reverse %{$from{'tlhingan'}} };
$to{'tlhingan'}{'q'} = 'q'; # map both 'Q' and 'q' to 'q'

$to{'XIFAN'} = { reverse %{$from{'XIFAN'}} };
$to{'XIFAN'}{'z'} = "'";

$to{'XIFANZ'} = { reverse %{$from{'XIFAN'}} };
$to{'XIFANZ'}{'z'} = 'Z';

# map names to internal form
my %internal = (
    'tlhIngan' => 'tlhIngan',
    'tlhIngan Hol' => 'tlhIngan',
    "tlhIngan Hol Dajalh'a'" => 'tlhIngan',

    'tlhingan' => 'tlhingan',
    'tlhingan hol' => 'tlhingan',
    "tlhingan hol dajatlh'a'" => 'tlhingan',

    'TLHINGAN' => 'TLHINGAN',
    'TLHINGAN HOL' => 'TLHINGAN',
    "TLHINGAN HOL DAJATLH'A'" => 'TLHINGAN',

    'xifan' => 'xifan',
    'xifan hol' => 'xifan',
    "xifan hol dajax'a'" => 'xifan',

    'xifan hol dajaxzaz' => 'xifanz',
    'xifanz' => 'xifanz',

    'XIFAN' => 'XIFAN',
    'XIFAN HOL' => 'XIFAN',
    "XIFAN HOL DAJAX'A'" => 'XIFAN',

    'XIFAN HOL DAJAXZAZ' => 'XIFANZ',
    'XIFANZ' => 'XIFANZ',

    'uhmal' => 'uhmal',
    'uhmal gnj' => 'uhmal',
    'uhmal gnj daiauzaz' => 'uhmal',

    'UHMAL' => 'UHMAL',
    'UHMAL GNJ' => 'UHMAL',
    'UHMAL GNJ DAIAUZAZ' => 'UHMAL',
);

# regular expression that defines a letter
my %letter = (
    'uhmal' => qr/[a-z]/,
    # "ng(?!h)" since the sequence "ngh" must be n+gh
    'tlhIngan' => qr/tlh|[cg]h|ng(?!h)|[abDeHIjlmnopqQrStuvwy']/,
    # Can't do that here, unfortunately, since "ngh" could be either
    # n+gh or ng+H = ng+h. The disadvantage of case-smashing.
    'tlhingan' => qr/tlh|[cg]h|ng|[abdehijlmnopqrstuvwy']/,
    'XIFAN' => qr/[A-Y']/,
    'XIFANZ' => qr/[A-Z]/,
);

# based on
my %base = (
    'uhmal' => 'uhmal',
    'UHMAL' => 'uhmal',
    'tlhIngan' => 'tlhIngan',
    'tlhingan' => 'tlhingan',
    'TLHINGAN' => 'tlhingan',
    'xifan' => 'XIFAN',
    'xifanz' => 'XIFANZ',
    'XIFAN' => 'XIFAN',
    'XIFANZ' => 'XIFANZ',
);


# The subroutine itself

sub recode {
  my $from = shift;
  my $to   = shift;
  my @input;
  my @result;

  if (not exists $internal{$from}) {
    croak "Can't recognise 'from' encoding '$from'";
  } elsif (not exists $internal{$to}) {
    croak "Can't recognise 'to' encoding '$to'";
  } else {
    $from = $internal{$from};
    $to = $internal{$to};

    if($to eq $from) {
      return +(wantarray ? @_ : $_[0]);
    } elsif($to eq lc $from) {
      return +(wantarray ? map lc, @_ : lc $_[0]);
    } elsif($to eq uc $from) {
      return +(wantarray ? map uc, @_ : uc $_[0]);
    } else {
      # transform from initial encoding to uhmal
      if($from eq 'UHMAL') {
        @input = map lc, @_;
      } elsif($from eq 'uhmal') {
        @input = @_;
      } else {
        @input = @_;
        for(@input) {
          $_ = lc $_ if $base{$from} eq lc $from;
          $_ = uc $_ if $base{$from} eq uc $from;
	  # Can't use /o since $base{$from} will change
          s/($letter{$base{$from}})/$from{$base{$from}}{$1}/g;
        }
      }

      # transform from uhmal to final encoding
      if($to eq 'UHMAL') {
        @result = map uc, @input;
      } elsif($to eq 'uhmal') {
        @result = @input;
      } else {
        @result = @input;
        for(@result) {
          s/($letter{'uhmal'})/$to{$base{$to}}{$1}/go;
          $_ = lc $_ if $to eq lc $base{$to};
          $_ = uc $_ if $to eq uc $base{$to};
        }
      }
    }
  }

  return +(wantarray ? @result : $result[0]);
}


1;
__END__

=head1 NAME

Lingua::Klingon::Recode - Convert Klingon words between different encodings

=head1 VERSION

This document refers to version 1.02 of Lingua::Klingon::Recode,
released on 2004-05-09.

=head1 SYNOPSIS

  use Lingua::Klingon::Recode;
  @copy = Lingua::Klingon::Recode::recode('XIFAN HOL',    # from
                                          'tlhIngan Hol', # to
                                          @original);

or

  use Lingua::Klingon::Recode ':all';
  @copy = recode 'XIFAN HOL', 'tlhIngan Hol', @original;

or

  # demonstrate scalar version for a change
  use Lingua::Klingon::Recode qw( recode );
  $copy = recode 'XIFAN HOL', 'tlhIngan Hol', $original;


=head1 DESCRIPTION

=head2 Overview

Lingua::Klingon::Recode is a module which allows you to convert Klingon
text from one encoding to another.

For example, one frequently-used encoding is the so-called 'XIFAN HOL'
encoding (after the encoded version of what is 'tlhIngan Hol' in the
standard encoding).

All suported encodings can represent the same sounds, but they use
different characters or sequences of characters to do so.

Most encodings have three allowable names (or aliasses): the
transliteration of 'tlhIngan Hol', an abbreviated version with only
'tlhIngan', and an extended version "tlhIngan Hol Dajatlh'a'" (this
extended version is mainly used to distinguish between related encodings
that differ in how they represent the apostrophe).

The support encodings, with their recognised aliasses, are:

=over 4

=item tlhIngan Hol, tlhIngan, tlhIngan Hol Dajatlh'a'

The standard encoding for Klingon; this is the usual transliteration.

=item tlhingan hol, tlhingan, tlhingan hol dajatlh'a'

This is the same as the standard encoding, except that all letters are
lowercase. This has the grave disadvantage that 'q' and 'Q' are
conflated, and that "ngh" can represent either "ng+H" or "n+gh" (it is
interpreted as the former).

=item TLHINGAN HOL, TLHINGAN, TLHINGAN HOL DAJATLH'a'

This is the same as the standard encoding, except that all letters are
uppercase. Again, 'q' and 'Q' cannot be distinguished in this encoding,
and the sequence "NGH" is ambiguous.

=item XIFAN HOL, XIFAN, XIFAN HOL DAJAX'A'

This is the so-called "XIFAN HOL" encoding, used, for example, as the
encoding of some fonts.

=item XIFANZ, XIFAN HOL DAJAXZAZ

This is the same encoding as the one above, but it uses Z for what is
written ' (apostrophe) in the standard encoding, rather than the
apostrophe. This encoding uses only the 26 letters of the uppercase
Roman alphabet.

This encoding must be specified in its full form, or in the abbreviation
'XIFANZ'.

=item xifan hol, xifan, xifan hol dajax'a'

This is the "XIFAN HOL" encoding with all letters replaced by their
lowercase form.

=item xifanz, xifan hol dajaxzaz

This is the "XIFAN HOL" encoding with all letters replaced by their
lowercase form, and with 'z' rather than "'" for the apostrophe. This
encoding uses only the 26 letters of the lowercase Roman alphabet.

=item uhmal gnj, uhmal, uhmal daiauzaz

This is an encoding formed by representing each Klingon letter in the
standard transliteration with a lower-case Roman letter in alphabetical
order according to the standard transliteration. It is also the encoding
currently used by L<Lingua::Klingon::Collate>. It can be represented as
followed:

    tlhIngan Hol  a   b   ch  D   e   gh  H   I   j   l   m   n   ng
    uhmal gnj     a   b   c   d   e   f   g   h   i   j   k   l   m

    tlhIngan Hol  o   p   q   Q   r   S   t   tlh u   v   w   y   '
    uhmal gnj     n   o   p   q   r   s   t   u   v   w   x   y   z

=item UHMAL GNJ, UHMAL, UHMAL GNJ DAIAUZAZ

This is the uppercase version of the 'uhmal gnj' encoding.

=back

=head2 Exports

Lingua::Klingon::Recode exports no functions by default, in order to
avoid namespace pollution. However, all functions listed here can be
imported explicitly by naming them, or they can be imported all together
by using the tag ':all'.

=head2 recode

This is currently the only subroutine in this module.

It takes at least three parameters:

=over 4

=item *

"from" encoding

=item *

"to" encoding

=item *

one or more strings

=back

The strings are converted from the "from" encoding to the "to" encoding.

In list context, returns all the converted strings. In scalar context,
returns the first converted string.

=head1 BUGS

The 'tlhingan hol' and 'TLHINGAN HOL' encodings lose information; this
is inherent in their definition. Do not use these encodings unless you
really need to.

No bugs in the code itself are currently known.

Please report any bugs found through http://rt.cpan.org/ or by emailing
the author.

=head1 SEE ALSO

L<Lingua::Klingon::Collate>

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
