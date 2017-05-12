package GD::Persian;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = "0.9";
$VERSION = eval $VERSION;

my $p_char = {
    'آ' => [ 'ﺂ', 'ﺂ', 'آ' ],
    'ا' => [ 'ﺎ', 'ﺎ', 'ا' ],
    'ب' => [ 'ﺐ', 'ﺒ', 'ﺑ' ],
    'پ' => [ 'ﭗ', 'ﭙ', 'ﭘ' ],
    'ت' => [ 'ﺖ', 'ﺘ', 'ﺗ' ],
    'ث' => [ 'ﺚ', 'ﺜ', 'ﺛ' ],
    'ج' => [ 'ﺞ', 'ﺠ', 'ﺟ' ],
    'چ' => [ 'ﭻ', 'ﭽ', 'ﭼ' ],
    'ح' => [ 'ﺢ', 'ﺤ', 'ﺣ' ],
    'خ' => [ 'ﺦ', 'ﺨ', 'ﺧ' ],
    'د' => [ 'ﺪ', 'ﺪ', 'ﺩ' ],
    'ذ' => [ 'ﺬ', 'ﺬ', 'ﺫ' ],
    'ر' => [ 'ﺮ', 'ﺮ', 'ﺭ' ],
    'ز' => [ 'ﺰ', 'ﺰ', 'ﺯ' ],
    'ژ' => [ 'ﮋ', 'ﮋ', 'ﮊ' ],
    'س' => [ 'ﺲ', 'ﺴ', 'ﺳ' ],
    'ش' => [ 'ﺶ', 'ﺸ', 'ﺷ' ],
    'ص' => [ 'ﺺ', 'ﺼ', 'ﺻ' ],
    'ض' => [ 'ﺾ', 'ﻀ', 'ﺿ' ],
    'ط' => [ 'ﻂ', 'ﻄ', 'ﻃ' ],
    'ظ' => [ 'ﻆ', 'ﻈ', 'ﻇ' ],
    'ع' => [ 'ﻊ', 'ﻌ', 'ﻋ' ],
    'غ' => [ 'ﻎ', 'ﻐ', 'ﻏ' ],
    'ف' => [ 'ﻒ', 'ﻔ', 'ﻓ' ],
    'ق' => [ 'ﻖ', 'ﻘ', 'ﻗ' ],
    'ک' => [ 'ﻚ', 'ﻜ', 'ﻛ' ],
    'گ' => [ 'ﮓ', 'ﮕ', 'ﮔ' ],
    'ل' => [ 'ﻞ', 'ﻠ', 'ﻟ' ],
    'م' => [ 'ﻢ', 'ﻤ', 'ﻣ' ],
    'ن' => [ 'ﻦ', 'ﻨ', 'ﻧ' ],
    'و' => [ 'ﻮ', 'ﻮ', 'ﻭ' ],
    'ی' => [ 'ﯽ', 'ﯿ', 'ﯾ' ],
    'ك' => [ 'ﻚ', 'ﻜ', 'ﻛ' ],
    'ي' => [ 'ﻲ', 'ﻴ', 'ﻳ' ],
    'أ' => [ 'ﺄ', 'ﺄ', 'ﺃ' ],
    'ؤ' => [ 'ﺆ', 'ﺆ', 'ﺅ' ],
    'إ' => [ 'ﺈ', 'ﺈ', 'ﺇ' ],
    'ئ' => [ 'ﺊ', 'ﺌ', 'ﺋ' ],
    'ة' => [ 'ﺔ', 'ﺘ', 'ﺗ' ],
    'ه' => [ 'ﻪ', 'ﻬ', 'ﻫ' ],
};

my @mp_chars =
  ( 'آ', 'ا', 'د', 'ذ', 'ر', 'ز', 'ژ', 'و', 'أ', 'إ', 'ؤ' );
