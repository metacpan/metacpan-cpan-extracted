=encoding utf-8

=head1 NAME

Encode::JP::Emoji::FB_EMOJI_TYPECAST - Emoji fallback for TypeCast emoji images

=head1 SYNOPSIS

    use Encode;
    use Encode::JP::Emoji;
    use Encode::JP::Emoji::FB_EMOJI_TYPECAST;

    my $image_base = 'http://example.com/images/emoticons/';
    $Encode::JP::Emoji::FB_EMOJI_TYPECAST::IMAGE_BASE = $image_base;

    # DoCoMo Shift_JIS <SJIS+F89F> octets
    # <img src="http://example.com/images/emoticons/sun.gif" alt="[晴れ]" class="e" />
    my $sun = "\xF8\x9F";
    Encode::from_to($sun, 'x-sjis-emoji-docomo', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());

    # KDDI(web) Shift_JIS <SJIS+F3A5> octets
    # <img src="http://example.com/images/emoticons/kissmark.gif" alt="[口]" class="e" />
    my $mouse = "\xF3\xA5";
    Encode::from_to($mouse, 'x-sjis-emoji-kddiweb', 'x-sjis-emoji-none', FB_EMOJI_TYPECAST());

    # SoftBank UTF-8 <U+E20C> string
    # <img src="http://example.com/images/emoticons/heart.gif" alt="[ハート]" class="e" />
    my $heart = "\x{E20C}";
    $heart = Encode::encode('x-sjis-e4u-none', $heart, FB_EMOJI_TYPECAST());

    # Google UTF-8 <U+FE983> octets
    # <img src="http://example.com/images/emoticons/beer.gif" alt="[ビール]" class="e" />
    my $beer = "\xF3\xBE\xA6\x83";
    $beer = Encode::decode('x-utf8-e4u-none', $beer, FB_EMOJI_TYPECAST());

=head1 DESCRIPTION

This module exports the following fallback function.
Use this with C<x-sjis-e4u-none> and C<x-utf8-e4u-none> encodings
which rejects any emojis.

=head2 FB_EMOJI_TYPECAST()

This function returns an C<img> element for PC to display emoji images.
Having conflicts with SoftBank encoding, KDDI(app) encoding is B<NOT> recommended.

=head2 $Encode::JP::Emoji::FB_EMOJI_TYPECAST::IMAGE_BASE

This variable sets base URL to TypeCast emoji files.
Download their C<emoticons.zip> archive package from
L<http://start.typepad.jp/typecast/>.

Image files on Google Code Project Hosting,
L<http://typecastmobile.googlecode.com/svn/trunk/static/images/emoticons/>,
is directly used by default.

TypeCast Emoji Icon Images by Six Apart Ltd is licensed
under a Creative Commons Attribution 2.1 Japan License.
Permissions beyond the scope of this license may be available at
L<http://start.typepad.jp/typecast/>.

=head1 LINKS

=over 4

=item * Subversion Trunk

L<http://emoji4unicode-ll.googlecode.com/svn/trunk/lang/perl/Encode-JP-Emoji-FB_EMOJI_TYPECAST/trunk/>

=item * Project Hosting on Google Code

L<http://code.google.com/p/emoji4unicode-ll/>

=item * Google Groups and some Japanese documents

L<http://groups.google.com/group/emoji4unicode-ll>

=item * RT: CPAN request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Encode-JP-Emoji-FB_EMOJI_TYPECAST>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Encode-JP-Emoji-FB_EMOJI_TYPECAST>

=item * Search CPAN

L<http://search.cpan.org/dist/Encode-JP-Emoji-FB_EMOJI_TYPECAST/>

=back

=head1 AUTHOR

Yusuke Kawasaki, L<http://www.kawa.net/>

=head1 SEE ALSO

L<Encode::JP::Emoji>

=head1 COPYRIGHT

Copyright 2009 Yusuke Kawasaki, all rights reserved.

=cut

package Encode::JP::Emoji::FB_EMOJI_TYPECAST;
use strict;
use warnings;
use base 'Exporter';
use Carp;
use Encode ();
use Encode::JP::Emoji;
use Encode::JP::Emoji::Property;
use Encode::JP::Emoji::FB_EMOJI_TEXT;

our $VERSION = '0.05';

our @EXPORT = qw(
    FB_EMOJI_TYPECAST
);

sub loaded_path {
    my $path = $INC{join('/'=>split('::'=>__PACKAGE__)).'.pm'};
    $path =~ s#[^\/\:\\]+$##;
    $path;
}

our $IMAGE_BASE  = 'http://typecastmobile.googlecode.com/svn/trunk/static/images/emoticons/';
our $HTML_FORMAT = '<img src="%s%s.gif" alt="%s" class="e" />';

my $DATA_FILE = 'Encode/JP/Emoji/FB_EMOJI_TYPECAST/Emoticon.pl';
my $DATA_CACHE;
sub data {
    return $DATA_CACHE if ref $DATA_CACHE;
    $DATA_CACHE = do $DATA_FILE;
}

my $ascii  = Encode::find_encoding('us-ascii');
my $utf8   = Encode::find_encoding('utf8');
my $docomo = Encode::find_encoding('x-utf8-e4u-docomo');
my $mixed  = Encode::find_encoding('x-utf8-e4u-mixed');
my $none   = Encode::find_encoding('x-utf8-e4u-none');
my $fbtext = FB_EMOJI_TEXT();

sub FB_EMOJI_TYPECAST {
    my $fb = shift || $fbtext;
    sub {
        my $code  = shift;
        my $chr   = chr $code;                          # Native UTF-8 string
        my $dcode = 0;
        if ($chr =~ /\p{InEmojiDoCoMo}/) {
            # docomo emoji
            $dcode = $code;
        } elsif ($chr =~ /\p{InEmojiAny}/) {
            # others emoji to docomo emoji
            my $moct = $utf8->encode(chr $code, $fb);   # Native UTF-8 octets
            my $gstr = $mixed->decode($moct, $fb);      # Google UTF-8 string
            my $doct = $docomo->encode($gstr, $fb);     # DoCoMo UTF-8 octets
            my $dstr = $utf8->decode($doct, $fb);       # DoCoMo UTF-8 string
            $dcode = ord $dstr if (1 == length $dstr);
        }
        my $data = data();
        my $hex  = sprintf '%04X' => $dcode;
        unless (exists $data->{docomo}->{$hex}) {
            my $aoct = $ascii->encode(chr $code, $fb);  # force fallback
            return $utf8->decode($aoct, $fb);           # UTF-8 string
        }
        my $file = $data->{docomo}->{$hex};
        my $name = $none->encode(chr $code, $fbtext);   # emoji name
        $name = $utf8->decode($name, $fb);              # UTF-8 string
        sprintf $HTML_FORMAT => $IMAGE_BASE, $file, $name;
    };
}

# Ｔｈｉｓ　ｆｉｌｅ　ｗａｓ　ｗｒｉｔｔｅｎ　ｉｎ　ＵＴＦ－８

1;
