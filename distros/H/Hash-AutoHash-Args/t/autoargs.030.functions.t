use lib qw(t);
use Carp;
use Hash::AutoHash::Args;
use Hash::AutoHash::Args::V0;
use Test::More;
use Test::Deep;

#################################################################################
# test class methods called directly in-module. version 0 only
#################################################################################
my $args=Hash::AutoHash::Args::V0::fix_args
  (-ARG1=>'value11',
   -ARG2=>'value21',-arg2=>'value22',
   ArG3=>'value31','--arg3'=>'value32',-ARG3=>'value33',
  );
cmp_deeply($args,{arg1=>'value11',
		  arg2=>['value21','value22'],
		  arg3=>['value31','value32','value33']},
	   'V0 fix_args in-module');

@keywords=qw(arg1 -arg1 ArG1 -ArG1);
@correct=('arg1') x scalar @keywords;
@actual=Hash::AutoHash::Args::V0::fix_keyword(@keywords);
cmp_deeply(\@actual,\@correct,'V0 fix_keyword in-module');
@actual=Hash::AutoHash::Args::V0::fix_keywords(@keywords);
cmp_deeply(\@actual,\@correct,'V0 fix_keywords in-module');

is(Hash::AutoHash::Args::V0::is_keyword(-arg=>'value'),1,'V0 is_keyword in-module: true');
is(Hash::AutoHash::Args::V0::is_keyword('value'),'','V0 is_keyword in-module: false');
is(Hash::AutoHash::Args::V0::is_positional('value'),1,'V0 is_positional in-module: true');
is(Hash::AutoHash::Args::V0::is_positional(-arg=>'value'),'','V0 is_positional in-module: false');

