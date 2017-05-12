#!/usr/bin/perl -w

# Test Linux::Cpuinfo;

use Test::More;

BEGIN 
  {
  plan tests => 18;

  use_ok ('Linux::Cpuinfo');
  }
  
can_ok ('Linux::Cpuinfo', qw/
  cpuinfo
  new
  num_cpus
  cpus
  cpu
  /);

# there might be others, but they are AUTOLOADed and thus not always
# available
can_ok ('Linux::Cpuinfo::Cpu', qw/
  new
  /);

#############################################################################

is ($/, "\n", '$/ default');
# did we load the right one?
ok($Linux::Cpuinfo::VERSION == 1.12,'version ok');

diag $Linux::Cpuinfo::VERSION;

my $cpuinfo;
eval { $cpuinfo = Linux::Cpuinfo->cpuinfo(); };
print "# Error: $@\n" unless
  is (ref($cpuinfo), 'Linux::Cpuinfo', 'cpuinfo()');

is ($/, "\n", '$/ not clobbered up');

eval { $cpuinfo = Linux::Cpuinfo->new(); };
print "# Error: $@\n" unless
  is (ref($cpuinfo), 'Linux::Cpuinfo', 'new()');

#############################################################################
# Test old interface.

my $bog = 0;

eval { $bog = $cpuinfo->bogomips(); };
print "# Error: $@\n" unless
  isnt ($bog,0, 'bogomips() returned something');


$cpuinfo = undef;
eval { $cpuinfo = Linux::Cpuinfo->new('t/proc/cpuinfo.x86_smp'); };

print "# Error: $@\n" unless
  is (ref($cpuinfo), 'Linux::Cpuinfo', 'reading alternate file');

#############################################################################
# test OO interface

my $num_cpus;

eval { $num_cpus = $cpuinfo->num_cpus(); };

print "# Error: $@\n" unless
  is ($num_cpus, 2, 'num_cpus == 2');
 
#############################################################################
# test the new interface.

my $cpu;

eval { $cpu = $cpuinfo->cpu(0); };

print "# Error: $@\n" unless
  is (ref($cpu), 'Linux::Cpuinfo::Cpu', 'cpu(0)');

my $chip;    
eval { $chip = $cpu->model_name(); };

print "# Error: $@\n" unless
  is ($chip, 'Pentium Pro', 'model_name');

eval
{
   foreach my $cpu ( $cpuinfo->cpus() )
   {
     my $bog = $cpu->bogomips();
     print "# Error: $@\n" unless
       isnt ($bog, 0, 'bogmips');
   }
};

eval { $cpuinfo->fofoo() && die("fofoo"); };
like ($@,
	qr/Can't locate object method "fofoo" via package "Linux::Cpuinfo::Cpu"/,
	'dies on unknown methods due to no NoFatal');

#############################################################################
# Test the new interface to the constructor

$cpuinfo = undef;
eval { $cpuinfo = Linux::Cpuinfo->cpuinfo({NoFatal => 1}); };

print "# Error: $@\n" unless
  is (ref($cpuinfo), 'Linux::Cpuinfo', 'NoFatal');

eval { $cpuinfo->fofoo() && die("fofoo"); };
isnt ($@, 'fofoo', 'does not die on unknown methods due to NoFatal');

