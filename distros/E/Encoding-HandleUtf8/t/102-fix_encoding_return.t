use strict;
use warnings FATAL => 'all';

use Test::More tests => 1 + 14;
use Test::NoWarnings;

############################################################################
# Prototypes.

sub fixtures_ue ();
sub fixtures_foo_ue_bar ();
sub fixtures_hashref ();
sub fixtures_arrayref ();
sub fixtures_arrays_of_hashrefs ();

############################################################################
# Use tests.

BEGIN {
  use_ok( 'Encoding::HandleUtf8', qw( fix_encoding_return ) );
}

############################################################################
# ue string tests.

subtest 'ue string input' => sub {
  plan tests => 2;
  my ( $utf8_input, $unicode_input, $utf8_orig, $unicode_orig ) = fixtures_ue;

  is(
    fix_encoding_return( 'input', $utf8_input ),
    $unicode_orig,
    q{ue string input UTF-8 > Unicode},
  );

  is(
    fix_encoding_return( 'input', $unicode_input ),
    $unicode_orig,
    q{ue string input Unicode > Unicode},
  );
};

subtest 'ue string output' => sub {
  plan tests => 2;
  my ( $utf8_input, $unicode_input, $utf8_orig, $unicode_orig ) = fixtures_ue;

  is(
    fix_encoding_return( 'output', $utf8_input ),
    $utf8_orig,
    q{ue string output UTF-8 > UTF-8},
  );

  is(
    fix_encoding_return( 'output', $unicode_input ),
    $utf8_orig,
    q{ue string output Unicode > UTF-8},
  );
};

############################################################################
# foo+ue+bar string tests.

subtest 'foo+ue+bar string input' => sub {
  plan tests => 2;
  my ( $utf8_input, $unicode_input, $utf8_orig, $unicode_orig ) = fixtures_foo_ue_bar;

  is(
    fix_encoding_return( 'input', $utf8_input ),
    $unicode_orig,
    q{foo+ue+bar string input UTF-8 > Unicode},
  );

  is(
    fix_encoding_return( 'input', $unicode_input ),
    $unicode_orig,
    q{foo+ue+bar string input Unicode > Unicode},
  );
};

subtest 'foo+ue+bar string output' => sub {
  plan tests => 2;
  my ( $utf8_input, $unicode_input, $utf8_orig, $unicode_orig ) = fixtures_foo_ue_bar;

  is(
    fix_encoding_return( 'output', $utf8_input ),
    $utf8_orig,
    q{foo+ue+bar string output UTF-8 > UTF-8},
  );

  is(
    fix_encoding_return( 'output', $unicode_input ),
    $utf8_orig,
    q{foo+ue+bar string output Unicode > UTF-8},
  );
};

############################################################################
# ue hash reference tests.

subtest 'ue hash reference input' => sub {
  plan tests => 2;
  {
    my ( $input, $utf8, $unicode ) = fixtures_hashref;
    is_deeply(
      fix_encoding_return( 'input', $input ),
      $unicode,
      q{ue hash reference input UTF-8 > Unicode},
    );
  }
  {
    my ( $input, $utf8, $unicode ) = fixtures_hashref;
    is_deeply(
      fix_encoding_return( 'input', $input ),
      $unicode,
      q{ue hash reference input Unicode > Unicode},
    );
  }
};

subtest 'ue hash reference output' => sub {
  plan tests => 2;
  {
    my ( $input, $utf8, $unicode ) = fixtures_hashref;
    is_deeply(
      fix_encoding_return( 'output', $input ),
      $utf8,
      q{ue hash reference output UTF-8 > UTF-8},
    );
  }
  {
    my ( $input, $utf8, $unicode ) = fixtures_hashref;
    is_deeply(
      fix_encoding_return( 'output', $input ),
      $utf8,
      q{ue hash reference output Unicode > UTF-8},
    );
  }
};

############################################################################
# ue array reference tests.

subtest 'ue array reference input' => sub {
  plan tests => 2;
  {
    my ( $input, $utf8, $unicode ) = fixtures_arrayref;
    is_deeply(
      fix_encoding_return( 'input', $input ),
      $unicode,
      q{ue array reference input UTF-8 > Unicode},
    );
  }
  {
    my ( $input, $utf8, $unicode ) = fixtures_arrayref;
    is_deeply(
      fix_encoding_return( 'input', $input ),
      $unicode,
      q{ue array reference input Unicode > Unicode},
    );
  }
};

subtest 'ue array reference output' => sub {
  plan tests => 2;
  {
    my ( $input, $utf8, $unicode ) = fixtures_hashref;
    is_deeply(
      fix_encoding_return( 'output', $input ),
      $utf8,
      q{ue array reference output UTF-8 > UTF-8},
    );
  }
  {
    my ( $input, $utf8, $unicode ) = fixtures_hashref;
    is_deeply(
      fix_encoding_return( 'output', $input ),
      $utf8,
      q{ue array reference output Unicode > UTF-8},
    );
  }
};

