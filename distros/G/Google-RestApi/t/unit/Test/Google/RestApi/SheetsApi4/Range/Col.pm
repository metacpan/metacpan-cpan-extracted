package Test::Google::RestApi::SheetsApi4::Range::Col;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Range::Col';

use parent qw(Test::Google::RestApi::SheetsApi4::Range::Base);

my $sheet = "'Sheet1'";

init_logger;

sub range : Tests(16) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet;

  is $ws0->range_col("A:A")->range(),     "$sheet!A:A", "A:A should be A:A";
  is $ws0->range_col(['A'])->range(),     "$sheet!A:A", "['A'] should be A:A";
  is $ws0->range_col(['1'])->range(),     "$sheet!A:A", "['1'] should be A:A";
  is $ws0->range_col([['A']])->range(),   "$sheet!A:A", "[['A']] should be A:A";
  is $ws0->range_col([['1']])->range(),   "$sheet!A:A", "[['1']] should be A:A";
  is $ws0->range_col({col => 'A'})->range(),      "$sheet!A:A", "{col => 'A'} should be A:A";
  is $ws0->range_col({col => '1'})->range(),      "$sheet!A:A", "{col => '1'} should be A:A";
  is $ws0->range_col([{col => 'A'}])->range(),    "$sheet!A:A", "[{col => 'A'}] should be A:A";
  is $ws0->range_col([{col => '1'}])->range(),    "$sheet!A:A", "[{col => '1'}] should be A:A";
  is $ws0->range_col([['A', 5], ['A']])->range(), "$sheet!A5:A", "[['A', 5], ['A']] should be A5:A";
  is $ws0->range_col([{col => 'A', row => 5}, {col => 'A'}])->range(), "$sheet!A5:A", "[{col => 'A', row => 5}, {col => 'A'}] should be A5:A";
  is $ws0->range_col("AA10:AA11")->range(), "$sheet!AA10:AA11", "AA10:AA11 should be AA10:AA11";
  is $ws0->range_col(52)->range(),          "$sheet!AZ:AZ", "52 should be col AZ:AZ";
  is $ws0->range_col(53)->range(),          "$sheet!BA:BA", "53 should be col BA:BA";
  is $ws0->range_col(18_278)->range(),      "$sheet!ZZZ:ZZZ", "18,278 should be col ZZZ:ZZZ";
  # this is an invalid column in google sheets, but let google die on us rather than us checking.
  is $ws0->range_col(18_279)->range(),      "$sheet!AAAA:AAAA", "18,279 should be col AAAA:AAAA";

  return;
}

1;
