#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1+15+15;
use constant {
    H_SERVER1 => 'http://hessian.caucho.com/test/test',
    H_SERVER2 => 'http://hessian.caucho.com/test/test2'
};

BEGIN{ use_ok('Hessian::Tiny::Client'); }

my $foo = new_ok('Hessian::Tiny::Client' => [ url => H_SERVER1, hessian_flag => 1 ]);
my $bar = new_ok('Hessian::Tiny::Client' => [ url => H_SERVER1, ]);
BAIL_OUT('client not initiated') unless defined $foo && defined $bar;
my($stat0,$stat,$res,$res2,$tmp_str,$tmp_str2);

my $noSuchMeth_test = sub {
  plan tests => 5;
  can_ok($foo, 'call');
  ($stat0,$res) = $foo->call('noSuchMeth');
  ok($stat0 != 0);

SKIP: {
    skip 'Server cannot be reached',3 unless $stat0 == 1;
          isa_ok($res, 'Hessian::Type::Fault');
          is($res->{code}, 'NoSuchMethodException');
          is($res->{message}, 'The service has no method named: noSuchMeth');
      }
};
my $NullTrueFalse_test = sub {
  if($stat0 != 1){ plan skip_all => 'server not reachable' }
  else{ plan tests => 22 }

  ($stat,$res) = $foo->call('methodNull');
  is($stat,0);
  is_deeply($res,Hessian::Type::Null->new() , 'methodNull');
  ($stat,$res) = $bar->call('methodNull');
  is($stat,0);
  is($res,undef);

  ($stat,$res) = $foo->call('replyNull');
  is($stat,0,'replyNull');
  isa_ok($res,'Hessian::Type::Null','replyNull');
  ($stat,$res) = $foo->call('argNull',$res);
  is($stat,0);
  isa_ok($res,'Hessian::Type::True','argNull');
  ($stat,$res) = $bar->call('replyNull');
  is($stat,0);
  is($res,undef);

  ($stat,$res) = $foo->call('replyTrue');
  is($stat,0);
  isa_ok($res,'Hessian::Type::True','replyTrue');
  ($stat,$res) = $foo->call('argTrue',$res);
  is($stat,0);
  isa_ok($res,'Hessian::Type::True','argTrue');
  ($stat,$res) = $bar->call('replyTrue');
  is($stat,0);
  is($res,1);

  ($stat,$res) = $foo->call('replyFalse');
  is($stat,0);
  isa_ok($res,'Hessian::Type::False','replyFalse');
  ($stat,$res) = $foo->call('argFalse',$res);
  is($stat,0);
  isa_ok($res,'Hessian::Type::True','argFalse');
  ($stat,$res) = $bar->call('replyFalse');
  is($stat,0);
  is($res,undef);

};
my $Integer_test = sub {
  my @ints = qw(
    0 1 47 m16 0x30 0x7ff m17 m0x800 0x800 0x3ffff
    m0x801 m0x40000 0x40000 0x7fffffff m0x40001 m0x80000000
  );
  if($stat0 != 1){ plan skip_all => 'server not reachable' }
  else{ plan tests => 6 * scalar @ints }

  for my $n (@ints){
    my $m = $n;
    $m =~ tr/m/-/;
    ($stat,$res) = $foo->call("replyInt_$n");
    is($stat,0);
    isa_ok($res,'Hessian::Type::Integer');
    ($stat,$res) = $foo->call("argInt_$n",$res);
    is($stat,0);
    isa_ok($res,'Hessian::Type::True',"argInt_$n");
    ($stat,$res) = $bar->call("replyInt_$n");
    is($stat,0);
    is($res,eval$m);
  }
};
my $Long_test = sub {
  my @longs = qw(
    0 1 15 m8 0x10 0x7ff m9 m0x800 0x800 0x3ffff m0x801
    m0x40000 0x40000 0x7fffffff m0x40001 m0x80000000 0x80000000 m0x80000001
  );
  if($stat0 != 1){ plan skip_all => 'server not reachable' }
  else{ plan tests => 8 * scalar @longs }

  for my $n (@longs){
    my $m = $n;
    $m =~ tr/m/-/;
    ($stat,$res) = $foo->call("replyLong_$n");
    isa_ok($res, 'Math::BigInt');
    is($res->bcmp(Math::BigInt->new($m)),0, "replyLong_$n");
    is($stat,0);
    isa_ok($res,'Math::BigInt');
    ($stat,$res) = $foo->call("argLong_$n",$res);
    is($stat,0);
    isa_ok($res,'Hessian::Type::True',"argLong_$n");
    ($stat,$res) = $bar->call("replyLong_$n");
    is($stat,0);
    ok($res eq Math::BigInt->new($m)->bstr);
  }
};
my $Double_test = sub {
  my @doubles = qw(
    0_0 1_0 2_0 127_0 m128_0 128_0 m129_0
    32767_0 m32768_0 0_001 m0_001 65_536 3_14159 
  );
  if($stat0 != 1){ plan skip_all => 'server not reachable' }
  else{ plan tests => 6 * scalar @doubles }

  for my $n (@doubles){
    my $m = $n; $m =~ tr/m_/-./;
    ($stat,$res) = $foo->call("replyDouble_$n");
    is($stat,0, "replyDouble_$n");
    isa_ok($res,'Hessian::Type::Double');
    ($stat,$res) = $foo->call("argDouble_$n",$res);
    is($stat,0);
    isa_ok($res,'Hessian::Type::True', "argDouble_$n");
    ($stat,$res) = $bar->call("replyDouble_$n");
    is($stat,0);
    ok(compare_float($res,$m));
  }
};
my $Date_test = sub {
  if($stat0 != 1){ plan skip_all => 'server not reachable' }
  else{ plan tests => 4 * 3 + 6 }

  for(qw( 0 1 2 )){
    ($stat,$res) = $foo->call("replyDate_$_");
    is($stat,0,"replyDate_$_");
    isa_ok($res,'Hessian::Type::Date');
    ($stat,$res) = $foo->call("argDate_$_",$res);
    is($stat,0);
    isa_ok($res,'Hessian::Type::True', "argDate_$_");
  }
  ($stat,$res) = $bar->call("replyDate_0");
  is($stat,0);
  is_deeply($res,Math::BigInt->new(0));
  ($stat,$res) = $bar->call("replyDate_1");
  is($stat,0);
  is_deeply($res,Math::BigInt->new('894621091'));
  ($stat,$res) = $bar->call("replyDate_2");
  is($stat,0);
  is_deeply($res,Math::BigInt->new('894621060'));
};
my $String_test = sub {
  my @strings = qw ( 0 1 31 32 1023 1024 65536 );
  if($stat0 != 1){ plan skip_all => 'server not reachable' }
  else{ plan tests => 2 + (6 * scalar @strings) }

  ($stat,$res) = $foo->call("replyString_null");
  isa_ok($res,'Hessian::Type::Null');
  is($stat,0,"replyString_null");

  for my$n (@strings) {
    ($stat,$res) = $foo->call("replyString_$n");
    is($stat,0,"replyString_$n");
    isa_ok($res,'Hessian::Type::String');
    ($stat,$res2) = $bar->call("replyString_$n");
    is($stat,0, "replyString_$n return status 0");
    is($res2,$res->{data}, "String same with or without hessian_flag");
    ($stat,$res) = $foo->call("argString_$n",$res);
    isa_ok($res,'Hessian::Type::True', "argString_$n matches replyString_$n");
    is($stat,0,"argString_$n");
  }
};
my $Binary_test = sub {
  my @binaries = qw( 0 1 15 16 1023 1024 65536 );
  if($stat0 != 1){ plan skip_all => 'server not reachable' }
  else{ plan tests => 2 + (6 * scalar @binaries) }

  ($stat,$res) = $foo->call("replyBinary_null");
  isa_ok($res,'Hessian::Type::Null');
  is($stat,0,"replyBinary_null");

  for my $n (@binaries){
    ($stat,$res) = $foo->call("replyBinary_$n");
    is($stat,0,"replyBinary_$n");
    isa_ok($res,'Hessian::Type::Binary');
    ($stat,$res2) = $bar->call("replyBinary_$n");
    is($stat,0);
    is($res2,$res->{data});
    ($stat,$res) = $foo->call("argBinary_$n",$res);
    isa_ok($res,'Hessian::Type::True');
    is($stat,0,"argBinary_$n");
  }
};
my $UntypedFixedList_test = sub {
  my @ufl = qw( 0 1 7 8 );
  if($stat0 != 1){ plan skip_all => 'server not reachable' }
  else{ plan tests => 8 * scalar @ufl }

  my %r = (0=>[],1=>[1],7=>[1..7],8=>[1..8]);
  for my $n (@ufl){
    ($stat,$res) = $foo->call("replyUntypedFixedList_$n");
    is($stat,0,"replyUntypedFixedList_$n");
    isa_ok($res,'Hessian::Type::List');
    ($stat,$res2) = $bar->call("replyUntypedFixedList_$n");
    is($stat,0);
    isa_ok($res2,'ARRAY');
    is_deeply($res2,$r{$n});
    is($n, scalar @{$res2});
    ($stat,$res) = $foo->call("argUntypedFixedList_$n",$res);
    isa_ok($res,'Hessian::Type::True');
    is($stat,0,"argUntypedFixedList_$n");
  }
};
my $TypedFixedList_test = sub {
  my @tfl = qw( 0 1 7 8 );
  if($stat0 != 1){ plan skip_all => 'server not reachable' }
  else{ plan tests => 8 * scalar @tfl }

  my %r = (0=>[],1=>[1],7=>[1..7],8=>[1..8]);
  for my $n (@tfl){
    ($stat,$res) = $foo->call("replyTypedFixedList_$n");
    is($stat,0,"replyTypedFixedList_$n");
    isa_ok($res,'Hessian::Type::List');
    ($stat,$res2) = $bar->call("replyTypedFixedList_$n");
    is($stat,0);
    isa_ok($res2,'ARRAY');
    is_deeply($res2,$r{$n});
    is($n,scalar @{$res2});
    ($stat,$res) = $foo->call("argTypedFixedList_$n",$res);
    isa_ok($res,'Hessian::Type::True');
    is($stat,0,"argTypedFixedList_$n");
  }
};
my $UntypedMap_test = sub {
  my @um = qw( 1 1 2 3 );
  if($stat0 != 1){ plan skip_all => 'server not reachable' }
  else{ plan tests => (7 * scalar @um) - 1 }

  my %r = (0=>{},1=>{'a',0},2=>{0=>'a',1=>'b'},3=>{['a'],0});
  for my $n (@um){
    ($stat,$res) = $foo->call("replyUntypedMap_$n");
    is($stat,0,"replyUntypedMap_$n");
    isa_ok($res,'Hessian::Type::Map');
    ($stat,$res2) = $bar->call("replyUntypedMap_$n");
    is($stat,0);
    isa_ok($res2,'HASH');
    is_deeply($res2,$r{$n}) unless $n > 2; # can't be done
    ($stat,$res) = $foo->call("argUntypedMap_$n",$res);
    isa_ok($res,'Hessian::Type::True');
    is($stat,0,"argUntypedMap_$n");
  }
};
my $TypedMap_test = sub {
  my @tm = qw( 0 1 2 3 );
  if($stat0 != 1){ plan skip_all => 'server not reachable' }
  else{ plan tests => (7 * scalar @tm) - 1 }

  tie my %h,'Tie::RefHash';
  my $a = ['a'];
  $h{$a} = 0;
  my %r = (0=>{},1=>{'a',0},2=>{0=>'a',1=>'b'},3=>\%h);
  for my $n (@tm){
    ($stat,$res) = $foo->call("replyTypedMap_$n");
    is($stat,0,"replyTypedMap_$n");
    isa_ok($res,'Hessian::Type::Map');
    ($stat,$res2) = $bar->call("replyTypedMap_$n");
    is($stat,0);
    isa_ok($res2,'HASH');
    is_deeply($res2,$r{$n}) unless $n > 2; # can't be done
    ($stat,$res) = $foo->call("argTypedMap_$n",$res);
    isa_ok($res,'Hessian::Type::True');
    is($stat,0,"argTypedMap_$n");
  }
};
my $Object_test = sub {
  my @objects = qw( 0 16 1 2 2a 2b 3 );
  if($stat0 != 1){ plan skip_all => 'server not reachable' }
  else{ plan tests => 5 * scalar @objects }

  my %r = (0=>{},16=>[{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}],
  1=>{_value=>0},2=>[{_value=>0},{_value=>1}],
  '2a'=>[{_value=>0},{_value=>0}],'2b'=>[{_value=>0},{_value=>0}],
  3=>{_first=>'a'});
  $r{3}->{_rest} = $r{3};
  for my $n (@objects) {
    ($stat,$res) = $foo->call("replyObject_$n");
    is($stat,0,"replyObject_$n");
    ($stat,$res2) = $bar->call("replyObject_$n");
    is($stat,0);
    is_deeply($res2,$r{$n});
    ($stat,$res) = $foo->call("argObject_$n",$res);
    isa_ok($res,'Hessian::Type::True');
    is($stat,0,"argObject_$n");
  }
};

