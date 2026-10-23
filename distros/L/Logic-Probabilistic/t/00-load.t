use v5.38;
use Test::More;

use_ok('Logic::Probabilistic') or BAIL_OUT("Cannot load Logic::Probabilistic");
use_ok('Logic::Probabilistic::PFact')
  or BAIL_OUT("Cannot load Logic::Probabilistic::PFact");
use_ok('Logic::Probabilistic::PChoice')
  or BAIL_OUT("Cannot load Logic::Probabilistic::PChoice");
use_ok('Logic::Probabilistic::Result')
  or BAIL_OUT("Cannot load Logic::Probabilistic::Result");
use_ok('Logic::Probabilistic::Program')
  or BAIL_OUT("Cannot load Logic::Probabilistic::Program");
use_ok('Logic::Probabilistic::Inference::Base')
  or BAIL_OUT("Cannot load Logic::Probabilistic::Inference::Base");
use_ok('Logic::Probabilistic::Inference::Exact')
  or BAIL_OUT("Cannot load Logic::Probabilistic::Inference::Exact");
use_ok('Logic::Probabilistic::Inference::Rejection')
  or BAIL_OUT("Cannot load Logic::Probabilistic::Inference::Rejection");
use_ok('Logic::Probabilistic::Inference::MCMC')
  or BAIL_OUT("Cannot load Logic::Probabilistic::Inference::MCMC");

diag("Testing Logic::Probabilistic $Logic::Probabilistic::VERSION, Perl $], $^X"
);

done_testing();
