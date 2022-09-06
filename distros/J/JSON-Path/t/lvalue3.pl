use Test2::V0;

use JSON::Path::Evaluator qw/evaluate_jsonpath/;
my $hash = { "a" => "b" };
my @refs = evaluate_jsonpath($hash, '$.l1.l2', want_ref => 1);
done_testing;

