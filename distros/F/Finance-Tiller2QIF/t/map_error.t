use strict;
use warnings;
use utf8;
use warnings FATAL => 'utf8';
use open ':std', ':encoding(UTF-8)';
use Test2::V0;
use Test2::Bundle::More;
use Test2::Tools::Exception qw/dies/;
use Path::Tiny;
use Finance::Tiller2QIF::Map;

require './t/TestHelper.pm';

my $tmpdir = "t/tmp";
mkdir $tmpdir unless -d $tmpdir;

subtest 'account filter on default line dies' => sub {
  my $mapfile = uniqfile('default_acct', 'map');
  freshmap($mapfile,
    '[Checking] default | Expenses:Groceries',
  );
  ok(dies { Finance::Tiller2QIF::Map::Map({db_path => 'dummy.db', mapfile => $mapfile}) },
    'Account filter on default line triggers error');
};

subtest 'default line missing destination dies' => sub {
  my $mapfile = uniqfile('default_nodest', 'map');
  freshmap($mapfile,
    'default | ',
  );
  ok(dies { Finance::Tiller2QIF::Map::Map({db_path => 'dummy.db', mapfile => $mapfile}) },
    'Default line missing destination triggers error');
};

subtest 'unknown field dies' => sub {
  my $mapfile = uniqfile('unknown_field', 'map');
  freshmap($mapfile,
    'notafield | foo | Expenses:Other',
    'default | source',
  );
  ok(dies { Finance::Tiller2QIF::Map::Map({db_path => 'dummy.db', mapfile => $mapfile}) },
    'Unknown field triggers error');
};

subtest 'missing pattern dies' => sub {
  my $mapfile = uniqfile('missing_pattern', 'map');
  freshmap($mapfile,
    'payee | | Expenses:Other',
    'default | source',
  );
  ok(dies { Finance::Tiller2QIF::Map::Map({db_path => 'dummy.db', mapfile => $mapfile}) },
    'Missing pattern triggers error');
};

subtest 'missing destination dies' => sub {
  my $mapfile = uniqfile('missing_dest', 'map');
  freshmap($mapfile,
    'payee | foo | ',
    'default | source',
  );
  ok(dies { Finance::Tiller2QIF::Map::Map({db_path => 'dummy.db', mapfile => $mapfile}) },
    'Missing destination triggers error');
};

subtest 'invalid account filter regex dies' => sub {
  my $mapfile = uniqfile('bad_acct_regex', 'map');
  freshmap($mapfile,
    '[foo(] payee | bar | Expenses:Other',
    'default | source',
  );
  ok(dies { Finance::Tiller2QIF::Map::Map({db_path => 'dummy.db', mapfile => $mapfile}) },
    'Invalid account filter regex triggers error');
};

subtest 'invalid pattern regex dies' => sub {
  my $mapfile = uniqfile('bad_pat_regex', 'map');
  freshmap($mapfile,
    'payee | foo( | Expenses:Other',
    'default | source',
  );
  ok(dies { Finance::Tiller2QIF::Map::Map({db_path => 'dummy.db', mapfile => $mapfile}) },
    'Invalid pattern regex triggers error');
};

subtest 'bare alternation without slash-quoting dies' => sub {
  my $mapfile = uniqfile('bare_alt', 'map');
  freshmap($mapfile,
    'payee | Foo|Bar | Expenses:Other',
    'default | source',
  );
  ok(dies { Finance::Tiller2QIF::Map::Map({db_path => 'dummy.db', mapfile => $mapfile}) },
    'Bare pipe alternation without slash-quoting triggers error');
};

done_testing();
unlink glob "$tmpdir/maperr_*" if test_pass();
