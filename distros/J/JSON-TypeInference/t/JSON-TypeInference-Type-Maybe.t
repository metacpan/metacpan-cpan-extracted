use strict;
use warnings;
use lib 't/lib';
use Test::More;

use JSON::TypeInference::Type::Null;
use JSON::TypeInference::Type::Number;
use JSON::TypeInference::Type::String;

require_ok 'JSON::TypeInference::Type::Maybe';

subtest '#looks_like_maybe' => sub {
  my $string = JSON::TypeInference::Type::String->new;
  my $number = JSON::TypeInference::Type::Number->new;
  my $null = JSON::TypeInference::Type::Null->new;

  subtest 'not maybe' => sub {
    ok ! JSON::TypeInference::Type::Maybe->looks_like_maybe([ $string ]);
    ok ! JSON::TypeInference::Type::Maybe->looks_like_maybe([ $string, $number ]);
    ok ! JSON::TypeInference::Type::Maybe->looks_like_maybe([ $null, $string, $number ]);
  };
  subtest 'maybe' => sub {
    ok JSON::TypeInference::Type::Maybe->looks_like_maybe([ $null, $number ]);
  };
};

done_testing;
