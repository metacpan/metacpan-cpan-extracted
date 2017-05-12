#!perl
use strict;
use warnings;

use Test::More;

plan skip_all => "set PERL_SIMPLECLIENT_TEST to run these tests"
  unless $ENV{PERL_SIMPLECLIENT_TEST};

require Email::Simple;
require Mail::SpamAssassin::SimpleClient;

plan 'no_plan';

open my $msg_fh, '<', 't/messages/spam.msg';
my $msg = do { local $/; <$msg_fh>; };

my $email = Email::Simple->new($msg);
my $result = Mail::SpamAssassin::SimpleClient->new->check($email);

ok($result->is_spam, "yup, this message is spam");
my @tests = $result->tests;
ok(@tests, 'got a list of tests');

my %scores = $result->test_scores;
foreach my $test (@tests) {
  ok(defined $scores{$test}, "got a score for $test");
}

my %descriptions = $result->test_descriptions;
foreach my $test (@tests) {
  ok(defined $descriptions{$test}, "got a description for $test");
}
