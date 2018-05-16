use Test::More tests => 10;
use Test::HexString;

BEGIN {
    use_ok 'Graphics::Raylib::Util', ':objects';
}
use Config;

my $data = "\xDE\xAD\xBE\xEF"."\xBA\xDC\x0F\xFE"
         . "\xBA\xDC\x0F\xFE"."\xDE\xAD\xBE\xEF"
         . "\xBA\xDC\x0F\xFE"."\xDE\xAD\xBE\xEF";

my $img = image(data => $data, width => 2, height => 3, mipmaps => 42);
is ref($img), 'Graphics::Raylib::XS::Image';
is length $$img, $Config{ptrsize} + 4*$Config{intsize};
is_hexstr $img->data(length $data), $data;
is $img->width, 2;
is $img->height, 3;
is $img->mipmaps, 42;
my $fmt = Graphics::Raylib::XS::UNCOMPRESSED_R8G8B8A8;
is $img->format, $fmt;
my $str = "$img";
like $str, qr/^\(Image: ([[:xdigit:]]{1,2}){1,$Config{ptrsize}} \[2x3\], mipmaps: 42, format: $fmt\)/;
is "$img", $str, "Pointer doesn't change";
