use strict;
use warnings;
use Test::More;

#bug report does not include a case where Log::Contextual is
#brought in via 'use'

#try to import a single log function but do not include any tags
BEGIN {
  require Log::Contextual;
  Log::Contextual->import('log_info');
}

eval {
   log_info { "test" };
};
like(
  $@,
  qr/^ no logger set!  you can't try to log something without a logger!/,
  'Got correct error'
);

done_testing;
