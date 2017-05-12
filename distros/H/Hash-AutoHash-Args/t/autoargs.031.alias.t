use lib qw(t);
use Carp;
use Hash::AutoHash::Args qw(autoargs_alias);
use Hash::AutoHash::Args::V0;
use Test::More;
use Test::Deep;

#################################################################################
# test alias. can't be tested in 030.functions because it has to be imported at
# compile-time for prototype to work
#################################################################################
sub test_exported_functions {
  my($V)=@_;
  my $args_class=$V? 'Hash::AutoHash::Args': 'Hash::AutoHash::Args::V0';
  my $label=$V? 'V1': 'V0';
  # test object class for sanity sake
  my $args=new $args_class;
  is(ref $args,$V? 'Hash::AutoHash::Args': 'Hash::AutoHash::Args::V0',
     "$label class is $args_class - sanity check");

  my %hash;
  my $args=new $args_class (-arg1=>'value11',Arg2=>'value21');
  autoargs_alias($args,%hash);
  cmp_deeply(\%hash,{arg1=>'value11',arg2=>'value21'},"$label autoargs_alias initial values");
  $hash{'aRg2'}='value22';
  $hash{'-arg3'}='value31';
  cmp_deeply(\%hash,{arg1=>'value11',arg2=>'value22',arg3=>'value31'},
	     "$label autoargs_alias after update hash: via hash");
  my %args=%$args;
  cmp_deeply(\%args,{arg1=>'value11',arg2=>'value22',arg3=>'value31'},
	     "$label autoargs_alias after update hash: via args");
  $args->arg3('value32');
  $args->arg4('value41');
  cmp_deeply(\%hash,{arg1=>'value11',arg2=>'value22',arg3=>'value32',arg4=>'value41'},
	     "$label autoargs_alias after update args: via hash");  
  my %args=%$args;
  cmp_deeply(\%args,{arg1=>'value11',arg2=>'value22',arg3=>'value32',arg4=>'value41'},
	     "$label autoargs_alias after update args: via args");  

}
test_exported_functions(0);
test_exported_functions(1);

done_testing();
