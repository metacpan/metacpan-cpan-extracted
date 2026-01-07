package Test::Google::RestApi::SheetsApi4::Range::Row;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Range::Row';

use parent qw(Test::Class Test::Google::RestApi::SheetsApi4::Range::Base);

init_logger;

my $sheet = "'Sheet1'";

sub range : Tests(13) {
  my $self = shift;

  my $ws0 = $self->mock_worksheet;

  is $ws0->range_row('1:1')->range(),          "$sheet!1:1", "1:1 should be 1:1";
  is $ws0->range_row([undef, '1'])->range(),   "$sheet!1:1", "[undef, '1'] should be 1:1";
  is $ws0->range_row([0, '1'])->range(),       "$sheet!1:1", "[0, '1'] should be 1:1";
  is $ws0->range_row(['', '1'])->range(),      "$sheet!1:1", "['', '1'] should be 1:1";
  is $ws0->range_row([[undef, '1']])->range(), "$sheet!1:1", "[[undef, '1']] should be 1:1";
  is $ws0->range_row([[0, '1']])->range(),     "$sheet!1:1", "[[0, '1']] should be 1:1";
  is $ws0->range_row([['', '1']])->range(),    "$sheet!1:1", "[['', '1']] should be 1:1";
  is $ws0->range_row({row => '1'})->range(),   "$sheet!1:1", "{row => '1'} should be 1:1";
  is $ws0->range_row([{row => '1'}])->range(), "$sheet!1:1", "[{row => '1'}] should be 1:1";
  is $ws0->range_row([[5, '1'], [undef, '1']])->range(), "$sheet!E1:1", "[[5, '1'], [undef, '1']] should be E1:1";
  is $ws0->range_row([[5, '1'], [0, '1']])->range(),     "$sheet!E1:1", "[[5, '1'], [0, '1']] should be E1:1";
  is $ws0->range_row([[5, '1'], ['', '1']])->range(),    "$sheet!E1:1", "[[5, '1'], ['', '1']] should be E1:1";
  is $ws0->range_row([{row => '1', col => 5}, {row => '1'}])->range(), "$sheet!E1:1", "[{row => '1', col => 5}, {row => '1'}] should be E1:1";

  return;
}

1;
