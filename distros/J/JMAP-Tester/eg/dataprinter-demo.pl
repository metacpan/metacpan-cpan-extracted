use v5.36.0;

use JMAP::Tester;

use Test::Deep::JType 0.005; # jstr() in both want and have
use Test::More;
use Test::Abortable 'subtest';

my $dumper = do {
  require Data::Printer;
  sub { Data::Printer::np($_[0], colored => 1) }
};

my $res = JMAP::Tester::Response->new({
  diagnostic_dumper => $dumper,
  items => [
    [ jstr('Pie/eat'),
      { howMany => jnum(100), tastiestPieId => jstr(123) },
      jstr('a') ],
    [ jstr('Junk/discard'),
      { notDiscarded => [] },
      jstr('a') ],

    [ jstr('Beer/drink'),
      { abv => jnum(0.02) },
      jstr('b') ],
    [ jstr('Nap/take'),
      { successfulDuration => jnum(2) },
      jstr('c') ],
    [ jstr('Dream/dream'),
      { about => jstr("more pie") },
      jstr('c') ],
  ],
});

use Test::Abortable 'subtest';
subtest "foo" => sub {
  $res->sentence_named('All/good');
};

done_testing;
