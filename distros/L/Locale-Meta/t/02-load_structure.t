#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 2;
use Locale::Meta;

my $lm = Locale::Meta->new();
ok($lm, 'Got a proper Meta structure');

my $structure = {
  "en" => {
    "greeting"   => {
      "trans" => "Hello",
       "meta" => {
          "test" => "meta hello"
      }
    }
  }
};

$lm->charge($structure);

is($lm->loc('greeting', 'en'), 'Hello', 'greeting -> en = Hello');

done_testing();
