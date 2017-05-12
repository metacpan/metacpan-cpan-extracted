use lib qw(t);

use strict;
use Carp;
use Test::More;
use List::MoreUtils qw(uniq);
# use Test::Deep;               # CAUTION: Test::Deep defines 'isa'. breaks 'isa' tests below
# use Tie::Hash::MultiValue;	# an example tied hash class
use autohashUtil;
use Hash::AutoHash;

require "autohash.055.typicalchild.pm"; # defines TypicalChild
my $autohash_class='Hash::AutoHash';
my $child_class='TypicalChild';

# import Hash::AutoHash qw(autohash_new);
# my $autohash=autohash_new();
# ok($autohash && (ref($autohash) eq $autohash_class),'import autohash function via base class');

#################################################################################
# test TypicalChild UNIVERSAL methods
#################################################################################
my $child=new TypicalChild;
ok($child,'TypicalChild new');

my $can=can TypicalChild('can');
ok($can,'TypicalChild can: can');
my $can=can TypicalChild('new');
ok($can,'TypicalChild can: new');
my $can=can TypicalChild('not_defined');
ok(!$can,'TypicalChild can: can\'t');
my $can=$child->can('can');
ok($can,'TypicalChild object can: can');
my $can=$child->can('not_defined');
ok(!$can,'TypicalChild object can: can\'t');

my $isa=isa TypicalChild('TypicalChild');
ok($isa,'TypicalChild isa: is TypicalChild');
my $isa=isa TypicalChild('Hash::AutoHash');
ok($isa,'TypicalChild isa: is Hash::AutoHash');
my $isa=isa TypicalChild('UNIVERSAL');
ok($isa,'TypicalChild isa: is UNIVERSAL');
my $isa=isa TypicalChild('not_defined');
ok(!$isa,'TypicalChild isa: isn\'t');
my $isa=$child->isa('TypicalChild');
ok($isa,'TypicalChild object isa: is TypicalChild');
my $isa=$child->isa('not_defined');
ok(!$isa,'TypicalChild object isa: isn\'t');

# Test DOES in perls > 5.10. 
# Note: $^V returns real string in perls > 5.10, and v-string in earlier perls
#   regexp below fails in earlier perls. this is okay
my($perl_main,$perl_minor)=$^V=~/^v(\d+)\.(\d+)/; # perl version
if ($perl_main==5 && $perl_minor>=10) {
  my $does=DOES TypicalChild('TypicalChild');
  is($does,1,'TypicalChild DOES: is TypicalChild');
  my $does=DOES TypicalChild('Hash::AutoHash');
  ok($does,'TypicalChild DOES: is Hash::AutoHash');
  my $does=DOES TypicalChild('UNIVERSAL');
  is($does,1,'TypicalChild DOES: is UNIVERSAL');
  my $does=DOES TypicalChild('not_defined');
  ok(!$does,'TypicalChild DOES: doesn\'t');
  my $does=$child->DOES('TypicalChild');
  is($does,1,'TypicalChild object DOES: is TypicalChild');
  my $does=$child->DOES('not_defined');
  ok(!$does,'TypicalChild object DOES: doesn\'t');
}

my $version=VERSION TypicalChild;
is($version,$TypicalChild::VERSION,'TypicalChild VERSION');
is($child->VERSION,$version,'TypicalChild object VERSION');

my @imports=
  map {my $copy=$_; $copy=~s/^autohash/typicalchild/; $copy} 
  @Hash::AutoHash::SUBCLASS_EXPORT_OK;
import TypicalChild @imports;
pass('import all functions');

#################################################################################
# test TypicalChild keys, AUTOLOADED methods
#################################################################################
# NOTE: $autohash used as global in autohashUtil test functions. 
#       do NOT 'my' it!! do NOT use other variable name, eg, 'child'
$autohash=new TypicalChild (key1=>'value11',key2=>'value21');
cmp_autohash('TypicalChild: 0th values',[undef,['value11'],['value21']]);
$autohash->key1('value12');
$autohash->key2('value22');
cmp_autohash('TypicalChild: 1st values',[undef,['value11','value12'],['value21','value22']]);

#################################################################################
# test TypicalChild special keys
#################################################################################
test_special_keys(new TypicalChild,1,sub {[$_[0]]});

