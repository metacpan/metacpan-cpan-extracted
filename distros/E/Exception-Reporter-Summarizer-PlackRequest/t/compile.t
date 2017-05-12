use Test::More 0.88;

use_ok 'Exception::Reporter::Summarizer::PlackRequest', 'compiles okay';

isa_ok(
  Exception::Reporter::Summarizer::PlackRequest->new,
  'Exception::Reporter::Summarizer::PlackRequest',
  'can instantiate objects'
);

done_testing;
