use strict;
use warnings;
use lib 't/lib';
use Test::Deep qw(cmp_deeply);
use Test::JSON::TypeInference::Matcher;
use Test::More;
use Types::Serialiser;

require_ok 'JSON::TypeInference::Type::Array';
require_ok 'JSON::TypeInference::Type::Boolean';
require_ok 'JSON::TypeInference::Type::Null';
require_ok 'JSON::TypeInference::Type::Number';
require_ok 'JSON::TypeInference::Type::Object';
require_ok 'JSON::TypeInference::Type::String';
require_ok 'JSON::TypeInference::Type::Union';
require_ok 'JSON::TypeInference';

subtest '#infer' => sub {
  subtest 'same types' => sub {
    cmp_deeply +JSON::TypeInference->infer([qw( a b c )]), string;
    cmp_deeply +JSON::TypeInference->infer([1, 2, 3]), number;
    cmp_deeply +JSON::TypeInference->infer([ Types::Serialiser::true, Types::Serialiser::true ]), boolean;
    cmp_deeply +JSON::TypeInference->infer([undef, undef]), null;
    cmp_deeply +JSON::TypeInference->infer([ [1], [2] ]), array number;
  };
  subtest 'union' => sub {
    cmp_deeply +JSON::TypeInference->infer([ 1, 'a' ]), union number, string;
    cmp_deeply +JSON::TypeInference->infer([ 1, [1] ]), union array(number), number;
  };
  subtest 'unknown' => sub {
    cmp_deeply +JSON::TypeInference->infer([ bless({}, 't::Blessed') ]), unknown;
  };
  subtest 'object' => sub {
    cmp_deeply +JSON::TypeInference->infer([ { id => 1, is_ok => Types::Serialiser::true }, { id => 2, is_ok => Types::Serialiser::false } ]), object(
      id    => number,
      is_ok => boolean,
    );
  };
  subtest 'optional' => sub {
    cmp_deeply +JSON::TypeInference->infer([ { id => 1, is_ok => Types::Serialiser::true }, { id => 2 } ]), object(
      id    => number,
      is_ok => maybe boolean,
    );
  };
  subtest 'empty array' => sub {
    cmp_deeply +JSON::TypeInference->infer([ [] ]), array unknown;
  };
  subtest 'empty object' => sub {
    cmp_deeply +JSON::TypeInference->infer([ {} ]), object();
  };
};

done_testing;
