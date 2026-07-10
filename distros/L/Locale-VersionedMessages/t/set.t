#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

sub test {
   my($op,@test) = @_;

   if ($op eq 'set') {
      $::lm->set(@test);
      my $err = $::lm->err();
      if ($err) {
         $err =~ s/ in \@INC.*$//;
         return $err;
      }
      return;
   }

   if      ($op eq 'query_set_default') {
      return $::lm->query_set_default(@test);
   } elsif ($op eq 'query_set_locales') {
      return $::lm->query_set_locales(@test);
   } elsif ($op eq 'query_set_msgid') {
      return $::lm->query_set_msgid(@test);
   }
}

my $tests = "

set foo     => 'Unable to load set: foo: Can't locate Locale/VersionedMessages/Sets/foo.pm'

set Empty   =>

set Test1   =>

query_set_default Test1  => en_US

query_set_locales Test1  => de_DE en_US fr_FR

query_set_msgid Test1
  =>
  Message_1
  Message_2
  Message_3
";

$::ti->tests(func  => \&test,
             tests => $tests);
$::ti->done_testing();

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

