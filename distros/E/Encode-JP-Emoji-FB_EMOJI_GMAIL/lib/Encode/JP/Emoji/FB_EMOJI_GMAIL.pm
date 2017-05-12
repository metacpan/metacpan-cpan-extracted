=encoding utf-8

=head1 NAME

Encode::JP::Emoji::FB_EMOJI_GMAIL - Emoji fallback functions with Gmail

=head1 SYNOPSIS

    use Encode;
    use Encode::JP::Emoji;
    use Encode::JP::Emoji::FB_EMOJI_GMAIL;

    # DoCoMo Shift_JIS <SJIS+F89F> octets
    # <img src="http://mail.google.com/mail/e/docomo_ne_jp/000" alt="[晴れ]" class="e" />
    my $sun = "\xF8\x9F";
    Encode::from_to($sun, 'x-sjis-emoji-docomo', 'x-sjis-emoji-none', FB_EMOJI_GMAIL());

    # KDDI(web) Shift_JIS <SJIS+F665> octets
    # <img src="http://mail.google.com/mail/e/ezweb_ne_jp/001" alt="[曇り]" class="e" />
    my $cloud = "\xF6\x65";
    Encode::from_to($cloud, 'x-sjis-emoji-kddiweb', 'x-sjis-emoji-none', FB_EMOJI_GMAIL());

    # SoftBank UTF-8 <U+E524> string
    # <img src="http://mail.google.com/mail/e/softbank_ne_jp/1CA" alt="[ハムスター]" class="e" />
    my $hamster = "\x{E524}";
    $hamster = Encode::encode('x-sjis-e4u-none', $hamster, FB_EMOJI_GMAIL());

    # Google UTF-8 <U+FE1C1> octets
    # <img src="http://mail.google.com/mail/e/1C1" alt="[クマ]" class="e" />
    my $bear = "\xF3\xBE\x87\x81";
    $bear = Encode::decode('x-utf8-e4u-none', $bear, FB_EMOJI_GMAIL());

=head1 DESCRIPTION

This module exports the following fallback function.
Use this with C<x-sjis-e4u-none> and C<x-utf8-e4u-none> encodings
which rejects any emojis.
Note that this is B<NOT> an official service powered by Gmail.

=head2 FB_EMOJI_GMAIL()

This returns C<img> element for PC to display emoji images.
Having conflicts with SoftBank encoding, KDDI(app) encoding is B<NOT> recommended.

=head2 FB_EMOJI_GMAIL()

=head1 LINKS

=over 4

=item * Subversion Trunk

L<http://emoji4unicode-ll.googlecode.com/svn/trunk/lang/perl/Encode-JP-Emoji-FB_EMOJI_GMAIL/trunk/>

=item * Project Hosting on Google Code

L<http://code.google.com/p/emoji4unicode-ll/>

=item * Google Groups and some Japanese documents

L<http://groups.google.com/group/emoji4unicode-ll>

=item * RT: CPAN request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Encode-JP-Emoji-FB_EMOJI_GMAIL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Encode-JP-Emoji-FB_EMOJI_GMAIL>

=item * Search CPAN

L<http://search.cpan.org/dist/Encode-JP-Emoji-FB_EMOJI_GMAIL/>

=back

=head1 BUGS

C<Encode.pm> 2.22 and less would face a problem on fallback function.
Use latest version of C<Encode.pm>, or use with C<EncodeUpdate.pm>
in C<t> test directory of the package.

=head1 AUTHOR

Yusuke Kawasaki, L<http://www.kawa.net/>

=head1 SEE ALSO

L<Encode::JP::Emoji>

=head1 COPYRIGHT

Copyright 2009 Yusuke Kawasaki, all rights reserved.

=cut

package Encode::JP::Emoji::FB_EMOJI_GMAIL;
use strict;
use warnings;
use base 'Exporter';
use Encode ();
use Encode::JP::Emoji;
use Encode::JP::Emoji::Property;
use Encode::JP::Emoji::FB_EMOJI_TEXT;

our $VERSION = '0.05';

our @EXPORT = qw(
    FB_EMOJI_GMAIL
);

our $DOCOMO_FORMAT   = '<img src="http://mail.google.com/mail/e/docomo_ne_jp/%03X" alt="%s" class="e" />';
our $KDDI_FORMAT     = '<img src="http://mail.google.com/mail/e/ezweb_ne_jp/%03X" alt="%s" class="e" />';
our $SOFTBANK_FORMAT = '<img src="http://mail.google.com/mail/e/softbank_ne_jp/%03X" alt="%s" class="e" />';
our $GOOGLE_FORMAT   = '<img src="http://mail.google.com/mail/e/%03X" alt="%s" class="e" />';

my $ascii  = Encode::find_encoding('us-ascii');
my $utf8   = Encode::find_encoding('utf8');
my $mixed  = Encode::find_encoding('x-utf8-e4u-mixed');
my $none   = Encode::find_encoding('x-utf8-e4u-none');
my $fbtext = FB_EMOJI_TEXT();

sub FB_EMOJI_GMAIL {
    my $fb = shift || $fbtext;
    sub {
        my $code   = shift;
        my $chr    = chr $code;
        my $format = $GOOGLE_FORMAT;
        my $gcode;
        if ($chr =~ /\p{InEmojiGoogle}/) {
            # google emoji
            $gcode = $code;
        } elsif ($chr =~ /\p{InEmojiAny}/) {
            # others emoji
            if ($chr =~ /\p{InEmojiDoCoMo}/) {
                $format = $DOCOMO_FORMAT;
            } elsif ($chr =~ /\p{InEmojiSoftBank}/) {
                $format = $SOFTBANK_FORMAT;
            } elsif ($chr =~ /\p{InEmojiKDDIweb}/) {
                $format = $KDDI_FORMAT;
            } elsif ($chr =~ /\p{InEmojiKDDIapp}/) {
                $format = $KDDI_FORMAT;
            }
            my $moct = $utf8->encode(chr $code, $fb);   # Mixed UTF-8 octets
            my $gstr = $mixed->decode($moct, $fb);      # Google UTF-8 string
            $gcode = ord $gstr if (1 == length $gstr);
        }
        unless (defined $gcode) {
            my $aoct = $ascii->encode(chr $code, $fb);  # force fallback
            return $utf8->decode($aoct, $fb);           # UTF-8 string
        }
        my $num = $gcode & 0x0FFF;
        my $name = $none->encode(chr $code, $fbtext);   # emoji name
        $name = $utf8->decode($name, $fb);              # UTF-8 string
        sprintf $format => $num, $name;
    };
}

# Ｔｈｉｓ　ｆｉｌｅ　ｗａｓ　ｗｒｉｔｔｅｎ　ｉｎ　ＵＴＦ－８

1;
