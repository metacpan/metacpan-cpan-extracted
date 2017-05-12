use lib qw(t);
use strict;
use Carp;
use Test::More;
use Test::Deep;
use Storable qw(dclone);
require 'autohash.TieMV.pm';	# example tied hash class
use autohashUtil;
use Hash::AutoHash qw(autohash_new autohash_hash autohash_tie 
			      autohash_wrap autohash_wraptie autohash_wrapobj);
use Hash::AutoHash qw(autohash_get);
our @keys;

sub test_set (*\@@) {
  my($label,$hash,@values)=@_;
  my $autohash_sav=dclone($autohash);	# copy since first test clobbers it
  my %hash=@$hash;
  # test key=>value form
  $label="set $label: key=>value form";
  autohash_set($autohash,%hash);
  my(@ok,@fail);
  for my $key (@keys) {
    my $value=shift @values;
    eq_deeply(autohash_get($autohash,$key),$value)? push(@ok,$key): push(@fail,$key);
  }
  report($label,@ok,@fail);
  # test separate ARRAYs form
  my($label,$hash,@values)=@_;	# restore parameters changed by first test
  $autohash=$autohash_sav;
  $label="set $label: separate ARRAYs form";
  my $keys=[keys %hash];
  my $values=[values %hash];
  autohash_set($autohash,$keys,$values);
  my(@ok,@fail);
  for my $key (@keys) {
    my $value=shift @values;
    eq_deeply(autohash_get($autohash,$key),$value)? push(@ok,$key): push(@fail,$key);
  }
  report($label,@ok,@fail);
}

# set 0 keys
use Hash::AutoHash qw(autohash_get autohash_set);
our @keys=qw(key0 key1 key2 key3);
my @hash=();
$autohash=autohash_new (key1=>'value10',key2=>'value20');
my @correct=(undef,'value10','value20',undef);
test_set('0 keys autohash_new',@hash,@correct);
$autohash=autohash_tie TieMV;
$autohash->key1('value10'); $autohash->key2('value20');
my @correct=(undef,['value10'],['value20'],undef);
test_set('0 keys autohash_tie',@hash,@correct);
$autohash=autohash_wrap %hash,(key1=>'value10',key2=>'value20');
my @correct=(undef,'value10','value20',undef);
test_set('0 keys autohash_wrap',@hash,@correct);
$autohash=autohash_wraptie %tie,TieMV;
$autohash->key1('value10'); $autohash->key2('value20');
my @correct=(undef,['value10'],['value20'],undef);
test_set('0 keys autohash_wraptie',@hash,@correct);
$object=tie %tie,'TieMV';
$autohash=autohash_wrapobj $object;
$autohash->key1('value10'); $autohash->key2('value20');
my @correct=(undef,['value10'],['value20'],undef);
test_set('0 keys autohash_wrapobj',@hash,@correct);

# set 1 key
use Hash::AutoHash qw(autohash_get autohash_set);
our @keys=qw(key0 key1 key2 key3);
my @hash=(key2=>'value21');
$autohash=autohash_new (key1=>'value10',key2=>'value20');
my @correct=(undef,'value10','value21',undef);
test_set('1 key autohash_new',@hash,@correct);
$autohash=autohash_tie TieMV;
$autohash->key1('value10'); $autohash->key2('value20');
my @correct=(undef,['value10'],['value20','value21'],undef);
test_set('1 key autohash_tie',@hash,@correct);
$autohash=autohash_wrap %hash,(key1=>'value10',key2=>'value20');
my @correct=(undef,'value10','value21',undef);
test_set('1 key autohash_wrap',@hash,@correct);
$autohash=autohash_wraptie %tie,TieMV;
$autohash->key1('value10'); $autohash->key2('value20');
my @correct=(undef,['value10'],['value20','value21'],undef);
test_set('1 key autohash_wraptie',@hash,@correct);
$object=tie %tie,'TieMV';
$autohash=autohash_wrapobj $object;
$autohash->key1('value10'); $autohash->key2('value20');
my @correct=(undef,['value10'],['value20','value21'],undef);
test_set('1 key autohash_wrapobj',@hash,@correct);

# set 2 keys
use Hash::AutoHash qw(autohash_set);
our @keys=qw(key0 key1 key2 key3);
my @hash=(key0=>'value01',key2=>'value21');
$autohash=autohash_new (key1=>'value10',key2=>'value20');
my @correct=('value01','value10','value21',undef);
test_set('2 keys autohash_new',@hash,@correct);
$autohash=autohash_tie TieMV;
$autohash->key1('value10'); $autohash->key2('value20');
my @correct=(['value01'],['value10'],['value20','value21'],undef);
test_set('2 keys autohash_tie',@hash,@correct);
$autohash=autohash_wrap %hash,(key1=>'value10',key2=>'value20');
my @correct=('value01','value10','value21',undef);
test_set('2 keys autohash_wrap',@hash,@correct);
$autohash=autohash_wraptie %tie,TieMV;
$autohash->key1('value10'); $autohash->key2('value20');
my @correct=(['value01'],['value10'],['value20','value21'],undef);
test_set('2 keys autohash_wraptie',@hash,@correct);
$object=tie %tie,'TieMV';
$autohash=autohash_wrapobj $object;
$autohash->key1('value10'); $autohash->key2('value20');
my @correct=(['value01'],['value10'],['value20','value21'],undef);
test_set('2 keys autohash_wrapobj',@hash,@correct);

done_testing();
