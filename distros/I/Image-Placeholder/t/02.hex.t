use Modern::Perl;
use Test::More      tests => 4;

use Image::Placeholder;


{
    my $img = Image::Placeholder->new();
    my @rgb = $img->rgb_to_hex( 'ffffff' );
    is_deeply( [ 255, 255, 255 ], \@rgb, 'white' );
}
{
    my $img = Image::Placeholder->new();
    my @rgb = $img->rgb_to_hex( 'f90' );
    is_deeply( [ 255, 153, 0 ], \@rgb, 'orange shorthand' );
}
{
    my $img = Image::Placeholder->new();
    my @rgb = $img->rgb_to_hex( 'bob' );
    is_deeply( [ 0, 0, 0 ], \@rgb, 'unknown strings are black' );
}
{
    my $img = Image::Placeholder->new();
    my @rgb = $img->rgb_to_hex( 'ccff' );
    is_deeply( [ 0, 0, 0 ], \@rgb, 'error strings are black' );
}
