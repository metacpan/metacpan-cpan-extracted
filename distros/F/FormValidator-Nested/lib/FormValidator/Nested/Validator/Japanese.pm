package FormValidator::Nested::Validator::Japanese;
use strict;
use warnings;
use utf8;

sub hiragana {
    my ( $value, $options, $req ) = @_;

    if ( $value =~ /\P{InHiragana}/ ) {
        return 0;
    }
    return 1;
}

sub katakana {
    my ( $value, $options, $req ) = @_;

    if ( $value =~ /\P{InKatakana}/ ) {
        return 0;
    }
    return 1;
}

1;
