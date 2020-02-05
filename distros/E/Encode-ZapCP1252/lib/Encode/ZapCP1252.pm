package Encode::ZapCP1252;

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT);
use 5.006_002;

$VERSION = '0.40';
@ISA     = qw(Exporter);
@EXPORT  = qw(zap_cp1252 fix_cp1252);
use constant PERL588 => $] >= 5.008_008;
use Encode ();

our %ascii_for = (
    # https://en.wikipedia.org/wiki/Windows-1252
    "\x80" => 'e',    # EURO SIGN
    "\x82" => ',',    # SINGLE LOW-9 QUOTATION MARK
    "\x83" => 'f',    # LATIN SMALL LETTER F WITH HOOK
    "\x84" => ',,',   # DOUBLE LOW-9 QUOTATION MARK
    "\x85" => '...',  # HORIZONTAL ELLIPSIS
    "\x86" => '+',    # DAGGER
    "\x87" => '++',   # DOUBLE DAGGER
    "\x88" => '^',    # MODIFIER LETTER CIRCUMFLEX ACCENT
    "\x89" => '%',    # PER MILLE SIGN
    "\x8a" => 'S',    # LATIN CAPITAL LETTER S WITH CARON
    "\x8b" => '<',    # SINGLE LEFT-POINTING ANGLE QUOTATION MARK
    "\x8c" => 'OE',   # LATIN CAPITAL LIGATURE OE
    "\x8e" => 'Z',    # LATIN CAPITAL LETTER Z WITH CARON
    "\x91" => "'",    # LEFT SINGLE QUOTATION MARK
    "\x92" => "'",    # RIGHT SINGLE QUOTATION MARK
    "\x93" => '"',    # LEFT DOUBLE QUOTATION MARK
    "\x94" => '"',    # RIGHT DOUBLE QUOTATION MARK
    "\x95" => '*',    # BULLET
    "\x96" => '-',    # EN DASH
    "\x97" => '--',   # EM DASH
    "\x98" => '~',    # SMALL TILDE
    "\x99" => '(tm)', # TRADE MARK SIGN
    "\x9a" => 's',    # LATIN SMALL LETTER S WITH CARON
    "\x9b" => '>',    # SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
    "\x9c" => 'oe',   # LATIN SMALL LIGATURE OE
    "\x9e" => 'z',    # LATIN SMALL LETTER Z WITH CARON
    "\x9f" => 'Y',    # LATIN CAPITAL LETTER Y WITH DIAERESIS
);

our %utf8_for = (
    # https://en.wikipedia.org/wiki/Windows-1252
    "\x80" => '€',    # EURO SIGN
    "\x82" => ',',    # SINGLE LOW-9 QUOTATION MARK
    "\x83" => 'ƒ',    # LATIN SMALL LETTER F WITH HOOK
    "\x84" => '„',    # DOUBLE LOW-9 QUOTATION MARK
    "\x85" => '…',    # HORIZONTAL ELLIPSIS
    "\x86" => '†',    # DAGGER
    "\x87" => '‡',    # DOUBLE DAGGER
    "\x88" => 'ˆ',    # MODIFIER LETTER CIRCUMFLEX ACCENT
    "\x89" => '‰',    # PER MILLE SIGN
    "\x8a" => 'Š',    # LATIN CAPITAL LETTER S WITH CARON
    "\x8b" => '‹',    # SINGLE LEFT-POINTING ANGLE QUOTATION MARK
    "\x8c" => 'Œ',    # LATIN CAPITAL LIGATURE OE
    "\x8e" => 'Ž',    # LATIN CAPITAL LETTER Z WITH CARON
    "\x91" => '‘',    # LEFT SINGLE QUOTATION MARK
    "\x92" => '’',    # RIGHT SINGLE QUOTATION MARK
    "\x93" => '“',    # LEFT DOUBLE QUOTATION MARK
    "\x94" => '”',    # RIGHT DOUBLE QUOTATION MARK
    "\x95" => '•',    # BULLET
    "\x96" => '–',    # EN DASH
    "\x97" => '—',    # EM DASH
    "\x98" => '˜',    # SMALL TILDE
    "\x99" => '™',    # TRADE MARK SIGN
    "\x9a" => 'š',    # LATIN SMALL LETTER S WITH CARON
    "\x9b" => '›',    # SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
    "\x9c" => 'œ',    # LATIN SMALL LIGATURE OE
    "\x9e" => 'ž',    # LATIN SMALL LETTER Z WITH CARON
    "\x9f" => 'Ÿ',    # LATIN CAPITAL LETTER Y WITH DIAERESIS
);

