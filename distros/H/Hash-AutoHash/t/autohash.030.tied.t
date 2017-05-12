################################################################################
# test autohash_tied
################################################################################
use lib qw(t);
use strict;
use Carp;
use Test::More;
# use Test::Deep;
use autohashUtil;
require 'autohash.01x.constructors.pm';
require 'autohash.TieOptions.pm';	# example tied hash class
use Hash::AutoHash qw(autohash_hash autohash_tie 
		      autohash_wrap autohash_wrapobj autohash_wraptie);
use Hash::AutoHash qw(autohash_alias autohash_tied);

sub cmp_tied {
  my($label)=@_;
  cmp_tied_object("tied object: $label");
  cmp_tied_methods("tied methods: $label");
}
sub cmp_tied_object {
  my($label)=@_;
  my $tied=tied %$autohash;
  my $correct_autohash=(!$tied || 'Hash::AutoHash::alias' eq ref $tied)? undef: $tied;
  my $tied=tied %hash;
#  my $correct_hash=!$tied? undef: 'Hash::AutoHash::alias' eq ref $tied? tied %{$tied->[0]}: $tied;
  my $correct_hash=!$tied? undef: 'Hash::AutoHash::alias' eq ref $tied? $correct_autohash: $tied;
  my(@ok,@fail);
  my $actual_autohash=autohash_tied($autohash);
  my $actual_hash=autohash_tied(%hash);
  $actual_autohash eq $correct_autohash? push(@ok,'autohash'): push(@fail,'autohash');
  $actual_hash eq $correct_hash? push(@ok,'hash'): push(@fail,'hash');
  pass($label),return unless @fail;
  fail($label);
  diag(scalar(@ok)." items correct: @ok");
  diag(scalar(@fail)." items wrong: @fail");
}
sub _tied (\%) {
  my($hash)=@_;
  my $tied=tied %$hash;
  while (ref($tied) =~ /alias/) {
    my $hash=$tied->[0];
    $tied=tied(%$hash);
  }
  'TieOptions' eq ref $tied;
}
sub cmp_tied_methods {
  my($label)=@_;
  my $object=autohash_tied($autohash);
  # set 1 option via each of autohash, hash, object 
  autohash_tied($autohash,'set_via_autohash','set_via_autohash_value1');
  autohash_tied(%hash,'set_via_hash','set_via_hash_value1');
  $object->set_via_object('set_via_object_value1') if $object;

  # correct values depend on whether autohash tied and hash aliased
  # in table below, 'tied' means 'tied to TieOptions possibly via alias'
  # ll combinations not in table are illegal
  #
  # get_via   ----- tied? -----    >>> ----- set_via_... -----
  #           ahash      hash      >>>  ahash     hash     obj
  # any       undef      undef     >>>  undef     undef    undef
  #
  # autohash  TRUE       undef     >>>  set       undef    set    
  # hash      TRUE       undef     >>>  undef     undef    undef
  # object    TRUE       undef     >>>  set       undef    set
  #
  # autohash  TRUE       TRUE      >>>  set       set      set    
  # hash      TRUE       TRUE      >>>  set       set      set  
  # object    TRUE       TRUE      >>>  set       set      set
  my %correct;
  # initialize all to undef, then set TRUE cases
  for my $set_via (map {"set_via_$_"} qw(autohash hash object)) {
    for my $get_via (map {"get_via_$_"} qw(autohash hash object)) {
      $correct{"$set_via$;$get_via"}=undef;
    }
  }
  if (_tied(%$autohash) && !_tied(%hash)) {
    $correct{"set_via_autohash$;get_via_autohash"}='set_via_autohash_value1';
    $correct{"set_via_autohash$;get_via_object"}='set_via_autohash_value1';
    $correct{"set_via_object$;get_via_autohash"}='set_via_object_value1';
    $correct{"set_via_object$;get_via_object"}='set_via_object_value1';
  } elsif (_tied(%$autohash) && _tied(%hash)) {   # all TRUE cases
      for my $set_via (map {"set_via_$_"} qw(autohash hash object)) {
 	for my $get_via (map {"get_via_$_"} qw(autohash hash object)) {
	  $correct{"$set_via$;$get_via"}=$set_via.'_value1';
	}}}
  
  # get all options via autohash, hash, object
  my %actual;
  for my $set_via (map {"set_via_$_"} qw(autohash hash object)) {
    $actual{"$set_via$;get_via_autohash"}=autohash_tied($autohash,$set_via);
    $actual{"$set_via$;get_via_hash"}=autohash_tied(%hash,$set_via);
    $actual{"$set_via$;get_via_object"}=$object? $object->$set_via: undef;
  }
  # compare correct vs. actual
  my(@ok,@fail);
  for my $set_via (map {"set_via_$_"} qw(autohash hash object)) {
    for my $get_via (map {"get_via_$_"} qw(autohash hash object)) {
      $actual{"$set_via$;$get_via"} eq $correct{"$set_via$;$get_via"}?
	push(@ok,$set_via.'->'.$get_via): push(@fail,$set_via.'->'.$get_via);
      }}
  pass($label),return unless @fail;
  fail($label);
  diag(scalar(@ok)." items correct: @ok");
  diag(scalar(@fail)." items wrong: @fail");
}
################################################################################
# test using all constuctor functions (code adapted from 010.cons_funcs.t)
################################################################################
# autohash_hash
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_hash';
my $label="$constructor without initial values";
$autohash=autohash_hash;
cmp_tied($label);
my $label="$constructor with initial values";
$autohash=autohash_hash (key1=>'value11',key2=>'value21');
cmp_tied($label);

