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
      { name => 'source', delimiter => ':' },
      { name => 'column', delimiter => '/' }, 
      { name => 'info' }, 
    ]
  }),
  "Instantiate new Hash::Layout instance"
);



sub lookups1 {
  my $HL1 = shift;

  is(
    $HL1->lookup('Film:rental_rate/foobar'),
    'Film rental_rate foobar',
    "lookup (1)"
  );

  is(
    $HL1->lookup('Album:id/foobar'),
    'default foobar',
    "lookup (2)"
  );

  is(
    $HL1->lookup('Film:id/foobar'),
    'Film foobar',
    "lookup (3)"
  );

  is(
    $HL1->lookup('Album:rental_rate/foobar'),
    'rental_rate foobar',
    "lookup (4)"
  );
  
 is(
    $HL1->lookup('Film:rental_rate'),
    undef,
    "lookup (5)"
  );
  
  is_deeply(
    $HL1->lookup_path('Film','rental_rate'),
    { foobar => "Film rental_rate foobar" },
    "lookup_path (6)"
  );
  
  is_deeply(
    $HL1->lookup('Film:rental_rate/'),
    { foobar => "Film rental_rate foobar" },
    "lookup (7)"
  );
  
  is(
    $HL1->lookup('Film'),
    undef,
    "lookup (8)"
  );
  
  is_deeply(
    $HL1->get_path('Film'),
    {
      "*" => {
        foobar => "Film foobar"
      },
      rental_rate => {
        foobar => "Film rental_rate foobar"
      }
    },
    "get_path (9)"
  );
  
  is_deeply(
    $HL1->lookup_path('Film'),
    {
      "*" => {
        foobar => "Film foobar"
      },
      rental_rate => {
        foobar => "Film rental_rate foobar"
      }
    },
    "lookup_path (10)"
  );
  
  is_deeply(
    $HL1->lookup('Film:'),
    {
      "*" => {
        foobar => "Film foobar"
      },
      rental_rate => {
        foobar => "Film rental_rate foobar"
      }
    },
    "lookup (11)"
  );
   
}

ok(
  my $HL1 = $HL->coerce(
    { '*/foobar'                => 'default foobar' },
    { 'rental_rate/foobar'      => 'rental_rate foobar' },
    { 'Film:foobar'             => 'Film foobar' },
    { 'Film:rental_rate/foobar' => 'Film rental_rate foobar' },
  ),
  "New via coerce()"
);

&lookups1($HL1);

ok(
  $HL1->lookup_mode('fallback'),
  "Change lookup_mode from default 'merge' to 'fallback'"
);

# 'fallback' is the same as 'merge' for scalar values:
&lookups1($HL1);

# will be used further down...
my $coercer = $HL1->coercer;

ok(
  $HL1->lookup_mode('get'),
  "Change lookup_mode to 'get'"
);

is(
  $HL1->lookup('Album:rental_rate/foobar'),
  undef,
  "lookup (a1)"
);

is(
  $HL1->lookup('rental_rate/foobar'),
  'rental_rate foobar',
  "lookup (a2)"
);



ok(
  my $HL2 = $HL1->coercer->($HL)->clone->reset->clone->coerce(
    { '*/foobar'                => 'default foobar' },
    { 'rental_rate/foobar'      => 'rental_rate foobar' },
  )->clone->load(
    { 'Film:foobar'             => 'Film foobar' },
    { 'Film:rental_rate/foobar' => 'Film rental_rate foobar' },
  )->clone->load(),
  "New via complex chaining clone/reset/coerce/coercer/load"
);

&lookups1($HL2);

ok(
  my $HL3 = $coercer->(
    { '*/foobar'                => 'default foobar' },
    { 'rental_rate/foobar'      => 'rental_rate foobar' },
    { 'Film:foobar'             => 'Film foobar' },
    { 'Film:rental_rate/foobar' => 'Film rental_rate foobar' },
  ),
  "New via saved coercer ref"
);

&lookups1($HL3);


sub lookups4 {
  my $HL = shift;
  is(
    $HL->lookup('*/*/Kingdom/*/*/Phylum/Class'),
    'Mammalia',
    "lookup (b1)"
  );

  is(
    $HL->lookup('*/*/Kingdom/*/Blah/Phylum/Class'),
    'Mammalia',
    "lookup (b2)"
  );

  is(
    $HL->lookup('*/*/Apple/*/Blah/Phylum/Class'),
    "default, default value",
    "lookup (b3)"
  );

  is(
    $HL->lookup('fish'),
    "default, default value",
    "lookup (b4)"
  );
}

ok(
  my $HL4 = Hash::Layout->new({
    levels => 15
  }),
  "Instantiate new Hash::Layout instance with 15 default levels"
);

ok(
  $HL4->load({
    '*/*'                           => 'default, default value',
    '*/*/Kingdom/*/*/Phylum/Class'  => 'Mammalia' 
  }),
  "Load values in 15-level layout"
);

is_deeply(
  $HL4->Data,
  {
    "*" => {
      "*" => {
        "*" => {
          "*" => {
            "*" => {
              "*" => {
                "*" => {
                  "*" => {
                    "*" => {
                      "*" => {
                        "*" => {
                          "*" => {
                            "*" => {
                              "*" => {
                                "*" => "default, default value"
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        Kingdom => {
          "*" => {
            "*" => {
              Phylum => {
                "*" => {
                  "*" => {
                    "*" => {
                      "*" => {
                        "*" => {
                          "*" => {
                            "*" => {
                              "*" => {
                                Class => "Mammalia"
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  },
  "Expected 15-level data"
);

is_deeply(
  $HL4->_def_key_bitmasks,
  {
    28158 => 1,
    32767 => 1
  },
  'Expected _def_key_bitmasks for 15-level data'
);

&lookups4($HL4);

ok(
  my $HL5 = Hash::Layout->new({
    levels => 30
  }),
  "Instantiate new Hash::Layout instance with 30 default levels"
);

ok(
  $HL5->load({
    '*/*'                           => 'default, default value',
    '*/*/Kingdom/*/*/Phylum/Class'  => 'Mammalia' 
  }),
  "Load values in 30-level layout"
);

is_deeply(
  $HL5->_def_key_bitmasks,
  {
    1073741823 => 1,
    922746878  => 1
  },
  'Expected _def_key_bitmasks for 30-level data'
);

&lookups4($HL5);

ok(
  $HL5->set( foo => 'blah' ),
  "set()"
);

is(
  $HL5->get('foo'),
  'blah',
  'get value which was just set'
);

is(
  $HL5->set( apple => 'banana' )->get('apple'),
  'banana',
  'chained set/get in one call'
);

is(
  $HL5->set( 'fruit/apple' => 'grape' )->get('fruit/apple'),
  'grape',
  'chained set/get in one call (composite key)'
);


is_deeply(
  $HL->coerce('*:lvl2_item/')->lookup_path('SomeLevelOneItem'),
  { lvl2_item => 1 },
  'Lookup non-existant key with default (1)'
);

is_deeply(
  $HL->coerce('lvl3_item')->lookup_path('SomeLevelOneItem'),
  { '*' => { lvl3_item => 1 }},
  'Lookup non-existant key with default (2)'
);

is_deeply(
  $HL->coerce('lvl3_item')->lookup_path('SomeLevelOneItem','SomeLevelTwoItem'),
  { lvl3_item => 1 },
  'Lookup non-existant key with default (3)'
);


done_testing;