my @utf8_skip = (
# This translates a utf-8-encoded byte into how many bytes the full utf8
# character occupies.  Illegal start bytes have a negative count.

# UTF-8 is a variable-length encoding.  The 128 ASCII characters were very
# deliberately set to be themselves, so UTF-8 would be backwards compatible
# with 7-bit applications.  Every other character has 2 - 13 bytes comprising
# it.
#
# If the first bit of the first byte in a character is 0, it is one of those
# 128 ASCII characters with length 1.

# Otherwise, the first bit is 1, and if the second bit is also one, this byte
# starts the sequence of bytes that represent the character.  The bytes C0-FF
# have the characteristic that the first two bits are both one.  The number of
# bytes that form a character corresponds to the number of consecutive leading
# bits that are all one in the start byte.  In the case of FE, the first 7
# bits are one, so the number of bytes in the character it represents is 7.
# FF is a special case, and Perl has arbitrarily set it to 13 instead of the
# expected 8.
#
# The remaining bytes begin with '10', from 80..9F.  They are called
# continuation bytes, and a UTF-8 character is comprised of a start byte
# indicating 'n' bytes total in it, then 'n-1' of these continuation bytes.
# What the character is that each sequence represents is derived by shifting
# and adding the other bits in the bytes.  (C0 and C1 aren't actually legal
# start bytes for security reasons that need not concern us here, hence are
# marked as negative in the table below.)

  # 0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # 0
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # 1
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # 2
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # 3
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # 4
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # 5
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # 6
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # 7
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  # 8
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  # 9
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  # A
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  # B
   -1,-1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,  # C
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,  # D
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,  # E
    4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 7,13,  # F
);

BEGIN {
    my $proto = $] >= 5.010000 ? '_' : '$';
    eval "sub zap_cp1252($proto) { unshift \@_, \\%ascii_for; &_tweakit; }";
    eval "sub fix_cp1252($proto) { unshift \@_, \\%utf8_for;  &_tweakit; }";
}

# These are the bytes that CP1252 redefines
my $cp1252_re = qr/[\x80\x82-\x8c\x8e\x91-\x9c\x9e\x9f]/;

sub _tweakit {
    my $table = shift;
    return unless defined $_[0];
    local $_[0] = $_[0] if defined wantarray;
    my $is_utf8 = PERL588 && Encode::is_utf8($_[0]);
    my $valid_utf8 = $is_utf8 && utf8::valid($_[0]);
    if (!$is_utf8) {

        # Here is non-UTF-8. Change the 1252 characters to their UTF-8
        # counterparts. These bytes are very rarely used in real world
        # applications, so their presence likely indicates that CP1252 was
        # meant.
        $_[0] =~ s/($cp1252_re)/$table->{$1}/gems;
    } elsif ($valid_utf8) {

        # Here is well-formed Perl extended UTF-8 and has the UTF-8 flag on
        # and the string is held as bytes. Change the 1252 characters to their
        # Unicode counterparts.
        $_[0] =~ s/($cp1252_re)/Encode::decode_utf8($table->{$1})/gems;
    } else {    # Invalid UTF-8.  Look for single-byte CP1252 gremlins

        # Turn off the UTF-8 flag so that we can go through the string
        # byte-by-byte.
        Encode::_utf8_off($_[0]);

        my $i = 0;
        my $length = length $_[0];
        my $fixed = "";     # The input after being fixed up by this loop
        while ($i < $length) {

            # Each time through the loop, we should here be ready to look at a
            # new character, and it's 0th byte is called a 'start byte'
            my $start_byte = substr($_[0], $i, 1);
            my $skip = $utf8_skip[ord $start_byte];

            # The table is set up so that legal UTF-8 start bytes have a
            # positive byte length.  Simply add all the bytes in the character
            # to the output, and go on to handle the next character in the
            # next loop iteration.
            if ($skip > 0) {
                $fixed .= substr($_[0], $i, $skip);
                $i += $skip;
                next;
            }

            # Here we have a byte that isn't a start byte in a position that
            # should oughta be a start byte.  The whole point of this loop is
            # to find such bytes that are CP1252 ones and which were
            # incorrectly inserted by the upstream process into an otherwise
            # valid UTF-8 string.  So, if we have such a one, change it into
            # its corresponding correct character.
            if ($start_byte =~ s/($cp1252_re)/$table->{$1}/ems) {

                # The correct character may be UTF-8 bytes.  We treat them as
                # just a sequence of non-UTF-8 bytes, because that's what
                # $fixed has in it so far.  After everything is consistently
                # added, we turn the UTF-8 flag back on before returning at
                # the end.
                Encode::_utf8_off($start_byte);
                $fixed .= $start_byte;
                $i++;
                next;
            }

            # Here the byte isn't a CP1252 one.
            die "Unexpected continuation byte: %02x", ord $start_byte;
        }

        # $fixed now has everything properly in it, but set to return it in
        # $_[0], marked as UTF-8.
        $_[0] = $fixed;
        Encode::_utf8_on($_[0]);
    }
    return $_[0] if defined wantarray;
}

