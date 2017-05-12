use strict;
use integer;
use Devel::WeakRef;
use Test::Helper;

my %cnt;
{
  package Foo;
  sub new {
    my ($class, $key)=@_;
    $cnt{$key}++;
    bless \$key, $class;
  }
  sub DESTROY {
    my ($self)=@_;
    my $key=$$self;
    $cnt{$key}--;
  }
  sub action {
    my ($self)=@_;
    $$self * $$self;
  }
}

test {
  comm 'Creating $foo';
  my $foo=new Foo 3;
  ok $foo;
  ok($cnt{3}==1);
  ok($foo->action == 9);
  comm "\$foo is $foo";

  comm 'Creating weak ref';
  my $foo_=new Devel::WeakRef $foo;
  ok($cnt{3}==1);
  ok $foo_;
  ok($foo eq $foo_->deref);
  comm "\$foo_ is $foo_ (ref to " . $foo_->deref . ')';

  comm 'Using weak ref';
  ok($foo_->deref->action == 9);
  ok !$foo_->empty;

  comm 'Killing strong ref';
  $foo=17;
  ok($cnt{3}==0);
  ok defined $foo_;
  ok !defined $foo_->deref;
  ok +$foo_->empty;
  comm "\$foo_->deref is " . $foo_->deref if defined $foo_->deref;

  comm 'Killing weak ref';
  $foo_=19;
  ok($cnt{3}==0);

  comm 'Creating $bar';
  my $bar=new Foo 2;
  ok($cnt{2}==1);

  comm 'Creating weak ref 1';
  my $bar_1=new Devel::WeakRef $bar;
  ok($cnt{2}==1);
  ok($bar eq $bar_1->deref);

  comm 'Creating weak ref 2';
  my $bar_2=new Devel::WeakRef $bar;
  ok($cnt{2}==1);
  ok($bar eq $bar_1->deref);
  ok($bar eq $bar_2->deref);

  comm 'Using weak refs';
  ok($bar_1->deref->action == 4);
  ok($bar_2->deref->action == 4);

  comm 'Optional test -- checking that they are actually synonymous';
  ok($bar_1 eq $bar_2);

  comm 'Killing strong ref';
  $bar=15;
  ok($cnt{2}==0);
  ok !defined $bar_1->deref;
  ok !defined $bar_2->deref;

  comm 'Killing weak ref 1';
  $bar_1=13;
  ok($cnt{2}==0);
  ok !defined $bar_2->deref;

  comm 'Killing weak ref 2';
  $bar_2=11;
  ok($cnt{2}==0);

  comm 'Creating $baz';
  my $baz=new Foo 4;

  comm 'Creating weak ref';
  my $baz_=new Devel::WeakRef $baz;
  ok($cnt{4}==1);

  comm 'Using weak ref';
  ok($baz_->deref->action == 16);

  comm 'Killing weak ref';
  $baz_=9;

  comm 'Using strong ref';
  ok($baz->action == 16);
  ok($cnt{4}==1);

  comm 'Killing strong ref';
  $baz=77;
  ok($cnt{4}==0);

  comm 'Making sure reference arg is ensured';
  ok !runs {new Devel::WeakRef 17};

  comm 'Creating hash ref $quux';
  my $quux={a => 41};

  comm 'Creating weak ref';
  my $quux_=new Devel::WeakRef $quux;

  comm 'Using weak ref';
  ok($quux_->deref->{a} == 41);

  comm 'Testing duplication of weak ref';
  my $quux_2=$quux_;
  ok($quux_2->deref->{a} == 41);

  comm 'Killing strong ref';
  $quux=75;
  ok !defined $quux_->deref;
  ok !defined $quux_2->deref;

  comm 'Testing use of direct dereference--this part is sketchier';

  comm 'Creating $kwak';
  my $kwak=new Foo 49;
  ok($cnt{49} == 1);

  comm 'Creating weak reference';
  my $kwak_=new Devel::WeakRef $kwak;
  ok($cnt{49} == 1);

  comm 'Trying direct dereference';
  ok($$kwak == 49);
  ok(defined $$kwak_);
  ok($$kwak_ eq $kwak);
  ok($$$kwak_ == 49);
  ok($$kwak_->action == 49*49);
  ok($cnt{49} == 1);

  comm 'Killing strong ref';
  $kwak=2;
  ok($cnt{49} == 0);
  ok(!defined $$kwak_);

  comm 'Killing weak ref';
  $kwak_=7;

  comm 'Creating $neet to test that directly deref\'d weak refs are hard';
  my $neet=new Foo 12;
  my $neet_=new Devel::WeakRef $neet;
  ok($cnt{12} == 1);
  my $neet2=$$neet_;
  $neet=14;
  ok($cnt{12} == 1);
  ok($neet2->action == 144);	# That I can do in my head.
  ok($$neet_->action == 144);
  $neet2=7;
  ok($cnt{12} == 0);
  ok(!defined $$neet_);

  comm 'Trying to overwrite target of weak reference (bad idea)';
  my $quod=new Foo 11;
  my $quod_=new Devel::WeakRef $quod;
  ok($$$quod_ == 11);
  ok !runs {$$quod_=7};
  $quod=new Foo 13;
  $quod_=new Devel::WeakRef $quod;
  ok !runs {undef $$quod_};
  $quod=$quod_=1;

  comm 'Devel::WeakRef::Table section';
  ok(tie my %tb, 'Devel::WeakRef::Table');
  my $elta=new Foo 'a';
  ok($cnt{a} == 1);
  my $eltb=new Foo 'b';
  ok($cnt{b} == 1);
  my $res=($tb{a}=$elta);
  ok($res);
  ok($res eq $elta);
  $res=($tb{b}=$eltb);
  ok($res eq $eltb);
  $res=7;
  ok($tb{a} eq $elta);
  ok($tb{b} eq $eltb);
  ok($tb{aa}=$elta);
  ok($tb{a} eq $tb{aa});
  $elta=177;
  ok(!defined $tb{a});
  ok(!defined $tb{aa});
  ok($cnt{a} == 0);
  ok($tb{b} eq $eltb);
  ok(tie my %tb2, 'Devel::WeakRef::Table');
  ok($tb2{b}=$eltb);
  ok($tb{b} eq $tb2{b});
  $eltb=119;
  ok($cnt{b} == 0);
  ok(!defined $tb{b});
  ok(!defined $tb2{b});

  comm 'Catching overwrites';
  my $eltc=new Foo 'c';
  my $eltd=new Foo 'd';
  $tb{a}=$tb{aa}=$tb{aaa}=$eltc;
  ok($cnt{c} == 1);
  $tb{aa}=$eltd;
  ok($cnt{d} == 1);
  ok($tb{aaa} eq $eltc);
  ok($tb{aa} eq $eltd);
  $tb{aaa}=$eltd;
  ok($tb{aaa} eq $eltd);
  $eltc=$eltd=99;
  ok($cnt{c} == 0);
  ok($cnt{d} == 0);
  ok(!defined $tb{a});
  ok(!defined $tb{aa});
  ok(!defined $tb{aaa});
  %tb=();
};
