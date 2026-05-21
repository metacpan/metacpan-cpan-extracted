use strict;
use warnings;
use utf8;
use warnings FATAL => 'utf8';
use open ':std', ':encoding(UTF-8)';
use Test2::V0;
use Test2::Bundle::More;
use Finance::Tiller2QIF::ReadCSV;

# require './t/TestHelper.pm';

# Call the private function directly to isolate it from CSV I/O and encoding.
sub norm { Finance::Tiller2QIF::ReadCSV::_normalize_amount(@_) }

subtest symbol_stripping => sub {
  is( norm('$100.00'),  '100.00',  'USD symbol stripped'         );
  is( norm('£100.50'),  '100.50',  'GBP symbol stripped'         );
  is( norm('£1500.00'), '1500.00', 'GBP whole amount stripped'   );
  is( norm('€42.00'),   '42.00',   'EUR symbol stripped'         );
  is( norm('¥1000'),    '1000',    'JPY symbol stripped'         );
};

subtest us_format => sub {
  is( norm('$1,234.56'), '1234.56', 'US comma-thousands with decimal'    );
  is( norm('$1,000'),    '1000',    'US comma-thousands without decimal'  );
  is( norm('100.00'),    '100.00',  'Plain decimal unchanged'             );
};

subtest european_format => sub {
  is( norm('€1.234,56'), '1234.56', 'EU dot-thousands comma-decimal'     );
  is( norm('€100,50'),   '100.50',  'EU comma-decimal without thousands' );
};

subtest edge_cases => sub {
  is( norm(''),        '',       'Empty string returns empty'     );
  is( norm('-50.00'),  '-50.00', 'Negative amount unchanged'      );
  is( norm('-$50.00'), '-50.00', 'Negative with symbol stripped'  );
};

done_testing();