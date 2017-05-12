use lib qw(t);

use strict;
use Carp;
use Test::More;
# use Test::Deep;               # CAUTION: Test::Deep defines 'isa'. breaks 'isa' tests below
# use Tie::Hash::MultiValue;	# an example tied hash class
use autohashUtil;
use Hash::AutoHash;

require "autohash.050.subclass.pm"; # defines classes Child, Grandchild
my $autohash_class='Hash::AutoHash';
my $child_class='Child';
my $grandchild_class='Grandchild';

# import Hash::AutoHash qw(autohash_new);
# my $autohash=autohash_new();
# ok($autohash && (ref($autohash) eq $autohash_class),'import autohash function via base class');

################################################################################
# test computation of @EXPORT_OK, @SUBCLASS_EXPORT_OK, %EXPORT_OK
################################################################################
my @export_ok=qw(autohash_new child_new grandchild_new not_defined
		 grandchild_xxx grandchild_yyy
		 grandchild_autohash_new grandchild_child_new grandchild_grandchild_new);
my @subclass_export_ok=@export_ok;
my %export_ok=
  (autohash_new=>'Hash::AutoHash::helper::autohash_new',
   child_new=>'Child::helper::child_new',
   grandchild_autohash_new=>'Hash::AutoHash::helper::autohash_new',
   grandchild_child_new=>'Child::helper::child_new',
   grandchild_grandchild_new=>'Grandchild::helper::grandchild_new',
   grandchild_new=>'Grandchild::helper::grandchild_new',
   grandchild_xxx=>'Hash::AutoHash::helper::autohash_keys',
   grandchild_yyy=>'Hash::AutoHash::helper::autohash_values',
   not_defined=>undef);
cmp_set(\@Grandchild::EXPORT_OK,\@export_ok,'Grandchild @EXPORT_OK');
cmp_set(\@Grandchild::SUBCLASS_EXPORT_OK,\@subclass_export_ok,'Grandchild @SUBCLASS_EXPORT_OK');
cmp_deeply(\%Grandchild::EXPORT_OK,\%export_ok,'Grandchild %EXPORT_OK');

#################################################################################
# test Grandchild class methods
#################################################################################
my $grandchild=new Grandchild;
ok($grandchild,'Grandchild new');

my $can=can Grandchild('can');
ok($can,'Grandchild can: can');
my $can=can Grandchild('child_method');
ok($can,'Grandchild can: child_method');
my $can=can Grandchild('grandchild_method');
ok($can,'Grandchild can: grandchild_method');
my $can=can Grandchild('not_defined');
ok(!$can,'Grandchild can: can\'t');
my $can=$grandchild->can('can');
ok($can,'Grandchild object can: can');
my $can=$grandchild->can('not_defined');
ok(!$can,'Grandchild object can: can\'t');

my $isa=isa Grandchild('Grandchild');
ok($isa,'Grandchild isa: is Grandchild');
my $isa=isa Grandchild('Child');
ok($isa,'Grandchild isa: is Child');
my $isa=isa Grandchild('Hash::AutoHash');
ok($isa,'Grandchild isa: is Hash::AutoHash');
my $isa=isa Grandchild('UNIVERSAL');
ok($isa,'Grandchild isa: is UNIVERSAL');
my $isa=isa Grandchild('not_defined');
ok(!$isa,'Grandchild isa: isn\'t');
my $isa=$grandchild->isa('Grandchild');
ok($isa,'Grandchild object isa: is Grandchild');
my $isa=$grandchild->isa('not_defined');
ok(!$isa,'Grandchild object isa: isn\'t');

