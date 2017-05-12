use strict; use warnings;

BEGIN {
  $ENV{PERL_TEST_DM_LOG_DIR} = 'xt/log'
    if -d 'xt/log';
}

use Test::DependentModules 'test_all_dependents';
test_all_dependents('List::Objects::WithUtils');
