my $test_count;
BEGIN { $test_count = 161 }

use strict;
use Test::More tests => $test_count;

use FindBin;
use lib $FindBin::RealBin;
use testload;

my @headers = ( 'Date', 'Open', 'High', 'Low', 'Close',
                'Volume', 'Adj. Close*');

my($pp_present, $xs_present);
eval  { require Text::CSV_PP };
$pp_present = !$@;
eval  { require Text::CSV_XS };
$xs_present = !$@;

my $each_count = ($test_count - 1)/2;

SKIP: {
  my $class = 'Text::CSV_PP';
  skip "$class not installed",  $each_count unless $pp_present;
  use_ok($class);
  my $cp = $class->new;
  csv_parse($cp, csv_content());
}

SKIP: {
  my $class = 'Text::CSV_XS';
  skip "$class not installed",  $each_count unless $xs_present;
  use_ok($class);
  my $cp = $class->new;
  csv_parse($cp, csv_content());
}

ok($pp_present || $xs_present, "csv parsing class present");

###

sub csv_parse {
  my($cp, $str) = @_;
  my @rows = split(/\s*\n\s*/, $str);
  chomp @rows;
  my $first_line = shift @rows;
  ok($cp->parse($first_line), "header parse");
  my @fields = $cp->fields;
  cmp_ok(scalar @fields, '==', scalar @headers,  "header field count");
  foreach (0 .. $#headers) {
    cmp_ok($fields[$_], 'eq', $headers[$_], "header field match");
  }
  foreach my $line (@rows) {
    ok($cp->parse($line), 'line parse');
    my @fields = $cp->fields;
    cmp_ok(scalar @fields, '==', 7, "line field count");
  }
}
