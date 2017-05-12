use Test::More      tests => 2;



use_ok( 'Image::Placeholder' );

my $img = Image::Placeholder->new();
isa_ok( $img, 'Image::Placeholder' );
