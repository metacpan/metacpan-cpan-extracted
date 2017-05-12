=head1 NAME

Encode::JP::Emoji::Encoding - Emoji encodings

=head1 DESCRIPTION

This module implements all encodings provided by the package.
Use L<Encode::JP::Emoji> instead of loading this module directly.

=head1 AUTHOR

Yusuke Kawasaki, L<http://www.kawa.net/>

=head1 SEE ALSO

L<Encode::JP::Emoji>

=head1 COPYRIGHT

Copyright 2009-2010 Yusuke Kawasaki, all rights reserved.

=cut

use strict;
use warnings;

package Encode::JP::Emoji::Encoding;
use base qw(Encode::Encoding);
use Encode::JP::Emoji::Mapping;
use Carp ();
use Encode ();

our $VERSION = '0.60';

my $ascii_encoding = Encode::find_encoding('us-ascii');
sub sub_check {
    my $check = $_[1];
    return $check unless $check;    # undef or 0
    return $check if ref $check;    # sub-routine
    return sub {
        $ascii_encoding->encode(chr $_[0], $check);
    }
}

sub no_sub_check {
    my $check = $_[1];
    $check;
}

sub decode {
    my ($self, $octets, $check) = @_;
    return undef unless defined $octets;
    $check ||=0;
    my $subcheck = $self->sub_check($check);
    my $nosubcheck = $self->no_sub_check($check);
    my $copy = $octets if $check and !($check & Encode::LEAVE_SRC());
    $octets .= '' if ref $octets; # stringify;
    $self->before_decode($octets, $subcheck);
    my $string = $self->byte_encoding->decode($octets, $nosubcheck);
    $self->after_decode($string, $subcheck);
    $_[1] = $copy if $check and !($check & Encode::LEAVE_SRC());
    $string;
}

sub encode {
    my ($self, $string, $check) = @_;
    return undef unless defined $string;
    $check ||=0;
    my $subcheck = $self->sub_check($check);
    my $nosubcheck = $self->no_sub_check($check);
    my $copy = $string if $check and !($check & Encode::LEAVE_SRC());
    $string .= '' if ref $string; # stringify;
    $self->before_encode($string, $subcheck);
    my $octets = $self->byte_encoding->encode($string, $nosubcheck);
    $self->after_encode($octets, $subcheck);
    $_[1] = $copy if $check and !($check & Encode::LEAVE_SRC());
    $octets;
}

sub before_decode {}
sub after_decode  {}
sub before_encode {}
sub after_encode  {}
sub byte_encoding { Carp::croak "byte_encoding not implemented"; }

# Shift_JIS Base

package Encode::JP::Emoji::Encoding::Shift_JIS;
use base 'Encode::JP::Emoji::Encoding';

sub mime_name { 'Shift_JIS'; }

my $cp932_encoding = Encode::find_encoding('cp932');
sub byte_encoding {
    $cp932_encoding;
}

# UTF8 Base

package Encode::JP::Emoji::Encoding::UTF8;
use base 'Encode::JP::Emoji::Encoding';
__PACKAGE__->Define('x-utf8-emoji-docomo-pp');
__PACKAGE__->Define('x-utf8-emoji-kddiapp-pp');
__PACKAGE__->Define('x-utf8-emoji-kddiweb-pp');
__PACKAGE__->Define('x-utf8-emoji-softbank3g-pp');
__PACKAGE__->Define('x-utf8-e4u-google-pp');

sub mime_name { 'UTF-8'; }

my $utf8_encoding = Encode::find_encoding('UTF-8');
sub byte_encoding {
    $utf8_encoding;
}

sub no_sub_check {
    my $check = $_[1];
    return 0 if ref $check;
    $check;
}

# DoCoMo

package Encode::JP::Emoji::Encoding::X_SJIS_EMOJI_DOCOMO_PP;
use base 'Encode::JP::Emoji::Encoding::Shift_JIS';
__PACKAGE__->Define('x-sjis-emoji-docomo-pp');
*after_decode  = \&Encode::JP::Emoji::Mapping::docomo_cp932_to_docomo_unicode;
*before_encode = \&Encode::JP::Emoji::Mapping::docomo_unicode_to_docomo_cp932;

