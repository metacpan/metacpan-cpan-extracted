use lib qw(t);
use Carp;
use Hash::AutoHash::Args;
use Hash::AutoHash::Args::V0;
use Test::More;
use Test::Deep;

#################################################################################
# test version 0 methods
#################################################################################
# check actual value for sanity sake
my $args=new Hash::AutoHash::Args::V0
  (-ARG1=>'value11',
   -ARG2=>'value21',-arg2=>'value22',
   ArG3=>'value31','--arg3'=>'value32',-ARG3=>'value33',
  );
my @list123=$args->get_args(qw(arg1 arg2 arg3));
cmp_deeply(\@list123,
	   ['value11',['value21','value22'],['value31','value32','value33']],
	   'V0 get_args. list');

my $list123=$args->get_args(qw(arg1 arg2 arg3));
cmp_deeply($list123,
	   ['value11',['value21','value22'],['value31','value32','value33']],
	   'V0 get_args. ARRAY');

my %hash123=$args->getall_args;
cmp_deeply(\%hash123,
	   {arg1=>'value11',
	    arg2=>['value21','value22'],
	    arg3=>['value31','value32','value33']},
	   'V0 getall_args. hash');
$hash123=$args->getall_args;
cmp_deeply($hash123,
	   {arg1=>'value11',
	    arg2=>['value21','value22'],
	    arg3=>['value31','value32','value33']},
	   'V0 getall_args. HASH');

$args->set_args
  (-arg1=>'changed value11',
   -arg2=>'changed value21',-arg2=>'changed value22',
   ArG3=>'changed value31','--arg3'=>'changed value32',-ARG3=>'changed value33',
  );
my @list123=$args->get_args(qw(arg1 arg2 arg3));
cmp_deeply(\@list123,
	   ['changed value11',
	    ['changed value21','changed value22'],
	    ['changed value31','changed value32','changed value33']],
	   'V0 set_args');

#################################################################################
# test version 0 methods on version 1 object
# also tested in special_keys, but do it here to make the difference clear
#################################################################################
my $args=new Hash::AutoHash::Args
  (-ARG1=>'value11',
   -ARG2=>'value21',-arg2=>'value22',
   ArG3=>'value31','--arg3'=>'value32',-ARG3=>'value33',
  );
my $actual=$args->get_args(qw(arg1 arg2 arg3)); # sets 'get_args' key to ARRAY of values
cmp_deeply($actual,[qw(arg1 arg2 arg3)],'V1 get_args');

my $actual=$args->getall_args;	
is($actual,undef,'V1 getall_args');

$args->set_args			                # sets 'set_arg' key to ARRAY of values
  (-arg1=>'changed value11',
   -arg2=>'changed value21',-arg2=>'changed value22',
   ArG3=>'changed value31','--arg3'=>'changed value32',-ARG3=>'changed value33',
  );
my $actual=$args->{set_args};
cmp_deeply($actual,
	   [(-arg1=>'changed value11',
	     -arg2=>'changed value21',-arg2=>'changed value22',
	     ArG3=>'changed value31','--arg3'=>'changed value32',-ARG3=>'changed value33',)],
	   'V1 set_args');

done_testing();
