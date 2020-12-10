#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Image::PNG::Const ':all';
use Image::PNG::Libpng ':all';
my $png = create_write_struct ();
$png->set_IHDR ({width => 1, height => 1, bit_depth => 8,
		 color_type => PNG_COLOR_TYPE_GRAY});
$png->set_rows (['X']);
$png->set_text ([{
    compression => PNG_TEXT_COMPRESSION_NONE,
    key => "Copyright",
    text => "Copyright (C) 2020 Fat Cat",
}, {
    compression => PNG_ITXT_COMPRESSION_zTXt,
    key => "Copyright",
    lang_key => '著者権',
    lang => 'ja_JP',
    text => '©令和２年茉莉ニャンバーガーさん',
}]);
$png->write_png_file ('copyright.png');