1;
__END__

##############################################################################

=head1 Name

Encode::ZapCP1252 - Zap Windows Western Gremlins

=head1 Synopsis

  use Encode::ZapCP1252;

  # Zap or fix in-place.
  zap_cp1252 $latin1_text;
  fix_cp1252 $utf8_text;

  # Zap or fix copy.
  my $clean_latin1 = zap_cp1252 $latin1_text;
  my $fixed_utf8   = fix_cp1252 $utf8_text;

=head1 Description

Have you ever been processing a Web form submit for feed, assuming that the
incoming text was encoded as specified in the Content-Type header, or in the
XML declaration, only to end up with a bunch of junk because someone pasted in
content from Microsoft Word? Well, this is because Microsoft uses a superset
of the Latin-1 encoding called "Windows Western" or "CP1252". If the specified
encoding is Latin-1, mostly things will come out right, but a few things--like
curly quotes, m-dashes, ellipses, and the like--may not. The differences are
well-known; you see a nice chart at documenting the differences on
L<Wikipedia|https://en.wikipedia.org/wiki/Windows-1252>.

Of course, that won't really help you. What will help you is to quit using
Latin-1 and switch to UTF-8. Then you can just convert from CP1252 to UTF-8
without losing a thing, just like this:

  use Encode;
  $text = decode 'cp1252', $text, 1;

But I know that there are those of you out there stuck with Latin-1 and who
don't want any junk characters from Word users. That's where this module comes
in. Its C<zap_cp1252> function will zap those CP1252 gremlins for you, turning
them into their appropriate ASCII approximations.

Another case that can occasionally come up is when you're reading reading in
text that I<claims> to be UTF-8, but it I<still> ends up with some CP1252
gremlins mixed in with properly encoded characters. I've seen examples of just
this sort of thing when processing GMail messages and attempting to insert
them into a UTF-8 database, as well as in some feeds processed by, say
Yahoo! Pipes. Doesn't work so well. For such cases, there's C<fix_cp1252>,
which converts those CP1252 gremlins into their UTF-8 equivalents.

=head1 Usage

This module exports two subroutines: C<zap_cp1252()> and C<fix_cp1252()>,
each of which accept a single argument:

  zap_cp1252 $text;
  fix_cp1252 $text;

When called in a void context, as in these examples, C<zap_cp1252()> and
C<fix_cp1252()> subroutine perform I<in place> conversions of any CP1252
gremlins into their appropriate ASCII approximations or UTF-8 equivalents,
respectively. Note that because the conversion happens in place, the data to
be converted I<cannot> be a string constant; it must be a scalar variable.

When called in a scalar or list context, on the other hand, a copy will be
modifed and returned. The original string will be unchanged:

  my $clean_latin1 = zap_cp1252 $latin1_text;
  my $fixed_utf8   = fix_cp1252 $utf8_text;

In this case, even constant values can be processed. Either way, C<undef>s
will be ignored.

In Perl 5.10 and higher, the functions may optionally be called with no
arguments, in which case C<$_> will be converted, instead:

  zap_cp1252; # Modify $_ in-place.
  fix_cp1252; # Modify $_ in-place.
  my $zapped = zap_cp1252; # Copy $_ and return zapped
  my $fixed = zap_cp1252; # Copy $_ and return fixed

