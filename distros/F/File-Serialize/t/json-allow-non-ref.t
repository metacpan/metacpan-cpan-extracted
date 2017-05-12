use strict;
use warnings;

use Test::More tests => 2;
use Test::Requires;
use Test::Exception;

test_requires 'JSON::MaybeXS';

use File::Serialize;

is deserialize_file( 't/corpus/non-ref.json' ) => 'hello', 'non-refs work';

no File::Serialize;

{
    use File::Serialize { allow_nonref => 0 };

    dies_ok { 
        deserialize_file( 't/corpus/non-ref.json' ) 
    } 'non-refs dies';
}





