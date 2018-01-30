use Test::More tests => 16;

BEGIN {
    use_ok 'Graphics::Raylib::Util';
}

my @vector2 = (10, -12);
my $vector2 = Graphics::Raylib::Util::vector(@vector2);
is ref($vector2), 'Graphics::Raylib::XS::Vector2';
is "$vector2", '(10, -12)';
is $vector2->x, $vector2[0];
is $vector2->y, $vector2[1];

my @vector3 = (10, -12, 9);
my $vector3 = Graphics::Raylib::Util::vector(@vector3);
is ref($vector3), 'Graphics::Raylib::XS::Vector3';
is "$vector3", '(10, -12, 9)';
is $vector3->x, $vector3[0];
is $vector3->y, $vector3[1];
is $vector3->z, $vector3[2];

my $rect = Graphics::Raylib::Util::rectangle(x=>0, y=>1, width => 2, height => 3);
is ref($rect), 'Graphics::Raylib::XS::Rectangle';
is "$rect", '(x: 0, y: 1, width: 2, height: 3)';
is $rect->x, 0;
is $rect->y, 1;
is $rect->width, 2;
is $rect->height, 3;
