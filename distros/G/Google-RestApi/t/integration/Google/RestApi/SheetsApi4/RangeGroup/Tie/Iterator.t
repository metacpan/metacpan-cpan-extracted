# for some (*&^ing reason can't use is_deeply or cmp_deeply on tied hashes
# (at least here). just get "does not exist" when looking for a hash key
# value. the tied hash can be copied to a normal hash and compared.
# is_deeply_tied is in utils.

use Test::Integration::Setup;

use Test::Most tests => 14;

use aliased "Google::RestApi::SheetsApi4::Range::Cell";
use aliased "Google::RestApi::SheetsApi4::Range::Row";
use aliased "Google::RestApi::SheetsApi4::RangeGroup::Tie::Iterator";

# use Carp::Always;
# init_logger($DEBUG);

delete_all_spreadsheets(sheets_api());

my $spreadsheet = spreadsheet();
my $ws0 = $spreadsheet->open_worksheet(id => 0);

my @values = (
  [ '',        'Freddie', 'Iggy' ],
  [ 'Mercury', 1,         2      ],
  [ 'Pop',     3,         4      ],
);
$ws0->range("A1:C3")->values(values => \@values);

$ws0->enable_header_row();
$ws0->enable_header_col("I really want to do this");

cols_read();
rows_read();
cols_write();
rows_write();

sub cols_read {
  my $cols = $ws0->tie_cols(freddie => 'Freddie', iggy => 'Iggy');
  isa_ok my $i = tied(%$cols)->iterator(), Iterator, "Tied row iterator cols_read";

  is_deeply_tied my $row = $i->next(), { freddie => 1, iggy => 2 }, "Check first row iterator hash values";
  is_deeply_tied $row = $i->next(), { freddie => 3, iggy => 4 }, "Check second row iterator hash values";
  is_deeply_tied $row = $i->next(), { freddie => undef, iggy => undef }, "Check third row iterator hash values";

  return;
}

sub cols_write {
  my $cols = $ws0->tie_cols(freddie => 'Freddie', iggy => 'Iggy');
  isa_ok my $i = tied(%$cols)->iterator(), Iterator, "Tied row iterator cols_write";

  my $row = $i->next();
  $row->{freddie} = 10;
  $row->{iggy} = 20;
  # since this is hash based, order of values is unpredictable.
  is_array my $x = tied(%$row)->submit_values(), "Submitting row values";
  is_deeply $ws0->row(2), ['Mercury', 10, 20], "Updated row values should be set";

  return;
}

sub rows_read {
  my $rows = $ws0->tie_rows(mercury => 'Mercury', pop => 'Pop');
  isa_ok my $i = tied(%$rows)->iterator(), Iterator, "Tied col iterator rows_read";

  is_deeply_tied my $col = $i->next(), { mercury => 1, pop => 3 }, "Check first col iterator hash values";
  is_deeply_tied $col = $i->next(), { mercury => 2, pop => 4 }, "Check second col iterator hash values";
  is_deeply_tied $col = $i->next(), { mercury => undef, pop => undef }, "Check third col iterator hash values";

  return;
}

sub rows_write {
  my $rows = $ws0->tie_rows(mercury => 'Mercury', pop => 'Pop');
  isa_ok my $i = tied(%$rows)->iterator(), Iterator, "Tied col iterator rows_write";

  my $col = $i->next();
  $col->{mercury} = 30;
  $col->{pop} = 40;
  # since this is hash based, order of values is unpredictable.
  is_array tied(%$col)->submit_values(), "Submitting col values";
  is_deeply $ws0->col(2), ['Freddie', 30, 40], "Updated col values should be set";

  return;
}

delete_all_spreadsheets(sheets_api());

# use YAML::Any qw(Dump);
# warn Dump($spreadsheet->stats());
