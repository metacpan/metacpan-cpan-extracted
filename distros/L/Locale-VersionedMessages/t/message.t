#!/usr/bin/perl

use Test::Inter 1.04;

BEGIN {
   $t       = new Test::Inter 'message';
   $testdir = $t->testdir();
}

use Locale::VersionedMessages;
use lib "$testdir/lib";

my $lm = new Locale::VersionedMessages;
$lm->set('Test1');

sub test {
   my($op,@test) = @_;

   my @ret;
   if ($op eq 'message') {
      @ret = $lm->message(@test);

   } elsif ($op eq 'search') {
      @ret = $lm->search(@test);

   } elsif ($op eq 'query_msg_locales') {
      @ret = $lm->query_msg_locales(@test);
   
   } elsif ($op eq 'query_msg_vers') {
      @ret = $lm->query_msg_vers(@test);
   
   }

   $err = $lm->err();
   return $err  if ($err);
   return @ret;
}

$tests = "

message Test1 Message_0  =>
   'Message not found in specified lexicons: Message_0'

search en_US             =>

message Test1 Message_1  =>
   'Message #1 in English.__nl__'
   en_US

search fr_FR en_US       =>

message Test1 Message_1  =>
   'Message #1 in French.__nl__'
   fr_FR

message Test1 Message_2  =>
   'Message #2 in English.__nl__'
   en_US

query_msg_locales Test1 Message_0 =>
   'Message ID not defined in set: Test1 [Message_0]'

query_msg_locales Test1 Message_1 =>
   en_US
   de_DE
   fr_FR

query_msg_locales Test1 Message_2 =>
   en_US
   de_DE

query_msg_vers Test1 Message_1 => 2

query_msg_vers Test1 Message_2 => 4

query_msg_vers Test1 Message_3 => 6

query_msg_vers Test1 Message_1 fr_FR => 2

query_msg_vers Test1 Message_2 fr_FR => 0

query_msg_vers Test1 Message_3 fr_FR => 5

";

$t->tests(func  => \&test,
          tests => $tests);
$t->done_testing();

#Local Variables:
#mode: cperl
#indent-tabs-mode: nil
#cperl-indent-level: 3
#cperl-continued-statement-offset: 2
#cperl-continued-brace-offset: 0
#cperl-brace-offset: 0
#cperl-brace-imaginary-offset: 0
#cperl-label-offset: 0
#End:

