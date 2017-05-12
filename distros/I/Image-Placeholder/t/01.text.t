use Modern::Perl;
use Test::More      tests => 3;

use Image::Placeholder;



{
    my $img = Image::Placeholder->new();
    ok( '300×300' eq $img->get_text() );
}
{
    my $img = Image::Placeholder->new( width => 600, height => 300 );
    ok( '600×300' eq $img->get_text() );
}
{
    my $img = Image::Placeholder->new( text => 'placeholder' );
    ok( 'placeholder' eq $img->get_text() );
}