package Encode::JP::Emoji::Encoding::X_SJIS_E4U_DOCOMO_PP;
use base 'Encode::JP::Emoji::Encoding::Shift_JIS';
__PACKAGE__->Define('x-sjis-e4u-docomo-pp');
*after_decode  = \&Encode::JP::Emoji::Mapping::docomo_cp932_to_google_unicode;
*before_encode = \&Encode::JP::Emoji::Mapping::google_unicode_to_docomo_cp932;

package Encode::JP::Emoji::Encoding::X_UTF8_E4U_DOCOMO_PP;
use base 'Encode::JP::Emoji::Encoding::UTF8';
__PACKAGE__->Define('x-utf8-e4u-docomo-pp');
*after_decode  = \&Encode::JP::Emoji::Mapping::docomo_unicode_to_google_unicode;
*before_encode = \&Encode::JP::Emoji::Mapping::google_unicode_to_docomo_unicode;

# KDDIapp

package Encode::JP::Emoji::Encoding::X_SJIS_EMOJI_KDDIAPP_PP;
use base 'Encode::JP::Emoji::Encoding::Shift_JIS';
__PACKAGE__->Define('x-sjis-emoji-kddiapp-pp');
*after_decode  = \&Encode::JP::Emoji::Mapping::kddi_cp932_to_kddi_unicode;
*before_encode = \&Encode::JP::Emoji::Mapping::kddi_unicode_to_kddi_cp932;

package Encode::JP::Emoji::Encoding::X_SJIS_E4U_KDDIAPP_PP;
use base 'Encode::JP::Emoji::Encoding::Shift_JIS';
__PACKAGE__->Define('x-sjis-e4u-kddiapp-pp');
*after_decode  = \&Encode::JP::Emoji::Mapping::kddi_cp932_to_google_unicode;
*before_encode = \&Encode::JP::Emoji::Mapping::google_unicode_to_kddi_cp932;

package Encode::JP::Emoji::Encoding::X_UTF8_E4U_KDDIAPP_PP;
use base 'Encode::JP::Emoji::Encoding::UTF8';
__PACKAGE__->Define('x-utf8-e4u-kddiapp-pp');
*after_decode  = \&Encode::JP::Emoji::Mapping::kddi_unicode_to_google_unicode;
*before_encode = \&Encode::JP::Emoji::Mapping::google_unicode_to_kddi_unicode;

# KDDIweb

package Encode::JP::Emoji::Encoding::X_SJIS_EMOJI_KDDIWEB_PP;
use base 'Encode::JP::Emoji::Encoding::Shift_JIS';
__PACKAGE__->Define('x-sjis-emoji-kddiweb-pp');
*after_decode  = \&Encode::JP::Emoji::Mapping::kddiweb_cp932_to_kddiweb_unicode;
*before_encode = \&Encode::JP::Emoji::Mapping::kddiweb_unicode_to_kddiweb_cp932;

package Encode::JP::Emoji::Encoding::X_SJIS_E4U_KDDIWEB_PP;
use base 'Encode::JP::Emoji::Encoding::Shift_JIS';
__PACKAGE__->Define('x-sjis-e4u-kddiweb-pp');
*after_decode  = \&Encode::JP::Emoji::Mapping::kddiweb_cp932_to_google_unicode;
*before_encode = \&Encode::JP::Emoji::Mapping::google_unicode_to_kddiweb_cp932;

package Encode::JP::Emoji::Encoding::X_UTF8_E4U_KDDIWEB_PP;
use base 'Encode::JP::Emoji::Encoding::UTF8';
__PACKAGE__->Define('x-utf8-e4u-kddiweb-pp');
*after_decode  = \&Encode::JP::Emoji::Mapping::kddiweb_unicode_to_google_unicode;
*before_encode = \&Encode::JP::Emoji::Mapping::google_unicode_to_kddiweb_unicode;

# SoftBank 2G

package Encode::JP::Emoji::Encoding::X_SJIS_EMOJI_SOFTBANK2G_PP;
use base 'Encode::JP::Emoji::Encoding::Shift_JIS';
__PACKAGE__->Define('x-sjis-emoji-softbank2g-pp');
*after_decode  = \&Encode::JP::Emoji::Encoding::Util::softbankauto_cp932_to_softbank_unicode;
*before_encode = \&Encode::JP::Emoji::Encoding::Util::softbank_unicode_to_softbank_escape;

