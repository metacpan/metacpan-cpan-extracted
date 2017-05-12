use strict;
use warnings;

use lib 't/lib';

use BaseLogger qw{:log with_logger set_logger};
use Test::More qw(no_plan);

my @levels = qw(lol wut zomg);

VANILLA: {
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
}

ok(!eval { Log::Contextual->import; 1 }, 'Blank Log::Contextual import dies');