sub compare_float { return ($_[0] == $_[1] || abs($_[0]*1e-3) > abs($_[0]-$_[1])) }

subtest 'v1:noSuchMeth'         => \&$noSuchMeth_test;
subtest 'v1:Null,True,False'    => \&$NullTrueFalse_test;
subtest 'v1:Integer'            => \&$Integer_test;
subtest 'v1:Long'               => \&$Long_test;
subtest 'v1:Double'             => \&$Double_test;
subtest 'v1:Date'               => \&$Date_test;
subtest 'v1:String'             => \&$String_test;
subtest 'v1:Binary'             => \&$Binary_test;
subtest 'v1:UntypedFixedList'   => \&$UntypedFixedList_test;
subtest 'v1:TypedFixedList'     => \&$TypedFixedList_test;
subtest 'v1:UntypedMap'         => \&$UntypedMap_test;
subtest 'v1:TypedMap'           => \&$TypedMap_test;
subtest 'v1:Object'             => \&$Object_test;

$foo = new_ok('Hessian::Tiny::Client' => [ version => 2, url => H_SERVER2, hessian_flag => 1 ]);
$bar = new_ok('Hessian::Tiny::Client' => [ version => 2, url => H_SERVER2, ]); 
subtest 'v2:noSuchMeth'         => \&$noSuchMeth_test;
subtest 'v2:Null,True,False'    => \&$NullTrueFalse_test;
subtest 'v2:Integer'            => \&$Integer_test;
subtest 'v2:Long'               => \&$Long_test;
subtest 'v2:Double'             => \&$Double_test;
subtest 'v2:Date'               => \&$Date_test;
subtest 'v2:String'             => \&$String_test;
subtest 'v2:Binary'             => \&$Binary_test;
subtest 'v2:UntypedFixedList'   => \&$UntypedFixedList_test;
subtest 'v2:TypedFixedList'     => \&$TypedFixedList_test;
subtest 'v2:UntypedMap'         => \&$UntypedMap_test;
subtest 'v2:TypedMap'           => \&$TypedMap_test;
subtest 'v2:Object'             => \&$Object_test;

