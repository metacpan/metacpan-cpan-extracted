use Test2::V0;
use File::Spec::Functions qw(catfile rel2abs);
use Getopt::App -capture;

my $script = rel2abs(catfile qw(example bin cool));
plan skip_all => "$script" unless -x $script;

local $0 = $script;
my $app = do($script) or die $@;

subtest 'dispatch to method' => sub {
  my $res = capture($app, [qw(foo)]);
  like $res->[0], qr{args= foo=}, 'plain stdout' or diag "ERROR: $res->[1]";

  $res = capture($app, [qw(foo --foo cool a b c)]);
  like $res->[0], qr{args=a,b,c foo=cool}, 'args stdout' or diag "ERROR: $res->[1]";
};

subtest 'dispatch to script' => sub {
  my $res = capture($app, []);
  is $res->[2], 10, 'main exit';
  like $res->[0], qr{^0\|.*\bcool$}, 'main stdout' or diag "ERROR: $res->[1]";

  $res = capture($app, [qw(nope)]);
  is $res->[1], "Unknown subcommand: nope\n", 'nope';
  is $res->[2], 2,                            'invalid exit';

  $res = capture($app, [qw(invalid)]);
  like $res->[1], qr{Unable to load subcommand invalid:}, 'invalid stderr';
  is $res->[2], 2, 'invalid exit';

  $res = capture($app, [qw(beans a 24)]);
  like $res->[0], qr{^1\|beans\|.*\bbeans\.pl\|.*\bbeans\.pl\|a\|24$}, 'beans stdout' or diag "ERROR: $res->[1]";
  is $res->[2], 11, 'beans exit';

  $res = capture($app, [qw(coffee b 42)]);
  like $res->[0], qr{\bcoffee\.pl/b/42$}, 'coffee stdout' or diag "ERROR: $res->[1]";
  is $res->[2], 12, 'coffee exit';

  $res = capture($app, [qw(help)]);
  like $res->[0],   qr{Usage:},       'help stdout'    or diag "ERROR: $res->[1]";
  unlike $res->[0], qr{Subcommands:}, 'no subcommands' or diag "ERROR: $res->[1]";
  is $res->[2], 1, 'help exit';
};

subtest 'help' => sub {
  my $res = capture($app, [qw(-h)]);
  is $res->[0], <<'HERE', 'help';
Subcommands:
  foo      internal method
  beans    Try beans.pl
  coffee   Try coffee.pl
  help     Try help.pl
  invalid  Try invalid.pl
  unknown  Try unknown.pl

Options:
  --foo                Argument for foo
  -h                   Print help
  --completion-script  Print autocomplete script

HERE
};

subtest 'unknown subcommand' => sub {
  my $res = capture($app, [qw(unknown)]);
  is $res->[0], "ok\n", 'ok stdout'     or diag "ERROR: $res->[1]";
  is $res->[2], 0,      'ok exit value' or diag "ERROR: $res->[1]";

  $res = capture($app, [qw(unknown foo)]);
  is $res->[0], "unknown\n", 'foo stdout'     or diag "ERROR: $res->[1]";
  is $res->[2], 0,           'foo exit value' or diag "ERROR: $res->[1]";

  $res = capture($app, [qw(unknown 42)]);
  is $res->[0], '', 'number stdout'     or diag "ERROR: $res->[1]";
  is $res->[1], '', 'number stderr'     or diag "ERROR: $res->[1]";
  is $res->[2], 42, 'number exit value' or diag "ERROR: $res->[1]";

  $res = capture($app, [qw(unknown die)]);
  like $res->[1], qr{not cool}, 'die stderr' or diag "ERROR: $res->[0]";
};

done_testing;
