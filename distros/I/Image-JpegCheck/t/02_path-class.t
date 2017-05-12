use strict;
use warnings;
use Test::More;
use Image::JpegCheck;

plan skip_all => 'this test requires Path::Class' unless eval "use Path::Class; 1;";
plan tests => 2;

Path::Class->import;

ok is_jpeg(file('t/foo.jpg'));
ok !is_jpeg(file('t/01_simple.t'));

