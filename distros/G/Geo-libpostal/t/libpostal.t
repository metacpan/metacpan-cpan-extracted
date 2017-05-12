#!perl
use strict;
use warnings;
use utf8;
use Test::More;
use Test::Fatal 'exception';

use Geo::libpostal ':all';
pass 'loaded Geo::libpostal';

subtest expand_address => sub {
  ok expand_address('120 E 96th St New York'), 'expand address';
  ok expand_address('The Book Club 100-106 Leonard St Shoreditch London EC2A 4RH, United Kingdom'), 'expand UK address';

  # test boolean options
  ok expand_address('120 E 96th St New York',
    latin_ascii => 1,
    transliterate => 1,
    strip_accents => 1,
    decompose => 1,
    lowercase => 1,
    trim_string => 1,
    drop_parentheticals => 1,
    replace_numeric_hyphens => 1,
    delete_numeric_hyphens => 1,
    split_alpha_from_numeric => 1,
    replace_word_hyphens => 1,
    delete_word_hyphens => 1,
    delete_final_periods => 1,
    delete_acronym_periods => 1,
    drop_english_possessives => 1,
    delete_apostrophes => 1,
    expand_numex => 1,
    roman_numerals => 1,
  ), 'expand address all options true';

  ok expand_address('120 E 96th St New York',
    latin_ascii => 0,
    transliterate => 0,
    strip_accents => 0,
    decompose => 0,
    #lowercase => 0, segfault on older libpostals https://github.com/openvenues/libpostal/issues/79
    trim_string => 0,
    drop_parentheticals => 0,
    replace_numeric_hyphens => 0,
    delete_numeric_hyphens => 0,
    split_alpha_from_numeric => 0,
    replace_word_hyphens => 0,
    delete_word_hyphens => 0,
    delete_final_periods => 0,
    delete_acronym_periods => 0,
    drop_english_possessives => 0,
    delete_apostrophes => 0,
    expand_numex => 0,
    roman_numerals => 0,
  ), 'expand address all options false';

  ok expand_address('120 E 96th St New York',
    latin_ascii => undef,
    transliterate => undef,
    strip_accents => undef,
    decompose => undef,
    lowercase => undef, # segfault on older libpostals https://github.com/openvenues/libpostal/issues/79
    trim_string => undef,
    drop_parentheticals => undef,
    replace_numeric_hyphens => undef,
    delete_numeric_hyphens => undef,
    split_alpha_from_numeric => undef,
    replace_word_hyphens => undef,
    delete_word_hyphens => undef,
    delete_final_periods => undef,
    delete_acronym_periods => undef,
    drop_english_possessives => undef,
    delete_apostrophes => undef,
    expand_numex => undef,
    roman_numerals => undef,
  ), 'expand address all options false (undef)';

  ok expand_address('120 E 96th St New York',
    lowercase => 0
  ), 'expand address lowercase false';

  # tests for components
  ok expand_address('120 E 96th St New York',
    components => undef
  ),'expand address components (undef)';

  ok expand_address('120 E 96th St New York',
    components => 0
  ),'expand address components (0)';

  ok expand_address('120 E 96th St New York',
    components => $ADDRESS_NAME | $ADDRESS_HOUSE_NUMBER | $ADDRESS_STREET | $ADDRESS_UNIT
  ),'expand address components (default)';

  ok expand_address('120 E 96th St New York',
    components => $ADDRESS_ALL
  ),'expand address components (all)';

  ok expand_address('120 E 96th St New York',
    components => $ADDRESS_POSTAL_CODE
  ),'expand address components (postal_code)';

  ok expand_address('120 E 96th St New York',
    components => $ADDRESS_LOCALITY
  ),'expand address components (locality)';

  ok expand_address('120 E 96th St New York',
    components => $ADDRESS_NAME | $ADDRESS_HOUSE_NUMBER | $ADDRESS_STREET | $ADDRESS_UNIT | $ADDRESS_POSTAL_CODE | $ADDRESS_COUNTRY
  ),'expand address components (default plus postal_code, country)';

  ok expand_address('120 E 96th St New York',
    components => $ADDRESS_ADMIN1 | $ADDRESS_ADMIN2 | $ADDRESS_ADMIN3 | $ADDRESS_ADMIN4 | $ADDRESS_ADMIN_OTHER
  ),'expand address components (admins)';

  ok expand_address('120 E 96th St New York',
    components => 1 << 32 # too big
  ),'expand address components (32bit)';

  # tests for languages
  ok expand_address('120 E 96th St New York', languages => [qw(en fr)]), 'expand address language (en, fr)';
  ok expand_address('120 E 96th St New York', languages => ['es']), 'expand address language (es)';
};

