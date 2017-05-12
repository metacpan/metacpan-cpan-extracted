# -*- cperl -*-

use Test::More tests => 5;

use Lingua::NATools::PCorpus;
ok(1);

# check some private functions
ok(!Lingua::NATools::PCorpus::neod("-*- READY -*-"));
ok(Lingua::NATools::PCorpus::neod("Ready"));
ok(Lingua::NATools::PCorpus::neod("\t-*- READY -*-"));
ok(Lingua::NATools::PCorpus::neod("-*- READY -*-\n"));
#
