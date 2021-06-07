use strict;
use warnings;

use Test2::V0;
plan tests => 1;

{
    package File::Serialize::Serializer::Bad;
    use Moo;
    with 'File::Serialize::Serializer';

    sub required_modules { 'Inexistant' }

    sub extensions { 'bad' }

    sub serialize { }
    sub deserialize { }

    1;
}

ok( !File::Serialize::Serializer::Bad->is_operative, "can't use it" );


