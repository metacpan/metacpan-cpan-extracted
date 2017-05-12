use strict;
use warnings;

use Test::More tests => 1;

use JSON::Schema::AsType;
use Path::Tiny;

ok not ( JSON::Schema::AsType->new( uri => "file:///" . path( './t/corpus/settlers.json' )->absolute )->validate_schema );

