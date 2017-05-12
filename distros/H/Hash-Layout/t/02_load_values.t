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

my $target1 = {
  "*" => {
    "*" => {
      column_info => 1
    }
  },
  Album => {
    "*" => {
      column_info => {
        blah => 1
      }
    }
  },
  Film => {
    id => {
      relationship_info => 1
    },
    rental_rate => {
      column_info => {
        foo => {
          baz => 2,
          blah => 1
        }
      }
    }
  }
};

my $target1_level_keys = {
  0 => {
    "*" => 1,
    Album => 1,
    Film => 1
  },
  1 => {
    "*" => 1,
    id => 1,
    rental_rate => 1
  },
  2 => {
    column_info => 1,
    relationship_info => 1
  }
};

ok(
  my $HL1 = $HL->clone->load(
    'column_info',
    'Album:*/column_info.blah',
    'Film:id/relationship_info',
    'Film:rental_rate/column_info.foo.blah',
    { 'Film:rental_rate/column_info.foo.baz' => 2 }
  ),
  "New via clone->load()"
);

is_deeply(
  $HL1->Data,
  $target1,
  "load values - target1 (1) - Data"
);

is_deeply(
  $HL1->_all_level_keys,
  $target1_level_keys,
  "load values - target1 (1) - _all_level_keys"
);

is_deeply(
  {
    0 => $HL1->level_keys(0),
    1 => $HL1->level_keys(1),
    2 => $HL1->level_keys(2),
  },
  $target1_level_keys,
  "load values - target1 (1) - level_keys()"
);


is_deeply(
  $HL->clone->load(
  'Album:column_info.blah',
  {
    "*" => {
      "*/column_info" => 1
    },
    'Film:id/' => {
      relationship_info => 1
    },
    Film => {
      rental_rate => {
        column_info => {
          foo => {
            baz => 2,
            blah => 1
          }
        }
      }
    }
  }
  )->Data,
  $target1,
  "load values - target1 (2)"
);

ok(
  $HL1->reset->load(
    'Album:column_info.blah',
    {
      "*" => {
        "*/column_info" => 1
      },
      'Film:id/' => {
        relationship_info => 1
      },
      Film => {
        rental_rate => {
          column_info => {
            foo => {
              baz => 2,
              blah => 1
            }
          }
        }
      }
    }
  ),
  "reset->load() same target data via different structure"
);

is_deeply(
  $HL1->Data,
  $target1,
  "load values - target1 (2) - Data"
);

is_deeply(
  $HL1->_all_level_keys,
  $target1_level_keys,
  "load values - target1 (2) - _all_level_keys"
);

is_deeply(
  {
    0 => $HL1->level_keys(0),
    1 => $HL1->level_keys(1),
    2 => $HL1->level_keys(2),
  },
  $target1_level_keys,
  "load values - target1 (2) - level_keys()"
);


is_deeply(
  $HL->clone->load(
  { 'Album:*' => { 'column_info.blah' => 1 } },
  {
    "*" => {
      "*/column_info" => 1
    },
    'Film:id' => { #<-- trailing '/' not needed
      relationship_info => 1
    },
    Film => {
      'rental_rate/column_info' => {
        foo => {
          baz => 2,
          blah => 1
        }
      }
    }
  }
  )->Data,
  $target1,
  "load values - target1 (3)"
);

ok(
  my $HL2 = $HL1->reset->clone->load(
    { 'Album:*' => { 'column_info.blah' => 1 } },
    {
      "*" => {
        "*/column_info" => 1
      },
      'Film:id' => { #<-- trailing '/' not needed
        relationship_info => 1
      },
      Film => {
        'rental_rate/column_info' => {
          foo => {
            baz => 2,
            blah => 1
          }
        }
      }
    }
  ),
  "New via reset->clone->load()"
);


is_deeply(
  $HL2->Data,
  $target1,
  "load values - target1 (3) - Data"
);

is_deeply(
  $HL2->_all_level_keys,
  $target1_level_keys,
  "load values - target1 (3) - _all_level_keys"
);

is_deeply(
  {
    0 => $HL2->level_keys(0),
    1 => $HL2->level_keys(1),
    2 => $HL2->level_keys(2),
  },
  $target1_level_keys,
  "load values - target1 (3) - level_keys()"
);


is_deeply(
  [
    scalar $HL2->delete_path('Album'),
    $HL2->Data
  ],
  [
    {
      "*" => {
        column_info => {
          blah => 1
        }
      }
    },
    {
      "*" => {
        "*" => {
          column_info => 1
        }
      },
      Film => {
        id => {
          relationship_info => 1
        },
        rental_rate => {
          column_info => {
            foo => {
              baz => 2,
              blah => 1
            }
          }
        }
      }
    }
  ],
  'delete_path (1)'
);

is_deeply(
  [
    scalar $HL2->delete('baz'),
    $HL2->Data
  ],
  [
    undef,
    {
      "*" => {
        "*" => {
          column_info => 1
        }
      },
      Film => {
        id => {
          relationship_info => 1
        },
        rental_rate => {
          column_info => {
            foo => {
              baz => 2,
              blah => 1
            }
          }
        }
      }
    }
  ],
  'delete (2) - deleted nothing'
);

is_deeply(
  [
    scalar $HL2->delete('column_info'),
    $HL2->Data
  ],
  [
    1,
    {
      "*" => {
        "*" => {}
      },
      Film => {
        id => {
          relationship_info => 1
        },
        rental_rate => {
          column_info => {
            foo => {
              baz => 2,
              blah => 1
            }
          }
        }
      }
    }
  ],
  'delete (3)'
);

is_deeply(
  [
    scalar $HL2->delete('Film:*/column_info.foo.baz'),
    $HL2->Data
  ],
  [
    undef,
    {
      "*" => {
        "*" => {}
      },
      Film => {
        id => {
          relationship_info => 1
        },
        rental_rate => {
          column_info => {
            foo => {
              baz => 2,
              blah => 1
            }
          }
        }
      }
    }
  ],
  'delete (4) - deleted nothing'
);

is_deeply(
  [
    scalar $HL2->delete('Film:rental_rate/column_info.foo.baz'),
    $HL2->Data
  ],
  [
    2,
    {
      "*" => {
        "*" => {}
      },
      Film => {
        id => {
          relationship_info => 1
        },
        rental_rate => {
          column_info => {
            foo => {
              blah => 1
            }
          }
        }
      }
    }
  ],
  'delete (5)'
);

is_deeply(
  [
    scalar $HL2->delete_path(qw(Film rental_rate)),
    $HL2->Data
  ],
  [
    {
      column_info => {
        foo => {
          blah => 1
        }
      }
    },
    {
      "*" => {
        "*" => {}
      },
      Film => {
        id => {
          relationship_info => 1
        },
      }
    }
  ],
  'delete_path (6)'
);

done_testing;
