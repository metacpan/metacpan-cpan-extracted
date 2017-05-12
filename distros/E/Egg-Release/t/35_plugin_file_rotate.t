use Test::More tests=> 52;
use lib qw( ./lib ../lib );
use Egg::Helper;

ok $e= Egg::Helper->run( Vtest=> {
  vtest_plugins=> [qw/ File::Rotate /],
  }), q{ load plugin. };

my $file= {
  filename => 'tmp/rotate.txt',
  value    => 'test',
  };
$e->helper_create_file($file);

can_ok $e, 'rotate';
  my $fname= $file->{filename};
  ok $e->rotate($fname), q{$e->rotate($fname)};
  ok ! -e $fname, q{! -e $fname};
  ok -e "$fname.1", q{-e "$fname.1"};
  $e->helper_create_file($file);
  ok -e $fname, q{-e $fname};
  ok $e->rotate($fname), q{$e->rotate($fname)};
  ok ! -e $fname, q{! -e $fname};
  ok -e "$fname.1", q{-e "$fname.1"};
  ok -e "$fname.2", q{-e "$fname.2"};
  $e->helper_create_file($file);
  ok -e $fname, q{-e $fname};
  ok $e->rotate($fname), q{$e->rotate($fname)};
  ok ! -e $fname, q{! -e $fname};
  ok -e "$fname.1", q{-e "$fname.1"};
  ok -e "$fname.2", q{-e "$fname.2"};
  ok -e "$fname.3", q{-e "$fname.3"};
  $e->helper_create_file($file);
  ok -e $fname, q{-e $fname};
  ok $e->rotate($fname, stock=> 3), q{$e->rotate($fname, stock=> 3)};
  ok ! -e $fname, q{! -e $fname};
  ok -e "$fname.1", q{-e "$fname.1"};
  ok -e "$fname.2", q{-e "$fname.2"};
  ok -e "$fname.3", q{-e "$fname.3"};
  ok ! -e "$fname.4", q{! -e "$fname.4"};
  $e->helper_create_file($file);
  ok -e $fname, q{-e $fname};
  ok $e->rotate($fname, stock=> 3), q{$e->rotate($fname, stock=> 3)};
  ok ! -e $fname, q{! -e $fname};
  ok -e "$fname.1", q{-e "$fname.1"};
  ok -e "$fname.2", q{-e "$fname.2"};
  ok -e "$fname.3", q{-e "$fname.3"};
  ok ! -e "$fname.4", q{! -e "$fname.4"};

can_ok $e, 'rotate_report';
  ok my @report= $e->rotate_report, q{my @report= $e->rotate_report};
  is @report, 12, q{@report, 12};
  ok ! $e->rotate_report(0), q{! $e->rotate_report(0)};
  ok ! $e->rotate_report,    q{! $e->rotate_report};

# reverse.
ok ! -e $fname, q{! -e $fname};
ok $e->rotate($fname, reverse=> 1), q{$e->rotate($fname, reverse=> 1)};
ok -e $fname, q{-e $fname};
ok -e "$fname.1", q{-e "$fname.1"};
ok -e "$fname.2", q{-e "$fname.2"};
ok ! -e "$fname.3", q{! -e "$fname.3"};
ok $e->rotate($fname, reverse=> 1), q{$e->rotate($fname, reverse=> 1)};
ok -e $fname, q{-e $fname};
ok -e "$fname.1", q{-e "$fname.1"};
ok ! -e "$fname.2", q{! -e "$fname.2"};
ok $e->rotate($fname, reverse=> 1), q{$e->rotate($fname, reverse=> 1)};
ok -e $fname, q{-e $fname};
ok ! -e "$fname.1", q{! -e "$fname.1"};
ok $e->rotate($fname, reverse=> 1), q{$e->rotate($fname, reverse=> 1)};
ok -e $fname, q{-e $fname};
ok $e->rotate($fname, reverse=> 1), q{$e->rotate($fname, reverse=> 1)};
ok -e $fname, q{-e $fname};
