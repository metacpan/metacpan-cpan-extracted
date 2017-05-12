# https://rt.cpan.org/Public/Bug/Display.html?id=28072
use strict;
use Test::More tests => 2;
use File::MMagic::XS;

{
    local $/ = "\n";
    my $magic = File::MMagic::XS->new();
    is( $magic->get_mime( 't/data/picture.jpg' ), 'image/jpeg' );
}

{
    local $/;
    my $magic = File::MMagic::XS->new();
    is( $magic->get_mime( 't/data/picture.jpg' ), 'image/jpeg' );
}