############################################################################
# ue array of hash references tests.

subtest 'ue array of hash references input' => sub {
  plan tests => 2;
  {
    my ( $input, $utf8, $unicode ) = fixtures_arrays_of_hashrefs;
    is_deeply(
      fix_encoding_return( 'input', $input ),
      $unicode,
      q{ue array of hash references input UTF-8 > Unicode},
    );
  }
  {
    my ( $input, $utf8, $unicode ) = fixtures_arrays_of_hashrefs;
    is_deeply(
      fix_encoding_return( 'input', $input ),
      $unicode,
      q{ue array of hash references input Unicode > Unicode},
    );
  }
};

subtest 'ue array of hash references output' => sub {
  plan tests => 2;
  {
    my ( $input, $utf8, $unicode ) = fixtures_arrays_of_hashrefs;
    is_deeply(
      fix_encoding_return( 'output', $input ),
      $utf8,
      q{ue array of hash references output UTF-8 > UTF-8},
    );
  }
  {
    my ( $input, $utf8, $unicode ) = fixtures_arrays_of_hashrefs;
    is_deeply(
      fix_encoding_return( 'output', $input ),
      $utf8,
      q{ue array of hash references output Unicode > UTF-8},
    );
  }
};

############################################################################
# multiple ue string tests.

subtest 'multiple ue string input' => sub {
  plan tests => 3;
  my ( $utf8_input, $unicode_input, $utf8_orig, $unicode_orig ) = fixtures_ue;

  is(
    fix_encoding_return( 'input', $utf8_input ),
    $unicode_orig,
    q{multiple ue string input run 1},
  );

  is(
    fix_encoding_return( 'input', $utf8_input ),
    $unicode_orig,
    q{multiple ue string input run 2},
  );

  is(
    fix_encoding_return( 'input', $utf8_input ),
    $unicode_orig,
    q{multiple ue string input run 3},
  );

};

subtest 'multiple ue string output' => sub {
  plan tests => 3;
  my ( $utf8_input, $unicode_input, $utf8_orig, $unicode_orig ) = fixtures_ue;

  is(
    fix_encoding_return( 'output', $unicode_input ),
    $utf8_orig,
    q{multiple ue string output run 1},
  );

  is(
    fix_encoding_return( 'output', $unicode_input ),
    $utf8_orig,
    q{multiple ue string output run 2},
  );

  is(
    fix_encoding_return( 'output', $unicode_input ),
    $utf8_orig,
    q{multiple ue string output run 3},
  );

};

############################################################################
# reference and return value tests.

subtest 'reference and return value' => sub {
  plan tests => 2;
  my ( $utf8_input, $unicode_input, $utf8_orig, $unicode_orig ) = fixtures_ue;

  my $foo = fix_encoding_return( 'input', $utf8_input );

  is(
    $foo,
    $unicode_orig,
    q{return},
  );

  is(
    $utf8_input,
    $utf8_orig,  # does NOT manipulate the original reference.
    q{reference},
  );

};

############################################################################
# error tests.


############################################################################
# Fixtures.

# latin small letter u with diaeresis.
sub fixtures_ue () {
  return "\xC3\xBC", "\xFC", "\xC3\xBC", "\xFC";
}

# foo + latin small letter u with diaeresis + bar.
sub fixtures_foo_ue_bar () {
  return "foo\xC3\xBCbar", "foo\xFCbar", "foo\xC3\xBCbar", "foo\xFCbar";
}

# hash reference with latin small letter u with diaeresis.
sub fixtures_hashref () {
  return { utf8 => "\xC3\xBC", unicode => "\xFC" }, { utf8 => "\xC3\xBC", unicode => "\xC3\xBC" },
    { utf8 => "\xFC", unicode => "\xFC" };
}

# array reference with latin small letter u with diaeresis.
sub fixtures_arrayref () {
  return [ "\xC3\xBC", "\xFC" ], [ "\xC3\xBC", "\xC3\xBC" ], [ "\xFC", "\xFC" ];
}

# array of hash references with latin small letter u with diaeresis.
sub fixtures_arrays_of_hashrefs () {
  return [ { utf8 => "\xC3\xBC", unicode => "\xFC" }, { utf8 => "\xC3\xBC", unicode => "\xFC" } ],
    [ { utf8 => "\xC3\xBC", unicode => "\xC3\xBC" }, { utf8 => "\xC3\xBC", unicode => "\xC3\xBC" } ],
    [ { utf8 => "\xFC",     unicode => "\xFC" },     { utf8 => "\xFC",     unicode => "\xFC" } ];
}

############################################################################
1;
