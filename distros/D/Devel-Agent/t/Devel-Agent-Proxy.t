use Modern::Perl;
use Test::More qw(no_plan);
use FindBin qw($Bin);
use lib $Bin;
use Data::Dumper;
$|=1;
require Devel::Agent;
require TestMe;
require TestMe2;

my $pkg='Devel::Agent::Proxy';
require_ok($pkg);
use_ok($pkg);

{
  my $agent=new DB;
  

  my $class='TestMe';
  my $obj=$class->new;
  my $self=$pkg->new(
    debugger_agent=>$agent,
    proxy_class_name=>'TestMe',
    proxied_object=>$obj,
    current_method=>'new',
  );

  isa_ok($self,$class);

  foreach my $method (qw(test_a test1)) {
    my $cb=$self->can($method);
    ok($cb,"Should pass \$self->can('$method')");
  }
  $obj->test1('test');
  cmp_ok($self->test1,'eq',$obj->test1);
}
{
  my $agent=new DB;

  my $class='TestMe2';
  my $obj=$class->new;
  my $self=$pkg->new(
    debugger_agent=>$agent,
    proxy_class_name=>$class,
    proxied_object=>$obj,
    current_method=>'new',
  );

  isa_ok($self,$class);

  foreach my $method (qw(echo test_a test1)) {
    my $cb=$self->can($method);
    ok($cb,"Should pass \$self->can('$method')");
  }
  $obj->test1('test');

  cmp_ok($self->test1,'eq',$obj->test1);

  my $args=[1,2,3];
  is_deeply($self->echo(@$args),$args,'validate subclassed proxied autoload');

  ok(!$self->___db_stack_filter(undef,{caller_class=>$pkg}),'should filter out any calls we make to ourselves');

  my $frame={
    caller_class=>'main',
    class_method=>$pkg.'::bogus',
    raw_method=>$pkg.'::bogus',
  };
  $self->___db_stack_filter(undef,$frame);
  is_deeply($frame,{
    caller_class=>'main',
    class_method=>$class.'::bogus',
    raw_method=>$class.'::bogus',
  },'ensure we rewrite the frame correctly');

}
