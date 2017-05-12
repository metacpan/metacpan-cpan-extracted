# -*- perl -*-

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
use Test::Exception;

use_ok('Hash::Layout');

ok(
  my $HL = Hash::Layout->new({
    levels => [
      { 
        name => 'source', 
        delimiter => ':' 
      },{ 
        name => 'type', 
        delimiter => '/',
        registered_keys => [qw(isa table_name columns relationships constraints)]
      },{ 
        name => 'id', 
      }
    ]
  }),
  "Instantiate new Hash::Layout instance"
);

my $target1 = {
    "*" => {
      "*" => {
        create_ts => 1
      },
      columns => {
        change_ts => {
          extra => 1
        }
      },
      isa => 1,
      zippy => {
        isa => 1
      },
    },
    Album => {
      "*" => {
        delete_ts => 1
      },
      relationships => 1
    },
    Artist => {
      constraints => {
        primary => 1
      },
      table_name => 'blah'
    }

};

is_deeply(
  $HL->clone->load(
    
    # maps as *:columns/change_ts.extra:
    'columns/change_ts.extra',
    
    # maps as *:*/create_ts
    'create_ts',
    
    # maps as Album:*/delete_ts:
    'Album:delete_ts',
    
    # maps as 'Album:relationships' instead of 'Album:*/elationships' 
    # because 'relationships' is a registered key of the second level:
    'Album:relationships',
    
    # maps as '*:isa' instead of '*:*/isa' because 'isa' is a  
    # registered key of the second level:
    'isa',
    
    # Still maps to '*:zippy/isa' - the registered key 'isa' on the second
    # layer does not interfere with deeper layers: 
    'zippy/isa',
    
    { 'Artist:table_name' => 'blah' },
    
    'Artist:constraints/primary'
    
  )->Data,
  $target1,
  "load values with registered keys"
);


done_testing;
