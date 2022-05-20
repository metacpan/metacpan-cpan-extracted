use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw(catfile rel2abs);
use Getopt::App -capture;

my $script = rel2abs(catfile qw(example bin cool));
plan skip_all => "$script" unless -x $script;

local $0 = $script;
my $app = do($script) or die $@;

subtest 'dispatch' => sub {
  my $res = capture($app, []);
  is $res->[2], 10, 'main exit';
  like $res->[0], qr{\bcool$}, 'main stdout' or diag "ERROR: $res->[1]";

  $res = capture($app, [qw(nope)]);
  is $res->[1], "Unknown subcommand: nope\n", 'nope';

  $res = capture($app, [qw(invalid)]);
  is $res->[2], 2, 'invalid exit';
  like $res->[1], qr{Unable to load subcommand invalid:}, 'invalid stderr';

  $res = capture($app, [qw(beans a 24)]);
  is $res->[2], 11, 'invalid exit';
  like $res->[0], qr{\bbeans\.pl/a/24$}, 'beans stdout' or diag "ERROR: $res->[1]";

  $res = capture($app, [qw(coffee b 42)]);
  is $res->[2], 12, 'invalid exit';
  like $res->[0], qr{\bcoffee\.pl/b/42$}, 'coffee stdout' or diag "ERROR: $res->[1]";
};

subtest 'help' => sub {
  my $res = capture($app, [qw(-h)]);
  is $res->[0], <<'HERE', 'help';
Subcommands:
  beans    Try beans.pl
  coffee   Try coffee.pl
  invalid  Try invalid.pl

Options:
  -h  

HERE
};

done_testing;