package Encode::JP::Emoji::Encoding::X_UTF8_EMOJI_SOFTBANK2G_PP;
use base 'Encode::JP::Emoji::Encoding::UTF8';
__PACKAGE__->Define('x-utf8-emoji-softbank2g-pp');
*after_decode  = \&Encode::JP::Emoji::Encoding::Util::softbank_escape_to_softbank_unicode;
*before_encode = \&Encode::JP::Emoji::Encoding::Util::softbank_unicode_to_softbank_escape;

package Encode::JP::Emoji::Encoding::X_SJIS_E4U_SOFTBANK2G_PP;
use base 'Encode::JP::Emoji::Encoding::Shift_JIS';
__PACKAGE__->Define('x-sjis-e4u-softbank2g-pp');
*after_decode  = \&Encode::JP::Emoji::Encoding::Util::softbankauto_cp932_to_google_unicode;
*before_encode = \&Encode::JP::Emoji::Encoding::Util::google_unicode_to_softbank_escape;

package Encode::JP::Emoji::Encoding::X_UTF8_E4U_SOFTBANK2G_PP;
use base 'Encode::JP::Emoji::Encoding::UTF8';
__PACKAGE__->Define('x-utf8-e4u-softbank2g-pp');
*after_decode  = \&Encode::JP::Emoji::Encoding::Util::softbankauto_unicode_to_google_unicode;
*before_encode = \&Encode::JP::Emoji::Encoding::Util::google_unicode_to_softbank_escape;

# SoftBank 3G

package Encode::JP::Emoji::Encoding::X_SJIS_EMOJI_SOFTBANK3G_PP;
use base 'Encode::JP::Emoji::Encoding::Shift_JIS';
__PACKAGE__->Define('x-sjis-emoji-softbank3g-pp');
*after_decode  = \&Encode::JP::Emoji::Mapping::softbank_cp932_to_softbank_unicode;
*before_encode = \&Encode::JP::Emoji::Mapping::softbank_unicode_to_softbank_cp932;

package Encode::JP::Emoji::Encoding::X_SJIS_E4U_SOFTBANK3G_PP;
use base 'Encode::JP::Emoji::Encoding::Shift_JIS';
__PACKAGE__->Define('x-sjis-e4u-softbank3g-pp');
*after_decode  = \&Encode::JP::Emoji::Mapping::softbank_cp932_to_google_unicode;
*before_encode = \&Encode::JP::Emoji::Mapping::google_unicode_to_softbank_cp932;

package Encode::JP::Emoji::Encoding::X_UTF8_E4U_SOFTBANK3G_PP;
use base 'Encode::JP::Emoji::Encoding::UTF8';
__PACKAGE__->Define('x-utf8-e4u-softbank3g-pp');
*after_decode  = \&Encode::JP::Emoji::Mapping::softbank_unicode_to_google_unicode;
*before_encode = \&Encode::JP::Emoji::Mapping::google_unicode_to_softbank_unicode;

# Mixed

package Encode::JP::Emoji::Encoding::X_UTF8_E4U_MIXED_PP;
use base 'Encode::JP::Emoji::Encoding::UTF8';
__PACKAGE__->Define('x-utf8-e4u-mixed-pp');
*after_decode  = \&Encode::JP::Emoji::Mapping::mixed_unicode_to_google_unicode;
*before_encode = \&Encode::JP::Emoji::Mapping::google_unicode_to_mixed_unicode;

# Unicode Standard

package Encode::JP::Emoji::Encoding::X_UTF8_E4U_UNICODE_PP;
use base 'Encode::JP::Emoji::Encoding::UTF8';
__PACKAGE__->Define('x-utf8-e4u-unicode-pp');
*after_decode  = \&Encode::JP::Emoji::Mapping::unicode_unicode_to_google_unicode;
*before_encode = \&Encode::JP::Emoji::Mapping::google_unicode_to_unicode_unicode;

# No PUA

package Encode::JP::Emoji::Encoding::X_UTF8_E4U_NONE_PP;
use base 'Encode::JP::Emoji::Encoding::UTF8';
__PACKAGE__->Define('x-utf8-emoji-none-pp');
__PACKAGE__->Define('x-utf8-e4u-none-pp');

