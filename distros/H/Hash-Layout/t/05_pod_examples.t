# -*- perl -*-

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;

use Hash::Layout;

# Create new Hash::Layout object with 3 levels and unique delimiters:
my $HL = Hash::Layout->new({
 levels => [
   { delimiter => ':' },
   { delimiter => '/' }, 
   {}, # <-- last level never has a delimiter
 ]
});

# load using actual hash structure:
$HL->load({
  '*' => {
    '*' => {
      foo_rule => 'always deny',
      blah     => 'thing'
    },
    NewYork => {
      foo_rule => 'prompt'
    }
  }
});

# load using composite keys:
$HL->load({
  'Office:NewYork/foo_rule' => 'allow',
  'Store:*/foo_rule'        => 'other',
  'Store:London/blah'       => 'purple'
});

# load composite keys w/o values (uses default_value '1'):
$HL->load(qw/baz:bool_key flag01/);


# get a copy of the hash data:
my $hash = $HL->Data;

is_deeply(
  $hash,
  {
    "*" => {
      "*" => {
        blah => "thing",
        flag01 => 1,
        foo_rule => "always deny"
      },
      NewYork => {
        foo_rule => "prompt"
      }
    },
    Office => {
      NewYork => {
        foo_rule => "allow"
      }
    },
    Store => {
      "*" => {
        foo_rule => "other"
      },
      London => {
        blah => "purple"
      }
    },
    baz => {
      "*" => {
        bool_key => 1
      }
    }
  },
  "Data"
);

 # lookup values by composite keys:
is($HL->lookup('*:*/foo_rule')              => 'always deny'         );
is($HL->lookup('foo_rule')                  => 'always deny'         );
is($HL->lookup('ABC:XYZ/foo_rule')          => 'always deny'         );
is($HL->lookup('Lima/foo_rule')             => 'always deny'         );
is($HL->lookup('NewYork/foo_rule')          => 'prompt'              );
is($HL->lookup('Office:NewYork/foo_rule')   => 'allow'               );
is($HL->lookup('Store:foo_rule')            => 'other'               );
is($HL->lookup('baz:Anything/bool_key')     => 1                     );

# lookup values by full/absolute paths:
is($HL->lookup_path(qw/ABC XYZ foo_rule/)   => 'always deny'         );
is($HL->lookup_path(qw/Store * foo_rule/)   => 'other'               );


done_testing;
