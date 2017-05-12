use lib qw(t);
use Carp;
use Hash::AutoHash::Args;
use Hash::AutoHash::Args::V0;
use Test::More;
use Test::Deep;

sub test_basics {
  my($V)=@_;
  my $args_class=$V? 'Hash::AutoHash::Args': 'Hash::AutoHash::Args::V0';
  my $label=$V? 'V1': 'V0';
  # test object class for sanity sake
  my $args=new $args_class;
  is(ref $args,$V? 'Hash::AutoHash::Args': 'Hash::AutoHash::Args::V0',
     "$label class is $args_class - sanity check");

  my($args, @list, @list2, @list3);
  $args=new $args_class(-arg1=>'value11');
  is($args->arg1,'value11',"$label one arg. initial value");
  $args=new $args_class(-arg1=>'value11',-arg2=>'value21',-arg2=>'value22');
  @list2=@{$args->arg2};
  is($args->arg1,'value11',"$label single valued arg. initial value");
  cmp_deeply(\@list2,['value21','value22'],"$label multivalued arg. initial value");
  $args->arg1('changed value1');
  $args->arg2('changed value2');
  is($args->arg1,'changed value1',"$label single valued arg. changed value set by mutator");
  is($args->arg2,'changed value2',"$label multivalued arg changed to single value. changed value set by mutator");
  $args->arg3(qw(value31 value32 value33));
  @list3=@{$args->arg3};
  cmp_deeply(\@list3,['value31','value32','value33'],"$label multivalued arg set by mutator");

  $args=new $args_class
    (-ARG1=>'value11',
     -ARG2=>'value21',-arg2=>'value22',
     ArG3=>'value31','--arg3'=>'value32',-ARG3=>'value33',
    );
  @list2=@{$args->arg2};
  @list3=@{$args->arg3};
  is($args->arg1,'value11',"$label mixed case. 1-valued arg. initial value");
  cmp_deeply(\@list2,['value21','value22'],"$label mixed case. 2-valued arg. initial value");
  cmp_deeply(\@list3,['value31','value32','value33'],"$label mixed case. 3-valued arg. initial value");

  $args=new $args_class([-arg1=>'value11']);
  is($args->arg1,'value11',"$label ARRAY param");
  $args=new $args_class({-arg1=>'value11'});
  is($args->arg1,'value11',"$label HASH param");
  $args=new $args_class($args);
  is($args->arg1,'value11',"$label object param");

  # non-existent arg should return nothing. (not undef);
  $args=new $args_class(-arg1=>'value11');
  @list=($args->arg0);
  is(scalar @list,0,"$label non-existent arg");

  #################################################################################
  # test access via tied hash (ie, using hash notation)
  #################################################################################
  $args=new $args_class(-arg1=>'value11');
  is($args->{'-ARG1'},'value11',"$label get via hash");
  $args->{'-ArG1'}='value12';
  is($args->arg1,'value12',"$label set via hash");
  ok(exists $args->{'ARg1'},"$label exists via hash: true");
  ok(!exists $args->{'arg2'},"$label exists via hash: false");
  delete $args->{'ARg1'};
  ok(!exists $args->{'arg1'},"$label delete via hash");

  # non-existent arg should return nothing (not undef) but Perl doesn't do it this way!
  $args=new $args_class(-arg1=>'value11');
  @list=($args->{arg0});
  is(scalar @list,1,"$label non-existent arg via hash");

}

test_basics(0);
test_basics(1);

done_testing();