*after_decode  = \&Encode::JP::Emoji::Encoding::Util::no_emoji;
*before_encode = \&Encode::JP::Emoji::Encoding::Util::no_emoji;

package Encode::JP::Emoji::Encoding::X_SJIS_E4U_NONE_PP;
use base 'Encode::JP::Emoji::Encoding::Shift_JIS';
__PACKAGE__->Define('x-sjis-emoji-none-pp');
__PACKAGE__->Define('x-sjis-e4u-none-pp');

*after_decode  = \&Encode::JP::Emoji::Encoding::Util::no_emoji;
*before_encode = \&Encode::JP::Emoji::Encoding::Util::no_emoji;

# Utils

package Encode::JP::Emoji::Encoding::Util;
use Encode::JP::Emoji::Property;

sub softbank_escape_to_softbank_unicode {
    $_[1] =~ s{
        \x1B\x24([GEFOPQ])([\x20-\x7F]+)\x0F?
    }{
        &escape_vodafone($1, $2)
    }egomx;
}

sub softbankauto_cp932_to_softbank_unicode {
    if ($_[1] =~ /\x1B\x24/) {
        Encode::JP::Emoji::Mapping::softbank_cp932_to_softbank_unicode(@_);
        Encode::JP::Emoji::Encoding::Util::softbank_escape_to_softbank_unicode(@_);
    } else {
        Encode::JP::Emoji::Mapping::softbank_cp932_to_softbank_unicode(@_);
    }
}

sub softbankauto_cp932_to_google_unicode {
    if ($_[1] =~ /\x1B\x24/) {
        Encode::JP::Emoji::Mapping::softbank_cp932_to_softbank_unicode(@_);
        Encode::JP::Emoji::Encoding::Util::softbank_escape_to_softbank_unicode(@_);
        Encode::JP::Emoji::Mapping::softbank_unicode_to_google_unicode(@_);
    } else {
        Encode::JP::Emoji::Mapping::softbank_cp932_to_google_unicode(@_);
    }
}

sub softbankauto_unicode_to_google_unicode {
    if ($_[1] =~ /\x1B\x24/) {
        Encode::JP::Emoji::Encoding::Util::softbank_escape_to_softbank_unicode(@_);
        Encode::JP::Emoji::Mapping::softbank_unicode_to_google_unicode(@_);
    } else {
        Encode::JP::Emoji::Mapping::softbank_unicode_to_google_unicode(@_);
    }
}

sub softbank_unicode_to_softbank_escape {
    my $check = $_[2] || sub {''};
    $_[1] =~ s{
        (\p{InEmojiSoftBank}+)
    }{
        &unescape_vodafone($1)
    }egomx;
}

sub google_unicode_to_softbank_escape {
    Encode::JP::Emoji::Mapping::google_unicode_to_softbank_unicode(@_);
    Encode::JP::Emoji::Encoding::Util::softbank_unicode_to_softbank_escape(@_);
}

my $map_escape_vodafone = {
    G   =>  0xE000,
    E   =>  0xE100,
    F   =>  0xE200,
    O   =>  0xE300,
    P   =>  0xE400,
    Q   =>  0xE500,
};

sub escape_vodafone {
    my $high = shift;
    my $code = shift;
    my $offset = $map_escape_vodafone->{$high};
    join '' => map {chr($offset - 32 + ord $_)} split //, $code;
}

my $map_unescape_vodafone = [qw( G E F O P Q )];

sub unescape_vodafone {
    my $string = shift;
    my $buf = [];
    my $prev = "";
    foreach my $char (split //, $string) {
        my $code = ord $char;
        my $high = ($code & 0x0700) >> 8;
        my $low  = ($code & 0xFF) + 32;
        my $page = $map_unescape_vodafone->[$high] or next;
        if ($prev eq $page) {
            $buf->[$#$buf] .= sprintf "%c" => $low;
        } else {
            push @$buf, sprintf "\x1B\x24%s%c" => $page, $low;
        }
        $prev = $page;
    }
    push @$buf, '';
    join "\x0F" => @$buf;
}

sub no_emoji {
    my $check = $_[2] || sub {};
    $_[1] =~ s{
        (\p{InEmojiAny})
    }{
        &$check(ord $1);
    }egomx;
}

1;
