use strict;
use warnings;

use Test2::V0;
use Test::Exception;
use Test::Requires;

use Path::Tiny;
use File::Serialize;

use Module::Runtime qw/ use_module /;

for my $serializer (
    map { "File::Serialize::Serializer::$_" } qw/
        JSON::MaybeXS
        TOML
        XML::Simple
        YAML::Tiny
        YAML::XS
        Data::Dumper
        JSON5
        Markdown
    /
) {
    subtest $serializer => sub {
        use_module( $serializer );

        plan skip_all => "dependencies for $serializer not met"
            unless use_module($serializer)->is_operative;

        my $ext = $serializer->extension;
        my $x = deserialize_file( "t/corpus/foo.$ext", { serializers => [ $serializer ] } );

        is $x => { foo => 'bar' };

        my $time = scalar localtime;

        my $path = "t/corpus/time.$ext";
        serialize_file( $path => {time => $time}, { serializers => [ $serializer ] } );

        is deserialize_file($path)->{time} => $time;
    }
}

throws_ok {
    serialize_file 't/corpus/meh' => [ 1..5 ];
} qr/no serializer found/, 'no serializer found';

subtest "explicit format" => sub {
    test_requires 'YAML';

    serialize_file 't/corpus/mystery' => [1..5], { format => 'yaml' };

    like path('t/corpus/mystery')->slurp_utf8 => qr'- 1', 'right format';
};

done_testing;