#################################################################################
# test exported functions
#################################################################################
sub test_exported_functions {
  my($V)=@_;
  my $args_class=$V? 'Hash::AutoHash::Args': 'Hash::AutoHash::Args::V0';
  my $label=$V? 'V1': 'V0';
  # test object class for sanity sake
  my $args=new $args_class;
  is(ref $args,$V? 'Hash::AutoHash::Args': 'Hash::AutoHash::Args::V0',
     "$label class is $args_class - sanity check");

  my @imports=($V? @Hash::AutoHash::Args::EXPORT_OK: @Hash::AutoHash::Args::V0::EXPORT_OK);
  import $args_class @imports;
  pass("$label import all functions");

  my $args=new $args_class (arg1=>'value11',arg2=>'value21');
  my @actual=get_args($args,qw(arg1 arg2));
  cmp_deeply(\@actual,['value11','value21'],"$label get_args exported. list");
  my $actual=get_args($args,qw(arg1 arg2));
  cmp_deeply($actual,['value11','value21'],"$label get_args exported. ARRAY");
  my %actual=getall_args($args);
  cmp_deeply(\%actual,{arg1=>'value11',arg2=>'value21'},"$label getall_args exported");
  set_args($args,arg2=>'value22');
  my $actual1=$args->arg1;
  my $actual2=$args->arg2;
  cmp_deeply($actual1,'value11',"$label set_args exported: unchanged arg (keyword=>value form)");
  cmp_deeply($actual2,'value22',"$label set_args exported: changed arg (keyword=>value form)");
  if ($V) {
    set_args($args,['arg2'],['value23']);
    my $actual1=$args->arg1;
    my $actual2=$args->arg2;
    cmp_deeply($actual1,'value11',"$label set_args exported: unchanged arg (separate ARRAYs form)");
    cmp_deeply($actual2,'value23',"$label set_args exported: changed arg (separate ARRAYs form)");
  }
  my $args=fix_args
    (-ARG1=>'value11',
     -ARG2=>'value21',-arg2=>'value22',
     ArG3=>'value31','--arg3'=>'value32',-ARG3=>'value33',
    );
  cmp_deeply($args,{arg1=>'value11',
		    arg2=>['value21','value22'],
		    arg3=>['value31','value32','value33']},
	     "$label fix_args exported");

  @keywords=qw(arg1 -arg1 ArG1 -ArG1);
  @correct=('arg1') x scalar @keywords;
  @actual=fix_keyword(@keywords);
  cmp_deeply(\@actual,\@correct,"$label fix_keyword exported");
  @actual=fix_keywords(@keywords);
  cmp_deeply(\@actual,\@correct,"$label fix_keywords exported");

  is(is_keyword(-arg=>'value'),1,"$label is_keyword exported: true");
  is(is_keyword('value'),'',"$label is_keyword exported: false");
  is(is_positional('value'),1,"$label is_positional exported: true");
  is(is_positional(-arg=>'value'),'',"$label is_positional exported: false");

  my $args=new $args_class (arg1=>'value11',arg2=>'value21');
 
  my($actual)=autoargs_get($args,'arg1');
  cmp_deeply($actual,'value11',"$label autoargs_get. list");
  my $actual=autoargs_get($args,'arg1');
  cmp_deeply($actual,['value11'],"$label autoargs_get. ARRAY");

  autoargs_set($args,arg2=>'value22');
  my $actual1=$args->arg1;
  my $actual2=$args->arg2;
  cmp_deeply($actual1,'value11',"$label autoargs_set: unchanged arg (keyword=>value form)");
  cmp_deeply($actual2,'value22',"$label autoargs_set: changed arg (keyword=>value form)");
  if ($V) {
    autoargs_set($args,['arg2'],['value23']);
    my $actual1=$args->arg1;
    my $actual2=$args->arg2;
    cmp_deeply($actual1,'value11',"$label autoargs_set exported: unchanged arg (separate ARRAYs form)");
    cmp_deeply($actual2,'value23',"$label autoargs_set exported: changed arg (separate ARRAYs form)");
  }

  autoargs_clear($args);
  ok(!defined($args->arg1)&&!defined($args->arg2)&&!scalar(args %$args),"$label autoargs_clear");

  my $args=new $args_class (arg1=>'value11',arg2=>'value21');
  autoargs_delete($args,'arg2');
  my $actual1=$args->arg1;
  my $actual2=$args->arg2;
  cmp_deeply($actual1,'value11',"$label autoargs_delete 1 arg: unchanged arg");
  cmp_deeply($actual2,undef,"$label autoargs_delete 1 arg: deleted arg");

  my $args=new $args_class (arg0=>'value00',arg1=>'value11',arg2=>'value21');
  autoargs_delete($args,qw(arg0 arg2));
  my $actual0=$args->key0;
  my $actual1=$args->arg1;
  my $actual2=$args->arg2;
  cmp_deeply($actual1,'value11',"$label autoargs_delete 2 args: unchanged arg");
  cmp_deeply([$actual0,$actual2],[undef,undef],"$label autoargs_delete 2 args: deleted args");

  my $actual1=autoargs_exists($args,'arg1');
  my $actual2=autoargs_exists($args,'arg2');
  ok($actual1,"$label autoargs_exists: true");
  ok(!$actual2,"$label autoargs_exists: false");

  my $args=new $args_class (arg1=>'value11',arg2=>'value21');
  my %actual;
  while(my($arg,$value)=autoargs_each($args)) {
    $actual{$arg}=$value;
  }
  cmp_deeply(\%actual,{arg1=>'value11',arg2=>'value21'},"$label autoargs_each list context");
  my @actual;
  while(my $arg=autoargs_each($args)) {
    push(@actual,$arg);
  }
  cmp_set(\@actual,[qw(arg1 arg2)],"$label autoargs_each scalar context");

  my $args=new $args_class (arg1=>'value11',arg2=>'value21');
  my @actual=autoargs_keys($args);
  cmp_set(\@actual,[qw(arg1 arg2)],"$label autoargs_keys");

  my @actual=autoargs_values($args);
  cmp_set(\@actual,['value11','value21'],"$label autoargs_values");

  my $actual=autoargs_count($args);
  is($actual,2,"$label autoargs_count");

  my $actual=autoargs_empty($args);
  ok(!$actual,"$label autoargs_empty: false");
  my $actual=autoargs_notempty($args);
  ok($actual,"$label autoargs_notempty: true");

  autoargs_clear($args);
  my $actual=autoargs_empty($args);
  ok($actual,"$label autoargs_empty: true");
  my $actual=autoargs_notempty($args);
  ok(!$actual,"$label autoargs_notempty: false");

  # cannot test autoargs_alias here.
  # must be imported at compile-time for prototype to work
}
test_exported_functions(0);
test_exported_functions(1);

done_testing();
