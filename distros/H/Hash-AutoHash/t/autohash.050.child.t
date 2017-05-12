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

# import Hash::AutoHash qw(autohash_new);
# my $autohash=autohash_new();
# ok($autohash && (ref($autohash) eq $autohash_class),'import autohash function via base class');

################################################################################
# test computation of @EXPORT_OK, @SUBCLASS_EXPORT_OK, %EXPORT_OK
################################################################################
my @export_ok=qw(autohash_new child_new not_defined
		 child_xxx
		 child_autohash_new child_child_new);
my @subclass_export_ok=@export_ok;
my %export_ok=
  (autohash_new=>'Hash::AutoHash::helper::autohash_new',
   child_autohash_new=>'Hash::AutoHash::helper::autohash_new',
   child_child_new=>'Child::helper::child_new',
   child_new=>'Child::helper::child_new',
   child_xxx=>'Hash::AutoHash::helper::autohash_keys',
   not_defined=>undef);
cmp_set(\@Child::EXPORT_OK,\@export_ok,'Child @EXPORT_OK');
cmp_set(\@Child::SUBCLASS_EXPORT_OK,\@subclass_export_ok,'Child @SUBCLASS_EXPORT_OK');
cmp_deeply(\%Child::EXPORT_OK,\%export_ok,'Child %EXPORT_OK');

#################################################################################
# test Child UNIVERSAL methods
#################################################################################
my $child=new Child;
ok($child,'Child new');

my $can=can Child('can');
ok($can,'Child can: can');
my $can=can Child('child_method');
ok($can,'Child can: child_method');
my $can=can Child('not_defined');
ok(!$can,'Child can: can\'t');
my $can=$child->can('can');
ok($can,'Child object can: can');
my $can=$child->can('not_defined');
ok(!$can,'Child object can: can\'t');

my $isa=isa Child('Child');
ok($isa,'Child isa: is Child');
my $isa=isa Child('Hash::AutoHash');
ok($isa,'Child isa: is Hash::AutoHash');
my $isa=isa Child('UNIVERSAL');
ok($isa,'Child isa: is UNIVERSAL');
my $isa=isa Child('not_defined');
ok(!$isa,'Child isa: isn\'t');
my $isa=$child->isa('Child');
ok($isa,'Child object isa: is Child');
my $isa=$child->isa('not_defined');
ok(!$isa,'Child object isa: isn\'t');

# Test DOES in perls > 5.10. 
# Note: $^V returns real string in perls > 5.10, and v-string in earlier perls
#   regexp below fails in earlier perls. this is okay
my($perl_main,$perl_minor)=$^V=~/^v(\d+)\.(\d+)/; # perl version
if ($perl_main==5 && $perl_minor>=10) {
  my $does=DOES Child('Child');
  is($does,1,'Child DOES: is Child');
  my $does=DOES Child('Hash::AutoHash');
  ok($does,'Child DOES: is Hash::AutoHash');
  my $does=DOES Child('UNIVERSAL');
  is($does,1,'Child DOES: is UNIVERSAL');
  my $does=DOES Child('not_defined');
  ok(!$does,'Child DOES: doesn\'t');
  my $does=$child->DOES('Child');
  is($does,1,'Child object DOES: is Child');
  my $does=$child->DOES('not_defined');
  ok(!$does,'Child object DOES: doesn\'t');
}

my $version=VERSION Child;
is($version,$Child::VERSION,'Child VERSION');
is($child->VERSION,$version,'Child object VERSION');

import Child qw(autohash_new);
# NOTE: $autohash used as global in autohashUtil test functions. do NOT 'my' it!!
$autohash=autohash_new();
ok($autohash && (ref($autohash) eq $autohash_class),'import autohash function via Child');
import Child qw(child_new);
my $child=child_new();
ok($child && (ref($child) eq $child_class),'import child function via Child');

eval {import Child qw(import);};
ok($@=~/not exported/,'import autohash function via Child: not exported');
eval {import Child qw(child_function_not_exported);};
ok($@=~/not exported/,'import child function via Child: not exported');
eval {import Child qw(not_defined);};
ok($@=~/not defined/,'import via Child: not defined');

import Child qw(child_autohash_new);
$autohash=child_autohash_new();
ok($autohash && (ref($autohash) eq $autohash_class),'import renamed autohash function via Child');
import Child qw(child_child_new);
my $child=child_child_new();
ok($child && (ref($child) eq $child_class),'import renamed child function via Child');

use Test::Deep;
import Child qw(child_xxx);
my $child=new Child(key1=>'value10',key2=>'value20',key3=>'value30');
my @actual=child_xxx($child);	# keys
my @correct=qw(key1 key2 key3);
cmp_set(\@actual,\@correct,"import renamed autohash function via Child \%RENAME_EXPORT_OK");

#################################################################################
# test Child keys, AUTOLOADED methods, real method
#################################################################################
$autohash=new Child (key1=>'value10',key2=>'value20');
cmp_autohash('Child: 0th values',[undef,'value10','value20']);
$autohash->key1('value11');
$autohash->key2('value21');
cmp_autohash('Child: 1st values',[undef,'value11','value21']);
$autohash->key1('value12');
$autohash->key2('value22');
cmp_autohash('Child: 2nd values',[undef,'value12','value22']);
is($autohash->child_method,'child method','Child: real child method');

#################################################################################
# test Child special keys
#################################################################################
# test_subclass_special_keys(Child);
test_special_keys(new Child);
 
done_testing();