In Perl 5.8.8 and higher, the conversion will work even when the string is
decoded to Perl's internal form (usually via C<decode 'ISO-8859-1', $text>) or
the string is encoded (and thus simply processed by Perl as a series of
bytes). The conversion will even work on a string that has not been decoded
but has had its C<utf8> flag flipped anyway (usually by an injudicious use of
C<Encode::_utf8_on()>. This is to enable the highest possible likelihood of
removing those CP1252 gremlins no matter what kind of processing has already
been executed on the string.

That said, although C<fix_cp1252()> takes a conservative approach to replacing
text in Unicode strings, it should be used as a very last option. Really,
avoid that situation if you can.

=head1 Conversion Table

Here's how the characters are converted to ASCII and UTF-8. The ASCII
conversions are not perfect, but they should be good enough for general
cleanup. If you want perfect, switch to UTF-8 and be done with it!

=encoding utf8

   Hex | Char  | ASCII | UTF-8 Name
  -----+-------+-------+-------------------------------------------
  0x80 |   €   |   e   | EURO SIGN
  0x82 |   ‚   |   ,   | SINGLE LOW-9 QUOTATION MARK
  0x83 |   ƒ   |   f   | LATIN SMALL LETTER F WITH HOOK
  0x84 |   „   |   ,,  | DOUBLE LOW-9 QUOTATION MARK
  0x85 |   …   |  ...  | HORIZONTAL ELLIPSIS
  0x86 |   †   |   +   | DAGGER
  0x87 |   ‡   |   ++  | DOUBLE DAGGER
  0x88 |   ˆ   |   ^   | MODIFIER LETTER CIRCUMFLEX ACCENT
  0x89 |   ‰   |   %   | PER MILLE SIGN
  0x8a |   Š   |   S   | LATIN CAPITAL LETTER S WITH CARON
  0x8b |   ‹   |   <   | SINGLE LEFT-POINTING ANGLE QUOTATION MARK
  0x8c |   Œ   |   OE  | LATIN CAPITAL LIGATURE OE
  0x8e |   Ž   |   Z   | LATIN CAPITAL LETTER Z WITH CARON
  0x91 |   ‘   |   '   | LEFT SINGLE QUOTATION MARK
  0x92 |   ’   |   '   | RIGHT SINGLE QUOTATION MARK
  0x93 |   “   |   "   | LEFT DOUBLE QUOTATION MARK
  0x94 |   ”   |   "   | RIGHT DOUBLE QUOTATION MARK
  0x95 |   •   |   *   | BULLET
  0x96 |   –   |   -   | EN DASH
  0x97 |   —   |   --  | EM DASH
  0x98 |   ˜   |   ~   | SMALL TILDE
  0x99 |   ™   |  (tm) | TRADE MARK SIGN
  0x9a |   š   |   s   | LATIN SMALL LETTER S WITH CARON
  0x9b |   ›   |   >   | SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
  0x9c |   œ   |   oe  | LATIN SMALL LIGATURE OE
  0x9e |   ž   |   z   | LATIN SMALL LETTER Z WITH CARON
  0x9f |   Ÿ   |   Y   | LATIN CAPITAL LETTER Y WITH DIAERESIS

=head2 Changing the Tables

Don't like these conversions? You can modify them to your heart's content by
accessing this module's internal conversion tables. For example, if you wanted
C<zap_cp1252()> to use an uppercase "E" for the euro sign, just do this:

  local $Encode::ZapCP1252::ascii_for{"\x80"} = 'E';

Or if, for some reason, you wanted the UTF-8 equivalent for a bullet
converted by C<fix_cp1252()> to be a black square, you can assign the
bytes (never a Unicode string) like so:

  local $Encode::ZapCP1252::utf8_for{"\x95"} = Encode::encode_utf8('■');

Just remember, without C<local> this would be a global change. In that case,
be careful if your code zaps CP1252 elsewhere. Of course, it shouldn't really
be doing that. These functions are just for cleaning up messes in one spot in
your code, not for making a fundamental part of your text handling. For that,
use L<Encode>.

=head1 See Also

=over

=item L<Encode>

=item L<Encoding::FixLatin>

=item L<Wikipedia: Windows-1252|https://en.wikipedia.org/wiki/Windows-1252>

=back

=head1 Support

This module is stored in an open L<GitHub
repository|https://github.com/theory/encode-zapcp1252/>. Feel free to fork
and contribute!

Please file bug reports via L<GitHub
Issues|https://github.com/theory/encode-zapcp1252/issues/> or by sending mail to
L<bug-Encode-CP1252@rt.cpan.org|mailto:bug-Encode-CP1252@rt.cpan.org>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Acknowledgments

My thanks to Sean Burke for sending me his original method for converting
CP1252 gremlins to more-or-less appropriate ASCII characters, and to Karl
Williamson for more correct handling of Unicode strings.

=head1 Copyright and License

Copyright (c) 2005-2020 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