# use Test::Deep;	 # do it here to avoid breaking 'isa' tests above
# {		 # used nested block to avoid global variables
#   my @keys;
#   {
#     no strict 'refs';
#     @keys=uniq(@COMMON_SPECIAL_KEYS,
# 	       # qw(import new can isa DOES VERSION AUTOLOAD DESTROY),
# 	       @Hash::AutoHash::EXPORT_OK,@imports);  
#   }
#   my $child=new TypicalChild;
#   my(@ok,@fail);
#   for my $key (@keys) {
#     my $value="value_$key";
#     $child->$key($value);	# set value
#     my $actual=$child->$key;	# get value
# #    (scalar(@$actual)==1 && $actual->[0] eq $value)? push(@ok,$key): push(@fail,$key);
#     eq_deeply($actual,[$value])? push(@ok,$key): push(@fail,$key);
#   }
#   # like 'report'
#   my $label="TypicalChild special keys";
#   unless (@fail) {
# #     pass("$label. keys=@keys");
#     pass($label);
#   } else {
#     fail($label);
#     diag(scalar(@ok)." keys have correct values: @ok");
#     diag(scalar(@fail)." keys have wrong values: @fail");
#   }
# }

#################################################################################
# test TypicalChild exported functions
#################################################################################
use Test::Deep;	 # do it here to avoid breaking 'isa' tests above
my $child=new TypicalChild (key1=>'value11',key2=>'value21');

my($actual)=typicalchild_get($child,'key1');
cmp_deeply($actual,['value11'],'typicalchild_get');

typicalchild_set($child,key2=>'value22');
my $actual1=$child->key1;
my $actual2=$child->key2;
cmp_deeply($actual1,['value11'],'typicalchild_set: unchanged key');
cmp_deeply($actual2,['value21','value22'],'typicalchild_set: changed key');

typicalchild_clear($child);
ok(!defined($child->key1)&&!defined($child->key2)&&!scalar(keys %$child),'typicalchild_clear');

my $child=new TypicalChild (key1=>'value11',key2=>'value21');
typicalchild_delete($child,'key2');
my $actual1=$child->key1;
my $actual2=$child->key2;
cmp_deeply($actual1,['value11'],'typicalchild_delete 1 key: unchanged key');
cmp_deeply($actual2,undef,'typicalchild_delete 1 key: deleted key');

my $child=new TypicalChild (key0=>'value00',key1=>'value11',key2=>'value21');
typicalchild_delete($child,qw(key0 key2));
my $actual0=$child->key0;
my $actual1=$child->key1;
my $actual2=$child->key2;
cmp_deeply($actual1,['value11'],'typicalchild_delete 2 keys: unchanged key');
cmp_deeply([$actual0,$actual2],[undef,undef],'typicalchild_delete 2 keys: deleted keys');

my $actual1=typicalchild_exists($child,'key1');
my $actual2=typicalchild_exists($child,'key2');
ok($actual1,'typicalchild_exists: true');
ok(!$actual2,'typicalchild_exists: false');

my $child=new TypicalChild (key1=>'value11',key2=>'value21');
my %actual;
while(my($key,$value)=typicalchild_each($child)) {
  $actual{$key}=$value;
}
cmp_deeply(\%actual,{key1=>['value11'],key2=>['value21']},'typicalchild_each list context');
my @actual;
while(my $key=typicalchild_each($child)) {
  push(@actual,$key);
}
cmp_set(\@actual,[qw(key1 key2)],'typicalchild_each scalar context');

my $child=new TypicalChild (key1=>'value11',key2=>'value21');
my @actual=typicalchild_keys($child);
cmp_set(\@actual,[qw(key1 key2)],'typicalchild_keys');

my @actual=typicalchild_values($child);
cmp_set(\@actual,[['value11'],['value21']],'typicalchild_values');

my $actual=typicalchild_count($child);
is($actual,2,'typicalchild_count');

my $actual=typicalchild_empty($child);
ok(!$actual,'typicalchild_empty: false');
my $actual=typicalchild_notempty($child);
ok($actual,'typicalchild_notempty: true');

typicalchild_clear($child);
my $actual=typicalchild_empty($child);
ok($actual,'typicalchild_empty: true');
my $actual=typicalchild_notempty($child);
ok(!$actual,'typicalchild_notempty: false');

done_testing();
