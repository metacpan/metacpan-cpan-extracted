use strict;
use warnings;

use Test2::V0;
plan tests => 1;

use Test::Requires +{
    map { $_ => 0 } qw/ YAML::Tiny YAML::XS /
};

use File::Serialize;

is(
    File::Serialize->_serializer({ format => 'yaml' }) => 'File::Serialize::Serializer::YAML::XS'
);

