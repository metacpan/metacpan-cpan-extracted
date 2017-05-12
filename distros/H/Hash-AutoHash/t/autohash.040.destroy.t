use lib qw(t);
use strict;
use Carp;
use Scalar::Util qw(refaddr weaken);
use Test::More;
use Test::Deep;
require 'autohash.TieMV.pm';	# example tied hash class
use autohashUtil;
use Hash::AutoHash qw(autohash_new autohash_hash autohash_tie 
			      autohash_wrap autohash_wraptie autohash_wrapobj);

#################################################################################
package Child;
our $VERSION='1.00_1111';

use strict;
use Hash::AutoHash;
our @ISA=qw(Hash::AutoHash);

package Child::helper;
use strict;
our @ISA=qw(Hash::AutoHash::helper);
use Hash::AutoHash qw(autohash_tie);

sub _new {
  my($helper_class,$class,@args)=@_;
  my $self=autohash_tie TieMV,@args;
  bless $self,$class;
}

package main;
our $DESTROYED=\%TieMV::DESTROYED;
my @INITIAL_VALUES=(key0=>'value01',key1=>'value11',key2=>'value21');
my %INITIAL_VALUES=@INITIAL_VALUES;
my @KEYS=keys %INITIAL_VALUES;
my($autohash_sav,$hash,$object);

sub test_destroy {
  my($label,$ok_hash,$ok_object)=@_;
  my(@ok,@fail);
  eq_set([keys %$autohash],\@KEYS)? push(@ok,'autohash'): push(@fail,'autohash');
  if ($ok_hash) {
    eq_set([keys %$hash],\@KEYS)? push(@ok,'hash'): push(@fail,'hash');
  } else {
    ($hash eq undef)? push(@ok,'hash'): push(@fail,'hash');
  }
  if ($ok_object) {
    eq_set([keys_obj($object)],\@KEYS)? push(@ok,'object'): push(@fail,'object');
  } else {
    ($object eq undef)? push(@ok,'object'): push(@fail,'object');
  }
  my $tiedaddr=ref(tied %$autohash) eq 'TieMV'? refaddr(tied %$autohash): undef;
  if ($tiedaddr) {
    ($DESTROYED->{$tiedaddr} eq 0)? 
      push(@ok,'TieMV::DESTROYED'): push(@fail,'TieMV::DESTROYED');
  }
  report("$label before destroy",@ok,@fail);

  # weaken refs used in test, then undef $autohash, and everything should be destroyed
  $autohash_sav=$autohash;
  weaken($autohash_sav); weaken($hash); weaken($object);
  undef $autohash;

  my(@ok,@fail);
  ($autohash_sav eq undef)? push(@ok,'autohash'): push(@fail,'autohash');
  ($hash eq undef)? push(@ok,'hash'): push(@fail,'hash');
  ($object eq undef)? push(@ok,'object'): push(@fail,'object');
  if ($tiedaddr) {
    ($DESTROYED->{$tiedaddr} eq 1)? 
      push(@ok,'TieMV::DESTROYED'): push(@fail,'TieMV::DESTROYED');
  }
  report("$label after destroy",@ok,@fail);
}

################################################################################
# tests start here
################################################################################

my $constructor='autohash_new (real)';
undef $autohash; undef $object; untie $hash; undef $hash;
$autohash=autohash_new @INITIAL_VALUES;
test_destroy($constructor);

my $constructor='autohash_new (tie)';
undef $autohash; undef $object; untie $hash; undef $hash;
$autohash=autohash_new ['TieMV'],@INITIAL_VALUES;
test_destroy($constructor);

my $constructor='autohash_new (wrap real)';
undef $autohash; undef $object; untie $hash; undef $hash;
$hash={};
$autohash=autohash_new $hash,@INITIAL_VALUES;
test_destroy($constructor,'hash');

my $constructor='autohash_new (wrap tied)';
undef $autohash; undef $object; untie $hash; undef $hash;
$hash={};
$object=tie %$hash,'TieMV';
$autohash=autohash_new $hash,@INITIAL_VALUES;
test_destroy($constructor,'hash','object');

my $constructor='autohash_new (wrap object)';
undef $autohash; undef $object; untie $hash; undef $hash;  
$hash={};
$object=tie %$hash,'TieMV';
$autohash=autohash_new $object,@INITIAL_VALUES;
test_destroy($constructor,'hash','object');

my $constructor='autohash_new (wraptie)';
undef $autohash; undef $object; untie $hash; undef $hash;
$hash={};
$autohash=autohash_new [$hash,'TieMV'],@INITIAL_VALUES;
$object=tied(%$hash);
test_destroy($constructor,'hash','object');

my $constructor='autohash_hash';
undef $autohash; undef $object; untie $hash; undef $hash;
$autohash=autohash_hash @INITIAL_VALUES;
test_destroy($constructor);

my $constructor='autohash_tie';
undef $autohash; undef $object; untie $hash; undef $hash;
$autohash=autohash_tie TieMV,@INITIAL_VALUES;
test_destroy($constructor);

my $constructor='autohash_wrap (real)';
undef $autohash; undef $object; untie $hash; undef $hash;
$hash={};
$autohash=autohash_wrap %$hash,@INITIAL_VALUES;
test_destroy($constructor,'hash',undef);

my $constructor='autohash_wrap (tied)';
undef $autohash; undef $object; untie $hash; undef $hash;
$hash={};
$object=tie %$hash,'TieMV';
$autohash=autohash_wrap %$hash,@INITIAL_VALUES;
test_destroy($constructor,'hash','object');

my $constructor='autohash_wrapobj';
undef $autohash; undef $object; untie $hash; undef $hash;
$hash={};
$object=tie %$hash,'TieMV';
$autohash=autohash_wrapobj $object,@INITIAL_VALUES;
test_destroy($constructor,'hash','object');

my $constructor='autohash_wraptie';
undef $autohash; undef $object; untie $hash; undef $hash;
$hash={};
$autohash=autohash_wraptie %$hash,TieMV,@INITIAL_VALUES;
$object=tied(%$hash);
test_destroy($constructor,'hash','object');

my $constructor='new Child';
undef $autohash; undef $object; untie $hash; undef $hash;
$autohash=new Child @INITIAL_VALUES;
test_destroy($constructor);

done_testing();
