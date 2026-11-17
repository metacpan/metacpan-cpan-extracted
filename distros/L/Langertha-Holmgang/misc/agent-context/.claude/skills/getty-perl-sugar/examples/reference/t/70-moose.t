use strict;
use warnings;
use Test::More;
BEGIN {
  eval { require Moose; 1 } or do {
    BAIL_OUT('Moose is required by strict integration mode') if $ENV{SUGAR_REQUIRE_INTEGRATIONS};
    plan skip_all => 'Moose is not installed; no simulated substitute is used';
  };
}
use Example::Sugar::Registry ();
require Example::Flow::Check;
my $check=Example::Flow::Check->new(url=>'https://example.invalid',deep=>1);
my $result=$check->run;
is_deeply([sort keys %$result],[qw(deeper parts probe)],'Moose class and role declarations execute');
ok($check->does('Example::Sugar::Runner'),'runner role applied automatically');
ok(!$check->can('step'),'class DSL keyword cleaned from namespace');
ok(!Example::Flow::Probe->can('step'),'role DSL keyword cleaned from namespace');
is(Example::Sugar::Registry::entries('Example::Flow::Probe')->[0]{owner},'Example::Flow::Probe','with_meta registers under role owner');
my $shallow=Example::Flow::Check->new(url=>'x');
ok(!exists($shallow->run->{deeper}),'false condition skips optional step');
is($shallow->results->{parts}{len},1,'results are isolated per instance');
is($check->results->{parts}{len},23,'other instance state unchanged');
my $ok=eval q{
  package Test::LateRole;
  use Example::Sugar::RoleDSL;
  step 'Late role' => late_role => sub { {ok=>1} };
  no Example::Sugar::RoleDSL;
  package Test::LateClass;
  use Example::Sugar;
  step 'Class first' => class_first => sub { {ok=>1} };
  with 'Test::LateRole';
  no Example::Sugar;
  __PACKAGE__->meta->make_immutable;
  1;
};
ok($ok,"late role fixture loads: $@");
is_deeply([sort keys %{Test::LateClass->new->run}],[qw(class_first late_role)],'with after declaration is visible at lookup');
$ok=eval q{
  package Test::Parent;
  use Example::Sugar;
  step 'Parent' => parent => sub { {ok=>1} };
  no Example::Sugar;
  __PACKAGE__->meta->make_immutable;
  package Test::Child;
  use Example::Sugar;
  extends 'Test::Parent';
  step 'Child' => child => sub { {ok=>1} }, requires=>['parent'];
  no Example::Sugar;
  __PACKAGE__->meta->make_immutable;
  1;
};
ok($ok,"inheritance fixture loads: $@");
is_deeply([map {$_->{key}} @{Test::Child->steps->{steps}}],[qw(parent child)],'parent class registry included');
is_deeply([sort keys %{Test::Child->new->run}],[qw(child parent)],'inherited and local steps execute');
done_testing;
