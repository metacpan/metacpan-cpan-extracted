use strict;
use warnings;

use Test::More tests => 2;

my $eval_return = eval {
  use Lingua::EN::SENNA;
  1;
};

ok($eval_return && !$@, 'Lingua::EN::SENNA module loaded successfully.');

my $tagger = Lingua::EN::SENNA->new();
ok($tagger, 'Can initialize a Lingua::EN::SENNA tagger');
