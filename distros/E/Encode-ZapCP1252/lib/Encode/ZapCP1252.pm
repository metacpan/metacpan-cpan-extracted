package Encode::ZapCP1252;

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT);
use 5.006_002;

$VERSION = '0.33';
@ISA     = qw(Exporter);
@EXPORT  = qw(zap_cp1252 fix_cp1252);
use constant PERL588 => $] >= 5.008_008;
require Encode if PERL588;

our %ascii_for = (
    # http://en.wikipedia.org/wiki/Windows-1252
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
    # http://en.wikipedia.org/wiki/Windows-1252
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

BEGIN {
    my $proto = $] >= 5.010000 ? '_' : '$';
    eval "sub zap_cp1252($proto) { unshift \@_, \\%ascii_for; &_tweakit; }";
    eval "sub fix_cp1252($proto) { unshift \@_, \\%utf8_for;  &_tweakit; }";
}

sub _tweakit {
    my $table = shift;
    return unless defined $_[0];
    local $_[0] = $_[0] if defined wantarray;
    if (PERL588 && Encode::is_utf8($_[0])) {
        _tweak_decoded($table, $_[0]);
    } else {
        $_[0] =~ s{([\x80-\x9f])}{$table->{$1} || $1}emxsg;
    }
    return $_[0] if defined wantarray;
}

sub _tweak_decoded {
    my $table = shift;
    local $@;
    # First, try to replace in the decoded string.
    eval {
        $_[0] =~ s{([\x80-\x9f])}{
            $table->{$1} ? Encode::decode('UTF-8', $table->{$1}) : $1
        }emxsg
    };
    if (my $err = $@) {
        # If we got a "Malformed UTF-8 character" error, then someone
        # likely turned on the utf8 flag without decoding. So turn it off.
        # and try again.
        die if $err !~ /Malformed/;
        Encode::_utf8_off($_[0]);
        $_[0] =~ s/([\x80-\x9f])/$table->{$1} || $1/emxsg;
        Encode::_utf8_on($_[0]);
    }
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
L<Wikipedia|http://en.wikipedia.org/wiki/Windows-1252>.

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
L<Yahoo! Pipes|http://pipes.yahoo.com>. Doesn't work so well. For such cases,
there's C<fix_cp1252>, which converts those CP1252 gremlins into their UTF-8
equivalents.

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

In Perl 5.8.8 and higher, the conversion will work even when the string is
decoded to Perl's internal form (usually via C<decode 'ISO-8859-1', $text>) or
the string is encoded (and thus simply processed by Perl as a series of
bytes). The conversion will even work on a string that has not been decoded
but has had its C<utf8> flag flipped anyway (usually by an injudicious use of
C<Encode::_utf8_on()>. This is to enable the highest possible likelihood of
removing those CP1252 gremlins no matter what kind of processing has already
been executed on the string.

In Perl 5.10 and higher, the functions may optionally be called with no
arguments, in which case C<$_> will be converted, instead:

  zap_cp1252; # Modify $_ in-place.
  fix_cp1252; # Modify $_ in-place.
  my $zapped = zap_cp1252; # Copy $_ and return zapped
  my $fixed = zap_cp1252; # Copy $_ and return fixed

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

Or if, for some bizarre reason, you wanted the UTF-8 equivalent for a bullet
converted by C<fix_cp1252()> to really be an asterisk (why would you? Just use
C<zap_cp1252> for that!), you can do this:

  local $Encode::ZapCP1252::utf8_for{"\x95"} = '*';

Just remember, without C<local> this would be a global change. In that case,
be careful if your code zaps CP1252 elsewhere. Of course, it shouldn't really
be doing that. These functions are just for cleaning up messes in one spot in
your code, not for making a fundamental part of your text handling. For that,
use L<Encode>.

=head1 See Also

=over

=item L<Encode>

=item L<Wikipedia: Windows-1252|http://en.wikipedia.org/wiki/Windows-1252>

=back

=head1 Support

This module is stored in an open L<GitHub
repository|http://github.com/theory/encode-cp1252/tree/>. Feel free to fork
and contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/encode-cp1252/issues/> or by sending mail to
L<bug-Encode-CP1252@rt.cpan.org|mailto:bug-Encode-CP1252@rt.cpan.org>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Acknowledgments

My thanks to Sean Burke for sending me his original method for converting
CP1252 gremlins to more-or-less appropriate ASCII characters.

=head1 Copyright and License

Copyright (c) 2005-2010 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