# NB these options are ignored by libpostal!
subtest parse_address => sub {
  ok parse_address('120 E 96th St New York'), 'parse address';

  # languages
  ok parse_address('120 E 96th St New York', language => undef),
    'parse address undef language';
  ok parse_address('120 E 96th St New York', language => 'en'),
    'parse address en language';
  ok parse_address('C/ Ocho, P.I. 4', language => 'es'),
    'parse address es language';
  ok parse_address('Quatre vingt douze R. de l\'Église', language => 'fr'),
    'parse address fr language';

  # countries
  ok parse_address('120 E 96th St New York', country => undef),
    'parse address undef country';
  ok parse_address('120 E 96th St New York', country => 'US'),
    'parse address US country';
  ok parse_address('The Book Club 100-106 Leonard St Shoreditch London EC2A 4RH, United Kingdom', country => 'GB'),
    'parse address GB country';
  ok parse_address('C/ Ocho, P.I. 4', country => 'ES'),
    'parse address ES country';
  ok parse_address('Quatre vingt douze R. de l\'Église', country => 'FR'),
    'parse address FR country';

  # both
  ok parse_address(
    '120 E 96th St New York',
    language => undef,
    country  => undef,
  ), 'parse address undef';

  ok my %address = parse_address(
    '120 E 96th St New York 11212',
    language => 'en',
    country  => 'US',
  ), 'parse address undef';

  ok parse_address(
    'The Book Club 100-106 Leonard St Shoreditch London EC2A 4RH, United Kingdom',
    country   => 'FR',
    language  => 'fr',
  ),'parse address GB en';

  ok parse_address(
    'C/ Ocho, P.I. 4',
    country   => 'ES',
    language  => 'es',
  ), 'parse address ES es';

  ok parse_address(
    'Quatre vingt douze R. de l\'Église',
    language => 'fr',
    country  => 'FR',
  ),'parse address fr FR';
};

subtest exceptions => sub {
  ok exception { expand_address(undef) }, 'expand_address() requires an address (undef)';
  ok exception { expand_address('') },    'expand_address() requires an address (empty)';
  ok exception { parse_address(undef)  }, 'parse_address() requires an address (undef)';
  ok exception { parse_address('')  },    'parse_address() requires an address (empty)';

  ok exception { expand_address('foo', undef)  }, 'expand_address() odd number of options (1)';
  ok exception { expand_address('foo', 1,2,3)  }, 'expand_address() odd number of options (3)';
  ok exception { parse_address('foo', undef)  },  'parse_address() odd number of options (1)';
  ok exception { parse_address('foo', 1,2,3)  },  'parse_address() odd number of options (3)';

  ok exception { expand_address('foo', undef, 'bar')  }, 'expand_address() option name invalid (undef)';
  ok exception { expand_address('foo', 'bar', 'dah')  }, 'expand_address() option name invalid (unrecog)';
  ok exception { expand_address('foo', '',    'dah')  }, 'expand_address() option name invalid (empty)';
  ok exception { expand_address('foo', 1,     'dah')  }, 'expand_address() option name invalid (type IV)';
  ok exception { expand_address('foo', sub{}, 'dah')  }, 'expand_address() option name invalid (type CV)';
  ok exception { expand_address('foo', \my $v,'dah')  }, 'expand_address() option name invalid (type RV)';
  ok exception { parse_address('foo', undef, 'bar')  },  'parse_address() option name invalid (undef)';
  ok exception { parse_address('foo', 'bar', 'dah')  },  'parse_address() option name invalid (unrecog)';
  ok exception { parse_address('foo', '',    'dah')  },  'parse_address() option name invalid (empty)';
  ok exception { parse_address('foo', 1,     'dah')  },  'parse_address() option name invalid (type IV)';
  ok exception { parse_address('foo', sub{}, 'dah')  },  'parse_address() option name invalid (type CV)';
  ok exception { parse_address('foo', \my $v,'dah')  },  'parse_address() option name invalid (type RV)';
};

subtest teardown => sub {
  ok !defined Geo::libpostal::_teardown, '_teardown()';
  ok !defined Geo::libpostal::_teardown, '_teardown() twice doesn\'t error';
  ok parse_address('120 E 96th St New York'),  'parse address works after _teardown()';
  ok expand_address('120 E 96th St New York'), 'expand address works after _teardown()';
};

done_testing();
