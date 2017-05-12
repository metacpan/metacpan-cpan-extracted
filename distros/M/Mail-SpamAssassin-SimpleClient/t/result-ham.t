#!perl
use strict;
use warnings;


use Test::More;

plan skip_all => "set PERL_SIMPLECLIENT_TEST to run these tests"
  unless $ENV{PERL_SIMPLECLIENT_TEST};

require Mail::SpamAssassin::SimpleClient;
require Email::Simple;

plan 'no_plan';

open my $msg_fh, '<', 't/messages/not-spam.msg';
my $msg = do { local $/; <$msg_fh>; };

my $email = Email::Simple->new($msg);
my $result = Mail::SpamAssassin::SimpleClient->new->check($email);

ok(!$result->is_spam, "yup, this message is ham");
my @tests = $result->tests;
ok(@tests, 'got a list of tests');

