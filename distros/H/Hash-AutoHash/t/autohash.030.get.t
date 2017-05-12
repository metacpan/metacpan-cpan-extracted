use lib qw(t);
use strict;
use Carp;
use Test::More;
use Test::Deep;
require 'autohash.TieMV.pm';	# example tied hash class
use autohashUtil;
use Hash::AutoHash qw(autohash_new autohash_hash autohash_tie 
			      autohash_wrap autohash_wraptie autohash_wrapobj);
use Hash::AutoHash qw(autohash_get);
our @keys;

sub test_get (*\@) {
  my($label,$correct)=@_;
  $label="get $label";
  my @actual=autohash_get($autohash,@keys);
  cmp_deeply(\@actual,$correct,$label);
}

# get 0 keys
our @keys=();
my @correct=();
$autohash=autohash_new (key1=>'value10',key2=>'value20');
test_get('0 keys autohash_new',@correct);
$autohash=autohash_tie TieMV;
$autohash->key1('value10'); $autohash->key2('value20');
test_get('0 keys autohash_tie',@correct);
$autohash=autohash_wrap %hash,(key1=>'value10',key2=>'value20');
test_get('0 keys autohash_wrap',@correct);
$autohash=autohash_wraptie %tie,TieMV;
$autohash->key1('value10'); $autohash->key2('value20');
test_get('0 keys autohash_wraptie',@correct);
$object=tie %tie,'TieMV';
$autohash=autohash_wrapobj $object;
$autohash->key1('value10'); $autohash->key2('value20');
test_get('0 keys autohash_wrapobj',@correct);

# get 1 key
our @keys=qw(key2);
$autohash=autohash_new (key1=>'value10',key2=>'value20');
my @correct=('value20');
test_get('1 key autohash_new',@correct);
$autohash=autohash_tie TieMV;
$autohash->key1('value10'); $autohash->key2('value20');
my @correct=(['value20']);
test_get('1 key autohash_tie',@correct);
$autohash=autohash_wrap %hash,(key1=>'value10',key2=>'value20');
my @correct=('value20');
test_get('1 key autohash_wrap',@correct);
$autohash=autohash_wraptie %tie,TieMV;
$autohash->key1('value10'); $autohash->key2('value20');
my @correct=(['value20']);
test_get('1 key autohash_wraptie',@correct);
$object=tie %tie,'TieMV';
$autohash=autohash_wrapobj $object;
$autohash->key1('value10'); $autohash->key2('value20');
my @correct=(['value20']);
test_get('1 key autohash_wrapobj',@correct);

# get 2 keys
our @keys=qw(key0 key2);
$autohash=autohash_new (key1=>'value10',key2=>'value20');
my @correct=(undef,'value20');
test_get('2 keys autohash_new',@correct);
$autohash=autohash_tie TieMV;
$autohash->key1('value10'); $autohash->key2('value20');
my @correct=(undef,['value20']);
test_get('2 keys autohash_tie',@correct);
$autohash=autohash_wrap %hash,(key1=>'value10',key2=>'value20');
my @correct=(undef,'value20');
test_get('2 keys autohash_wrap',@correct);
$autohash=autohash_wraptie %tie,TieMV;
$autohash->key1('value10'); $autohash->key2('value20');
my @correct=(undef,['value20']);
test_get('2 keys autohash_wraptie',@correct);
$object=tie %tie,'TieMV';
$autohash=autohash_wrapobj $object;
$autohash->key1('value10'); $autohash->key2('value20');
my @correct=(undef,['value20']);
test_get('2 keys autohash_wrapobj',@correct);

done_testing();
