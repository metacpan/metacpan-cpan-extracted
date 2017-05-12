#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Excel::CloneXLSX::Format qw(translate_xlsx_format);

{
    my %old_format = (
        AlignH   => 0,
        AlignV   => 2,
        BdrColor => [undef, "#4F81BD", undef, undef,],
        BdrStyle => [0, 1, 0, 0,],
        Fill     => [0, undef, undef,],
        Font     => {
            Bold             => 0,
            Color            => "#000000",
            Height           => 12,
            Italic           => 0,
            Name             => "Calibri",
            Strikeout        => 0,
            Super            => 0,
            Underline        => 0,
            UnderlineStyle   => 0
        },
    );

    my %new_format = (
        bold             => 0,
        color            => "#000000",
        font             => "Calibri",
        font_script      => 0,
        font_strikeout   => 0,
        italic           => 0,
        pattern          => 0,
        right            => 1,
        right_color      => "#4F81BD",
        size             => 12,
        text_h_align     => 0,
        text_v_align     => 3,
        underline        => 0
    );


    my $translated = translate_xlsx_format( \%old_format );
    is_deeply($translated, \%new_format);
}


done_testing();
