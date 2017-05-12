=encoding utf-8

=head1 NAME

Encode::JP::Emoji::FB_EMOJI_TEXT - Emoji fallback functions

=head1 SYNOPSIS

    use Encode;
    use Encode::JP::Emoji;
    use Encode::JP::Emoji::FB_EMOJI_TEXT;

    # DoCoMo Shift_JIS <SJIS+F95B> octets fallback to "[SOON]"
    my $soon = "\xF9\x5B";
    Encode::from_to($soon, 'x-sjis-e4u-docomo', 'x-sjis-e4u-kddiweb', FB_EMOJI_TEXT());

    # KDDI Shift_JIS <SJIS+F7B5> octets fallback to "[霧]"
    my $fog = "\xF7\xB5";
    Encode::from_to($fog, 'x-sjis-e4u-kddiweb', 'x-sjis-e4u-softbank3g', FB_EMOJI_TEXT());

    # SoftBank UTF-8 <U+E524> string fallback to "[ハムスター]"
    my $hamster = "\x{E524}";
    my $softbank = Encode::encode('x-sjis-e4u-none', $hamster, FB_EMOJI_TEXT());

    # Google UTF-8 <U+FE1C1> octets fallback to "[クマ]"
    my $bear = "\xF3\xBE\x87\x81";
    my $google = Encode::decode('x-utf8-e4u-none', $bear, FB_EMOJI_TEXT());

=head1 DESCRIPTION

This module exports the following fallback function.

=head2 FB_EMOJI_TEXT()

This returns emoji character name.
Having conflicts with SoftBank encoding, KDDI(app) encoding is B<NOT> recommended.

=head1 BUGS

C<Encode.pm> 2.22 or less would face a problem with fallback function.
Use latest version of C<Encode.pm>, or use with C<EncodeUpdate.pm>
in C<t> test directory of the package.

=head1 AUTHOR

Yusuke Kawasaki, L<http://www.kawa.net/>

=head1 SEE ALSO

L<Encode::JP::Emoji>

=head1 COPYRIGHT

Copyright 2009-2010 Yusuke Kawasaki, all rights reserved.

=cut

package Encode::JP::Emoji::FB_EMOJI_TEXT;
use strict;
use warnings;
use base 'Exporter';
use Encode ();
use Encode::JP::Emoji::Mapping;
use Encode::JP::Emoji::Property;

our $VERSION = '0.60';

our @EXPORT = qw(
    FB_EMOJI_TEXT
);

our $TEXT_FORMAT = '[%s]';

my $ascii  = Encode::find_encoding('us-ascii');
my $utf8   = Encode::find_encoding('utf8');
my $stand  = Encode::find_encoding('x-utf8-e4u-unicode');
my $mixed  = Encode::find_encoding('x-utf8-e4u-mixed');
my $check  = Encode::FB_XMLCREF();

sub FB_EMOJI_TEXT {
    my $fb = shift || $check;
    sub {
        my $code = shift;
        my $chr  = chr $code;
        my $gcode;
        if ($chr =~ /\p{InEmojiGoogle}/) {
            # google emoji
            $gcode = $code;
        } elsif ($chr =~ /\p{InEmojiUnicode}/) {
            # unicode emoji
            my $moct = $utf8->encode(chr $code, $fb);   # Mixed UTF-8 octets
            my $gstr = $stand->decode($moct, $fb);      # Standard UTF-8 string
            $gcode = ord $gstr if (1 == length $gstr);
        } elsif ($chr =~ /\p{InEmojiMixed}/) {
            # others emoji
            my $moct = $utf8->encode(chr $code, $fb);   # Mixed UTF-8 octets
            my $gstr = $mixed->decode($moct, $fb);      # Google UTF-8 string
            $gcode = ord $gstr if (1 == length $gstr);
        }
        my $hex = sprintf '%04X' => $gcode;
        unless (exists $Encode::JP::Emoji::Mapping::CharnamesEmojiGoogle{$hex}) {
            my $aoct = $ascii->encode(chr $code, $fb);  # force fallback
            return $utf8->decode($aoct, $fb);           # UTF-8 string
        }
        my $name = $Encode::JP::Emoji::Mapping::CharnamesEmojiGoogle{$hex};
        sprintf $TEXT_FORMAT => $name;
    };
}

# Ｔｈｉｓ　ｆｉｌｅ　ｗａｓ　ｗｒｉｔｔｅｎ　ｉｎ　ＵＴＦ－８

1;
