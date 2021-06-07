use 5.20.0;

use strict;
use utf8;

use Test2::V0;
use Test::Warnings 'warning';
use Test::Requires 'YAML::XS';

use Path::Tiny;

use File::Serialize;

plan tests => 2;

my $data = { a => "Kohl’s" };
my $file = Path::Tiny->tempfile( SUFFIX => '.yaml' );

serialize_file $file, $data;

my $back = deserialize_file $file;

is $back->{a}, "Kohl’s", "Unicode character is still there";