# Test DOES in perls > 5.10. 
# Note: $^V returns real string in perls > 5.10, and v-string in earlier perls
#   regexp below fails in earlier perls. this is okay
my($perl_main,$perl_minor)=$^V=~/^v(\d+)\.(\d+)/; # perl version
if ($perl_main==5 && $perl_minor>=10) {
  my $does=DOES Grandchild('Grandchild');
  is($does,1,'Grandchild DOES: is Grandchild');
  my $does=DOES Grandchild('Grandchild');
  is($does,1,'Grandchild DOES: is Grandchild');
  my $does=DOES Grandchild('Hash::AutoHash');
  ok($does,'Grandchild DOES: is Hash::AutoHash');
  my $does=DOES Grandchild('UNIVERSAL');
  is($does,1,'Grandchild DOES: is UNIVERSAL');
  my $does=DOES Grandchild('not_defined');
  ok(!$does,'Grandchild DOES: doesn\'t');
  my $does=$grandchild->DOES('Grandchild');
  is($does,1,'Grandchild object DOES: is Grandchild');
  my $does=$grandchild->DOES('not_defined');
  ok(!$does,'Grandchild object DOES: doesn\'t');
}

my $version=VERSION Grandchild;
is($version,$Grandchild::VERSION,'Grandchild VERSION');
is($grandchild->VERSION,$version,'Grandchild object VERSION');

import Grandchild qw(autohash_new);
# NOTE: $autohash used as global in autohashUtil test functions. do NOT 'my' it!!
$autohash=autohash_new();
ok($autohash && (ref($autohash) eq $autohash_class),'import autohash function via Grandhild');
import Grandchild qw(child_new);
my $child=child_new();
ok($child && (ref($child) eq $child_class),'import child function via Grandhild');
import Grandchild qw(grandchild_new);
my $grandchild=grandchild_new();
ok($grandchild && (ref($grandchild) eq $grandchild_class),'import grandchild function via Grandhild');

eval {import Grandchild qw(import);};
ok($@=~/not exported/,'import autohash function via Grandchild: not exported');
eval {import Grandchild qw(child_function_not_exported);};
ok($@=~/not exported/,'import child function via Grandchild: not exported');
eval {import Grandchild qw(grandchild_function_not_exported);};
ok($@=~/not exported/,'import grandchild function via Grandchild: not exported');
eval {import Grandchild qw(not_defined);};
ok($@=~/not defined/,'import via Grandchild: not defined');

import Grandchild qw(grandchild_autohash_new);
$autohash=grandchild_autohash_new();
ok($autohash && (ref($autohash) eq $autohash_class),'import renamed autohash function via Grandchild');
import Grandchild qw(grandchild_child_new);
my $child=grandchild_child_new();
ok($child && (ref($child) eq $child_class),'import renamed child function via Grandchild');
import Grandchild qw(grandchild_grandchild_new);
my $grandchild=grandchild_grandchild_new();
ok($grandchild && (ref($grandchild) eq $grandchild_class),'import renamed grandchild function via Grandchild');

use Test::Deep;
import Grandchild qw(grandchild_xxx);
my $grandchild=new Grandchild(key1=>'value10',key2=>'value20',key3=>'value30');
my @actual=grandchild_xxx($grandchild);	# keys
my @correct=qw(key1 key2 key3);
cmp_set(\@actual,\@correct,"import renamed Child function via Grandchild \%RENAME_EXPORT_OK");
import Grandchild qw(grandchild_yyy);
my @actual=grandchild_yyy($grandchild);	# values
my @correct=qw(value10 value20 value30);
cmp_set(\@actual,\@correct,"import renamed autohash function via Grandchild \%RENAME_EXPORT_OK");

#################################################################################
# test Grandchild keys, AUTOLOADED methods, real method
#################################################################################
$autohash=new Grandchild (key1=>'value10',key2=>'value20');
cmp_autohash('Grandchild: 0th values',[undef,'value10','value20']);
$autohash->key1('value11');
$autohash->key2('value21');
cmp_autohash('Grandchild: 1st values',[undef,'value11','value21']);
$autohash->key1('value12');
$autohash->key2('value22');
cmp_autohash('Grandchild: 2nd values',[undef,'value12','value22']);
is($autohash->child_method,'child method','Grandchild: real child method');
is($autohash->grandchild_method,'grandchild method','Grandchild: real grandchild method');

#################################################################################
# test Grandchild special keys
#################################################################################
# test_subclass_special_keys(Grandchild);
test_special_keys(new Grandchild);

done_testing();