# autohash_tie
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_tie';
my $label="$constructor without initial values";
$autohash=autohash_tie TieOptions;
cmp_tied($label);
my $label="$constructor with initial values";
$autohash=autohash_tie TieOptions,(key1=>'value11',key2=>'value21');
cmp_tied($label);

# autohash_wrap (real)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_wrap (real)';
my $label="$constructor without initial values";
$autohash=autohash_wrap %hash;
cmp_tied($label);
my $label="$constructor with initial values";
$autohash=autohash_wrap %hash,(key1=>'value11',key2=>'value21');
cmp_tied($label);

# autohash_wrap (tied)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_wrap (tied)';
my $label="$constructor without initial values";
$object=tie %hash,'TieOptions';
$autohash=autohash_wrap %hash;
cmp_tied($label);
my $label="$constructor with initial values";
$object=tie %hash,'TieOptions';
$autohash=autohash_wrap %hash,(key1=>'value11',key2=>'value21');
cmp_tied($label);

# autohash_wrapobj
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_wrapobj';
my $label="$constructor without initial values";
$object=tie %hash,'TieOptions';
$autohash=autohash_wrapobj $object;
cmp_tied($label);
my $label="$constructor with initial values";
$object=tie %hash,'TieOptions';
$autohash=autohash_wrapobj $object,(key1=>'value11',key2=>'value21');
cmp_tied($label);
undef $object;

# autohash_wraptie
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_wraptie';
my $label="$constructor without initial values";
$autohash=autohash_wraptie %hash,TieOptions;
$object=tied(%hash);
cmp_tied($label);
my $label="$constructor with initial values";
$autohash=autohash_wraptie %hash,TieOptions,(key1=>'value11',key2=>'value21');
$object=tied(%hash);
cmp_tied($label);

################################################################################
# test on all alias cases (code adapted from 030.alias.t)
################################################################################
# autohash_alias (wrap real)
my $constructor='autohash_alias (wrap real)';
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor without initial values";
autohash_alias $autohash,%hash;
cmp_tied($label);
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor with initial values";
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_tied($label);

# autohash_alias (wrap tied)
my $constructor='autohash_alias (wrap tied)';
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor without initial values";
tie %hash,'TieOptions';
autohash_alias $autohash,%hash;
cmp_tied($label);
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor with initial values";
tie %hash,'TieOptions';
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_tied($label);

# autohash_hash
my $constructor='autohash_alias autohash_hash';
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor without initial values";
$autohash=autohash_hash;
autohash_alias $autohash,%hash;
cmp_tied($label);
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor with initial values";
$autohash=autohash_hash (key1=>'value11',key2=>'value21');
autohash_alias $autohash,%hash;
cmp_tied($label);
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor alias with initial values";
$autohash=autohash_hash;
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_tied($label);

# autohash_tie
my $constructor='autohash_alias autohash_tie';
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor without initial values";
$autohash=autohash_tie TieOptions;
autohash_alias $autohash,%hash;
cmp_tied($label);
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor with initial values";
$autohash=autohash_tie TieOptions,(key1=>'value11',key2=>'value21');
autohash_alias $autohash,%hash;
cmp_tied($label);
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor alias with initial values";
$autohash=autohash_tie TieOptions;
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_tied($label);

# autohash_wrap (real)
my $constructor='autohash_alias autohash_wrap (real)';
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor without initial values";
$autohash=autohash_wrap %source;
autohash_alias $autohash,%hash;
cmp_tied($label);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor with initial values";
$autohash=autohash_wrap %source,(key1=>'value11',key2=>'value21');
autohash_alias $autohash,%hash;
cmp_tied($label);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor alias with initial values";
$autohash=autohash_wrap %source;
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_tied($label);

# autohash_wrap (tied)
my $constructor='autohash_alias autohash_wrap (tied)';
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor without initial values";
$object=tie %source,'TieOptions';
$autohash=autohash_wrap %source;
autohash_alias $autohash,%hash;
cmp_tied($label);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor with initial values";
$object=tie %source,'TieOptions';
$autohash=autohash_wrap %source,(key1=>'value11',key2=>'value21');
autohash_alias $autohash,%hash;
cmp_tied($label);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor alias with initial values";
$object=tie %source,'TieOptions';
$autohash=autohash_wrap %source;
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_tied($label);

# autohash_wrapobj
my $constructor='autohash_alias autohash_wrapobj';
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor without initial values";
$object=tie %source,'TieOptions';
$autohash=autohash_wrapobj $object;
autohash_alias $autohash,%hash;
cmp_tied($label);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor with initial values";
$object=tie %source,'TieOptions';
$autohash=autohash_wrapobj $object,(key1=>'value11',key2=>'value21');
autohash_alias $autohash,%hash;
cmp_tied($label);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor alias with initial values";
$object=tie %source,'TieOptions';
$autohash=autohash_wrapobj $object;
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_tied($label);

# autohash_wraptie
my $constructor='autohash_alias autohash_wraptie';
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor without initial values";
$autohash=autohash_wraptie %source,TieOptions;
$object=tied(%source);
autohash_alias $autohash,%hash;
cmp_tied($label);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor with initial values";
$autohash=autohash_wraptie %source,TieOptions,(key1=>'value11',key2=>'value21');
$object=tied(%source);
autohash_alias $autohash,%hash;
cmp_tied($label);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor alias with initial values";
$autohash=autohash_wraptie %source,TieOptions;
$object=tied(%source);
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_tied($label);

done_testing();
