#!perl

use strict;
use warnings;

use Test::More;

use Linux::Cpuinfo;

while (my $filename = <t/proc/cpuinfo.*>) 
{
   ok(my $obj = Linux::Cpuinfo->new($filename), "create an object from $filename");
   isa_ok($obj, 'Linux::Cpuinfo');
   ok($obj->num_cpus() > 0, "got at least one cpu");

   my $count_cpus = 0;

   for my $cpu ( $obj->cpus() )
   {
      $count_cpus++;
      isa_ok($cpu, 'Linux::Cpuinfo::Cpu');
      foreach my $method (keys %{$cpu->{_data}} )
      {
         eval { my $v = $cpu->$method };
         if ( $@ )
         {
            fail "can call $method";
         }
         else
         {
            pass "can call $method";
         }
         can_ok($cpu, $method);
      }
   }

   is($obj->num_cpus(), $count_cpus, "and we saw the expected number of cpus");
}

done_testing();
