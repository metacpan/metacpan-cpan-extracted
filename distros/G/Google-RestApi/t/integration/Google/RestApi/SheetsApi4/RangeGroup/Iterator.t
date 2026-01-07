use Test::Integration::Setup;

use Test::Most tests => 21;

use aliased "Google::RestApi::SheetsApi4::RangeGroup";
use aliased "Google::RestApi::SheetsApi4::RangeGroup::Iterator";

# use Carp::Always;
init_logger;

delete_all_spreadsheets(sheets_api());

my $spreadsheet = spreadsheet();
my $ws0 = $spreadsheet->open_worksheet(id => 0);

my @values = (
  [ 1, 2, 3],
  [ 4, 5, 6],
  [ 7, 8, 9],
);
$ws0->range("A1:C3")->values(values => \@values);

my $col = $ws0->range_col(1);
my $row = $ws0->range_row(1);
my $range_group = $spreadsheet->range_group($col, $row);

defaults();
by();
from();
to();

sub defaults {
  my ($i, $rg);
  isa_ok $i = $range_group->iterator(), Iterator, "Iterator creation";

  isa_ok $rg = $i->next(), RangeGroup, "First iteration";
  is_deeply $rg->values(), [1, 1], "First iteration should be [1, 1]";

  isa_ok $rg = $i->next(), RangeGroup, "Second iteration";
  is_deeply $rg->values(), [4, 2], "Second iteration should be [4, 2]";

  isa_ok $rg = $i->next(), RangeGroup, "Third iteration";
  is_deeply $rg->values(), [7, 3], "Third iteration should be [7, 3]";

  isa_ok $rg = $i->next(), RangeGroup, "Forth iteration";
  is_deeply $rg->values(), [undef, undef], "Forth iteration should be undef";
  return;
}

sub by {
  my ($i, $rg);
  isa_ok $i = $range_group->iterator(by => 2), Iterator, "'By' iterator";
  $rg = $i->next() for (1..2);
  is_deeply $rg->values(), [7, 3], "Second 'by' iteration should be [7, 3]";
  isa_ok $rg = $i->next(), RangeGroup, "Third 'by' iteration";
  is_deeply $rg->values(), [undef, undef], "Third 'by' iteration should be undef";
  return;
}

sub from {
  my ($i, $rg);
  isa_ok $i = $range_group->iterator(from => 2), Iterator, "'From' iterator creation";
  $rg = $i->next();
  is_deeply $rg->values(), [7, 3], "Second 'by' iteration should be [7, 3]";
  isa_ok $rg = $i->next(), RangeGroup, "Third 'by' iteration";
  is_deeply $rg->values(), [undef, undef], "Third 'by' iteration should be undef";
  return;
}

sub to {
  my ($i, $rg);
  isa_ok $i = $range_group->iterator(to => 1), Iterator, "'To' iterator creation";
  isa_ok $rg = $i->next(), RangeGroup, "First 'to' iteration";
  is_deeply $rg->values(), [1, 1], "First 'to' iteration should be [1, 1]";
  is $rg = $i->next(), undef, "Second 'to' iteration should be undef";
  return;
}

delete_all_spreadsheets(sheets_api());

# use YAML::Any qw(Dump);
# warn Dump($spreadsheet->stats());
