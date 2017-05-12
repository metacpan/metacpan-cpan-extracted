#!/usr/bin/perl

use Test::Inter;

BEGIN {
   $t       = new Test::Inter 'search';
   $testdir = $t->testdir();
}

use Locale::VersionedMessages;
use lib "$testdir/lib";

my $lm = new Locale::VersionedMessages;
$lm->set('Test1');

sub test {
   my ($op,@test) = @_;

   if ($op eq 'search') {
      $lm->search(@test);
      return ();
   }

   if ($op eq 'query') {
      @ret = $lm->query_search(@test);
      $err = $lm->err();
      if ($err) {
         return $err;
      }
      return @ret;
   }
}

$tests = "

query                    =>

search de_DE fr_FR en_US =>

query                    => de_DE fr_FR en_US

search                   =>

query                    =>

query Test1              => 

search Test1 de_DE fr_FR =>

query Test1              => de_DE fr_FR

search Test1             =>

query Test1              => 

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

