use strict;
use warnings;

use lib 't/lib';

use DefaultImportLogger;
use Test::More;

my @levels = qw(lol wut zomg);

for (@levels) {
  main->can("log_$_")->(sub { 'fiSMBoC' });
  is($DumbLogger2::var, "[$_] fiSMBoC\n", "$_ works");

  my @vars =
    main->can("log_$_")->(sub { 'fiSMBoC: ' . $_[1] }, qw{foo bar baz});
  is($DumbLogger2::var, "[$_] fiSMBoC: bar\n", "log_$_ works with input");
  ok(
    eq_array(\@vars, [qw{foo bar baz}]),
    "log_$_ passes data through correctly"
  );

  my $val = main->can("logS_$_")->(sub { 'fiSMBoC: ' . $_[0] }, 'foo');
  is($DumbLogger2::var, "[$_] fiSMBoC: foo\n", "logS_$_ works with input");
  is($val, 'foo', "logS_$_ passes data through correctly");
}

done_testing;