my @ignorelist = (
    '',    'ٌ',  'ٍ',  'ً',  'ُ',  'ِ',  'َ',  'ّ',
    'ٓ',  'ٰ',  'ٔ',  'ﹶ', 'ﹺ', 'ﹸ', 'ﹼ', 'ﹾ',
    'ﹴ', 'ﹰ', 'ﱞ', 'ﱟ', 'ﱠ', 'ﱡ', 'ﱢ', 'ﱣ',
);

sub Convert {
    my $str = shift;

    my $str_len = length($str);

    if ( not utf8::is_utf8($str) ) {
        Carp::croak( __PACKAGE__
              . ": string ("
              . $str
              . ") is not utf8, maybe you need to add `use utf8` in your source file"
        );
    }
    my @arr_str = split( "", $str );
    my $new_str = "";

    #split by space
    my @arr_words = split( " ", $str );

    #we also need to reverse text because GD shows it reverse !
    @arr_words = reverse @arr_words;
    my $num_words = scalar @arr_words;
    foreach my $w_index ( 0 .. $num_words - 1 ) {

        @arr_str = split "", $arr_words[$w_index];
        $str_len = scalar @arr_str;

        my $converted_word = "";
        foreach my $index ( 0 .. $str_len - 1 ) {

            #now we need to stick chars together if is needed
            my ( $ch_back, $ch_next ) = ( 0, 0 );
            $ch_back = $arr_str[ $index - 1 ] if $index > 0;
            $ch_next = $arr_str[ $index + 1 ] if $index < $str_len;

            $ch_back = 0
              if $index > 0 and grep { /$arr_str[$index-1]/ } @mp_chars;

            if ( not grep { /$arr_str[$index]/ } keys %{$p_char} ) {
                $converted_word .= $arr_str[$index];
            }
            elsif ( not $ch_next and not $ch_back ) {
                $converted_word .= $arr_str[$index];
            }
            elsif ( $ch_next and not $ch_back ) {
                $converted_word .= $p_char->{ $arr_str[$index] }->[2];
            }
            elsif ( $ch_next and $ch_back ) {
                $converted_word .= $p_char->{ $arr_str[$index] }->[1];
            }
            elsif ( not $ch_next and $ch_back ) {
                $converted_word .= $p_char->{ $arr_str[$index] }->[0];
            }
            else {
                $converted_word .= $arr_str[$index];
            }
        }
        if ( $w_index != $num_words - 1 ) {
            $new_str .= ( reverse $converted_word ) . " ";
        }
        else {
            $new_str .= ( reverse $converted_word );
        }
    }

    return $new_str;
}

=head1 NAME

GD::Persian - Persian UTF-8 support for GD module

=head1 DESCRIPTION

The L<GD> lib dosn't support Persian and Arabic chars propebly. It shows characters unsticky and reverse the sentence.
This package get Persian UTF-8 charecter and replace it with proper characters that is readable in L<GD>
    
=head1 SYNOPSIS

use GD;


    # create a new image
    use GD;
    use GD::Persian;
    use utf8;
    my $gd        = new GD::Image(800,200);
    my $black     = $gd->colorAllocate(0,0,0); 
    my $white     = $gd->colorAllocate(255,255,255);
    my $font_path = "/Library/Fonts/Tahoma.ttf";
    $gd->stringFT($white,$font_path ,40 ,0 ,20 ,90 ,
             GD::Persian::Convert("هوا بس ناجوان مردانه سرد است "),
              {linespacing=>0.6,
               charmap  => 'Unicode',
              });
    binmode STDOUT;
    print $gd->png;

=head1 METHODS


=over


=item C<Convert>
    
    Convert Persian UTF-8 characters to proper characters for using in images that is created by GD lib

=cut 

=back

=head1 AUTHOR

Milad Rastian <milad@cpan.org>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Milad Rastian E<lt>milad@cpan.orgE<gt>

All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

=head1 BUGS

https://github.com/slashmili/perl-gd-persian/issues

=cut

=head1 VERSION

0.9

=cut

1;
