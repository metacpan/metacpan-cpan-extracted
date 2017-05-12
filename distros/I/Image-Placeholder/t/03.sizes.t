use Modern::Perl;
use Test::More      tests => 12;

use Image::Placeholder;



{
    my $img = Image::Placeholder->new();
    ok( 300 == $img->get_width,  'default width is 300' );
    ok( 300 == $img->get_height, 'default height is 300' );
}
{
    my $img = Image::Placeholder->new( size => 'snafu' );
    ok( 300 == $img->get_width,  'invalid size is default width' );
    ok( 300 == $img->get_height, 'invalid size is default height' );
}
{
    my $img = Image::Placeholder->new( size => '200x100' );
    ok( 200 == $img->get_width,  '200x100 width is 200' );
    ok( 100 == $img->get_height, '200x100 height is 100' );
}
{
    my $img = Image::Placeholder->new( width => 450 );
    ok( 450 == $img->get_width,  'width is 450' );
    ok( 450 == $img->get_height, 'no height gets the width (450)' );
}
{
    my $img = Image::Placeholder->new( width => -1, height => -1 );
    ok( 300 == $img->get_width,  'negative widths are 300' );
    ok( 300 == $img->get_height, 'negative heights are 300' );
}
{
    my $img = Image::Placeholder->new( width => 0 );
    ok( 300 == $img->get_width,  'zero widths are 300' );
    ok( 300 == $img->get_height, 'zero heights are 300' );
}
