use Test::More tests => 49;
use Scalar::Util qw/blessed/;

BEGIN {
    use_ok 'Graphics::Raylib::Util', ':objects';
}

my @vector2 = (10, -12);
my $vector2 = vector(@vector2);
is blessed($vector2), 'Graphics::Raylib::XS::Vector2';
is length $$vector2, 8;
is "$vector2", '(10, -12)';
is $vector2->x, $vector2[0];
is $vector2->y, $vector2[1];
is vector(1,2,3), vector(1,2,3);
ok (vector(map { $_ - 1 } @vector2) == ($vector2 + vector(-1,-1)));
is abs($vector2), sqrt(10**2 + (-12)**2);

my @vector3 = (10, -12, 9);
my $vector3 = vector(@vector3);
is blessed($vector3), 'Graphics::Raylib::XS::Vector3';
is length $$vector3, 12;
is "$vector3", '(10, -12, 9)';
is $vector3->x, $vector3[0];
is $vector3->y, $vector3[1];
is $vector3->z, $vector3[2];
is abs($vector3), sqrt(10**2 + (-12)**2 + 9**2);

my $vector2to3 = vector(@vector2, 0);
my $sum = $vector2to3 + $vector3;
is $sum, vector(20, -24, 9);
ok $vector2to3 == $vector2;

{
    my @vector4 = (10, -12, 9, 2);
    my $vector4 = vector(@vector4);
    is blessed($vector4), 'Graphics::Raylib::XS::Vector4';
    is length $$vector4, 16;
    is "$vector4", '(10, -12, 9, 2)';
    is $vector4->x, $vector4[0];
    is $vector4->y, $vector4[1];
    is $vector4->z, $vector4[2];
    is $vector4->w, $vector4[3];
    is abs($vector4), sqrt(10**2 + (-12)**2 + 9**2 + 2**2);
}

my $vector4 = vector($vector3);
is length $$vector4, 12;
is $vector4, $vector3;

my $vector5 = vector([10, -12, 9]);
is length $$vector5, 12;
is $vector5, $vector3;

my $rect = rectangle(x=>10, y=>-12, width => 2, height => 3);
is blessed($rect), 'Graphics::Raylib::XS::Rectangle';
is "$rect", '(x: 10.000000, y: -12.000000, width: 2.000000, height: 3.000000)';
is length $$rect, 16;
is $rect->x, 10;
is $rect->y, -12;
is $rect->width, 2;
is $rect->height, 3;
is rectangle(position => vector(10, -12), size => vector(2, 3)), $rect;
ok rectangle(x=>10, y=> -12, width=> 1, height => 3) x $rect, 'Collision';
ok !(rectangle(x=>10, y=> 10, width=> 1, height => 3) x $rect), 'No collision';

my $cam = camera3d(position=>vector(4,2,0), target=>[5,6,7], up => $vector3, fovy => 3.5);
is blessed($cam), 'Graphics::Raylib::XS::Camera3D';
is length $$cam, 44;
isnt $cam->position, vector(2,2,0);
is $cam->position, vector(4,2,0);
is $cam->target, vector(5,6,7);
is $cam->up, $vector3;
is $cam->fovy, 3.5;
is "$cam", "(position: (4, 2, 0), target: (5, 6, 7), up: $vector3, fovy: 3.5, type: 0)";

my $cam2 = ${vector(4,2,0)}.${vector(5,6,7)}.$$vector3.pack('f2', 3.5, 0);
is $$cam, $cam2;
