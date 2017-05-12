#!/usr/bin/perl

use Test::Inter 1.04;

BEGIN {
   $t       = new Test::Inter 'message (substitution)';
   $testdir = $t->testdir();
}

use Locale::VersionedMessages;
use lib "$testdir/lib";

$lm = new Locale::VersionedMessages;
$lm->set('Test2');

sub test {
   my($op,@test) = @_;

   my @ret;
   if ($op eq 'message') {
      $tmp = $lm->message(@test);
      @ret = ($tmp);

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

# Errors

message Test2 Subst_0a fr_FR aaa AAA =>
   'Message not found in specified lexicons: Subst_0a'

message Test2 Subst_0b en_US bbb BBB =>
   'A required substitution value was not passed in: Subst_0b [aaa]'

message Test2 Subst_0b en_US aaa AAA bbb BBB =>
   'An invalid value was passed in: Subst_0b [bbb]'

message Test2 Subst_0c en_US aaa AAA =>
   'Message does not contain substitutions, but values were supplied: Subst_0c'

message Test2 Subst_0d en_US aaa AAA =>
   'The message in a lexicon does not contain a required substitution: Subst_0d [en_US aaa]'

message Test2 Subst_0e en_US aaa AAA =>
   'Invalid sprintf format: Subst_0e [en_US aaa]'

message Test2 Subst_0f en_US aaa AAA =>
   'Invalid sprintf format: Subst_0f [en_US aaa]'

message Test2 Subst_0g en_US n 5 =>
   'Default string required in quant substitution: Subst_0g [en_US n]'

message Test2 Subst_0h en_US n 5 =>
   'Quantity test contains invalid characters: Subst_0h [en_US n]'

message Test2 Subst_3a en_US n -5 =>
   'Quantity test requires an unsigned integer: Subst_3a [en_US n]'

message Test2 Subst_0i en_US n 5 =>
   'Quantity test malformed: Subst_0i [en_US n]'

# Simple substitutions

message Test2 Subst_1a en_US aaa AAA =>
   'Substitution message 1a with value AAA in English.__nl__'

message Test2 Subst_1a fr_FR aaa AAA =>
   'Substitution message 1a with value AAA in French.__nl__'

message Test2 Subst_1b en_US aaa AAA =>
   'Substitution message 1b with value AAA (dupl: AAA) in English.__nl__'

# Formatted substitutions

message Test2 Subst_2a en_US n 5 =>
   'Substitution message 2a with formatted value 00005 in English.__nl__'

# Quantity substitutions

message Test2 Subst_3a en_US n 1 =>
   'Substitution message 3a with one value in English.__nl__'

message Test2 Subst_3a en_US n 2 =>
   'Substitution message 3a with 2 values in English.__nl__'

message Test2 Subst_3a fr_FR n 1 =>
   'Substitution message 3a with one value in French.__nl__'

message Test2 Subst_3a fr_FR n 2 =>
   'Substitution message 3a with two values in French.__nl__'

message Test2 Subst_3a fr_FR n 3 =>
   'Substitution message 3a with 3 values in French.__nl__'

message Test2 Subst_3b en_US n 1 =>
   'Substitution message 3b with one value in English.__nl__'

message Test2 Subst_3b en_US n 2 =>
   'Substitution message 3b with  2 values in English.__nl__'

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

