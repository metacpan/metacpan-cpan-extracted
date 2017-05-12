use lib qw(t);
use Carp;
use Hash::AutoHash;
use Test::More;
use Test::Deep;
use autohashUtil;

sub as_hash {
  my $autohash=shift;
  my %hash;
  while (my($key,$value)=each %$autohash) {
    if ('Hash::AutoHash' eq ref $value) {
      $value=as_hash($value);	# recurse
    }
    $hash{$key}=$value;
  }
  \%hash;
}
################################################################################
# SYNOPSIS
################################################################################
use Hash::AutoHash;

# real hash
my $autohash=new Hash::AutoHash name=>'Joe', hobbies=>['hiking','cooking'];
is(ref($autohash),'Hash::AutoHash','real hash ref');
cmp_deeply(as_hash($autohash),{name=>'Joe',hobbies=>['hiking','cooking']},'real hash data');

# access or change hash elements via methods
my $name=$autohash->name;           # 'Joe'
is($name,'Joe','access name via methods');
my $hobbies=$autohash->hobbies;     # ['hiking','cooking']
cmp_deeply($hobbies,['hiking','cooking'],'access hobbies via methods');
$autohash->hobbies(['go','chess']); # hobbies now ['go','chess']
cmp_deeply(as_hash($autohash),{name=>'Joe',hobbies=>['go','chess']},'change element via methods');

# you can also use standard hash notation and functions
my($name,$hobbies)=@$autohash{qw(name hobbies)};
is($name,'Joe','access name via hash');
cmp_deeply($hobbies,['go','chess'],'access hobbies via hash');
$autohash->{name}='Moe';	# name now 'Moe'
cmp_deeply(as_hash($autohash),{name=>'Moe',hobbies=>['go','chess']},'change element via hash');
my @values=values %$autohash;	# ('Moe',['go','chess'])
# cmp_bag(\@values,['Moe',['go','chess']],'values');
cmp_set(\@values,['Moe',['go','chess']],'values');

# tied hash. 
use Hash::AutoHash qw(autohash_tie);
use Tie::Hash::MultiValue;          # from CPAN. each hash element is ARRAY
my $autohash=autohash_tie Tie::Hash::MultiValue;
is(ref($autohash),'Hash::AutoHash','tied hash ref');
cmp_deeply(as_hash($autohash),{},'tied hash initial data');
$autohash->name('Joe');
$autohash->hobbies('hiking','cooking');
my $name=$autohash->name;	  # ['Joe']
my $hobbies=$autohash->hobbies;	  # ['hiking','cooking']
cmp_deeply(as_hash($autohash),{name=>['Joe'],hobbies=>['hiking','cooking']},'tied hash data');
cmp_deeply([$name,$hobbies],[['Joe'],['hiking','cooking']],'access elements via methods');
 
# real hash via constructor function. analogous to autohash_tied
use Hash::AutoHash qw(autohash_hash);
my $autohash=autohash_hash name=>'Joe',hobbies=>['hiking','cooking'];
is(ref($autohash),'Hash::AutoHash','real hash ref via constructor function');
cmp_deeply(as_hash($autohash),{name=>'Joe',hobbies=>['hiking','cooking']},'real hash data via constructor function');
my $name=$autohash->name;           # 'Joe'
is($name,'Joe','access name via methods');
my $hobbies=$autohash->hobbies;     # ['hiking','cooking']
cmp_deeply($hobbies,['hiking','cooking'],'access hobbies via methods');

# autohash_set is easy way to set multiple elements at once
# it has two forms
autohash_set($autohash,name=>'Moe',hobbies=>['go','chess']);
cmp_deeply(as_hash($autohash),
	   {name=>'Moe',hobbies=>['go','chess']},'autohash_set: key=>value form');
# folllowing line NOT in docs. reset $autohash for next test
my $autohash=autohash_hash name=>'Joe',hobbies=>['hiking','cooking'];
autohash_set($autohash,['name','hobbies'],['Moe',['go','chess']]);
cmp_deeply(as_hash($autohash),
	   {name=>'Moe',hobbies=>['go','chess']},'autohash_set: separate ARRAYs form');

# alias $autohash to regular hash for more concise hash notation
use Hash::AutoHash qw(autohash_alias);
my %hash;
autohash_alias($autohash,%hash);
cmp_autohash('autohash_alias',$autohash,
	     {name=>'Moe',hobbies=>['go','chess']},'hash',undef,\%hash);
# access or change hash elements without using ->
$hash{name}='Joe';                     # changes $autohash and %hash
cmp_autohash('autohash_alias',$autohash,
	     {name=>'Joe',hobbies=>['go','chess']},'hash',undef,\%hash);
my $name_via_hash=$hash{name};         # 'Joe'
is($name_via_hash,'Joe','name via aliased hash');
my $name_via_autohash=$autohash->name; # 'Joe'
is($name_via_autohash,'Joe','name via aliased autohash');
# get two elements in one statement
my($name,$hobbies)=@hash{qw(name hobbies)};
cmp_deeply([$name,$hobbies],['Joe',['go','chess']],'get two elements from aliased hash');

# nested structures work, too, of course
my $name=autohash_hash first=>'Joe',last=>'Doe';
my $person=autohash_hash name=>$name,hobbies=>['hiking','cooking'];
cmp_deeply(as_hash($person),{name=>{first=>'Joe',last=>'Doe'},hobbies=>['hiking','cooking']},
	   'nested structure');
my $first=$person->name->first;    # 'Joe'
is($first,'Joe','access nested structure');

################################################################################
# DESCRIPTION
################################################################################
my $autohash=autohash_hash name=>'Joe'; # not in POD
my $name=$autohash->{name};
my $name=$autohash->name;

$autohash->{name}='Jonathan';
$autohash->name('Jonathan');

$autohash->{first_name}='Joe';
$autohash->last_name('Plumber');

cmp_deeply(as_hash($autohash),{name=>'Jonathan',first_name=>'Joe',last_name=>'Plumber'},
	   'DESCRIPTION: access or change elements');

use Hash::AutoHash qw(autohash_set);
my $autohash=autohash_tie Tie::Hash::MultiValue;
autohash_set ($autohash,name=>'Joe',hobbies=>'hiking',hobbies=>'cooking');
cmp_deeply(as_hash($autohash),{name=>['Joe'],hobbies=>['hiking','cooking']},'autohash_set: key=>value form');
my $autohash=autohash_tie Tie::Hash::MultiValue;
autohash_set($autohash,['name','hobbies'],['Joe','hiking']);
cmp_deeply(as_hash($autohash),{name=>['Joe'],hobbies=>['hiking']},'autohash_set:separate ARRAYs form');

my $name=autohash_hash first=>'Joe',last=>'Doe';
my $person=autohash_hash name=>$name,hobbies=>['hiking','cooking'];
cmp_deeply(as_hash($person),{name=>{first=>'Joe',last=>'Doe'},hobbies=>['hiking','cooking']},
	   'nested structure');
my $first=$person->name->first;    # $name is 'Joe'
is($first,'Joe','access nested structure');

use Hash::AutoHash qw(autohash_alias);
my $autohash=autohash_tie Tie::Hash::MultiValue;
autohash_alias($autohash,%hash);
$hash{name}='Joe';                  # changes both $autohash and %hash
$autohash->hobbies('kayaking');     # changes both $autohash and %hash
my($name,$hobbies)=@hash{qw(name hobbies)};
cmp_deeply(as_hash($autohash),\%hash,'aliased autohash and hash');
cmp_deeply([$name,$hobbies],[['Joe'],['kayaking']],'access hash');

# wrap existing hash - can be real or tied.
use Hash::AutoHash qw(autohash_wrap);
my %hash=(name=>'Moe',hobbies=>['running','rowing']);
my $autohash=autohash_wrap %hash;
cmp_deeply(as_hash($autohash),\%hash,'autohash and wrapped hash');
cmp_deeply(as_hash($autohash),{name=>'Moe',hobbies=>['running','rowing']},'autohash and wrapped hash: data');
my($name,$hobbies)=@hash{qw(name hobbies)};
cmp_deeply([$name,$hobbies],['Moe',['running','rowing']],'access wrapped hash');
$hash{name}='Joe';                  # changes both $autohash and %hash
$autohash->hobbies('kayaking');     # changes both $autohash and %hash
cmp_deeply(as_hash($autohash),{name=>'Joe',hobbies=>'kayaking'},'access wrapped hash');

use Hash::AutoHash qw(autohash_tied);
my $autohash1=autohash_tie Tie::Hash::MultiValue;
my $tied=autohash_tied($autohash1);  # Tie::Hash::MultiValue object 
is($tied,tied %$autohash1,'autohash_tied: autohash');
my %hash1;
autohash_alias($autohash1,%hash1);
my $tied=autohash_tied(%hash1);      # same object as above
is($tied,tied %$autohash1,'autohash_tied: hash');

use Hash::AutoHash qw(autohash_keys autohash_delete);
$autohash->undef1(undef);
$autohash->undef2(undef);
cmp_deeply(as_hash($autohash),{name=>'Joe',hobbies=>'kayaking',undef1=>undef,undef2=>undef},'before deleting undef values');
my @keys=autohash_keys($autohash);
for my $key (@keys) {
  autohash_delete($autohash,$key) unless defined $autohash->$key;
}
cmp_deeply(as_hash($autohash),{name=>'Joe',hobbies=>'kayaking'},'after deleting undef values');

# NG 12-09-02. No longer possible to use methods innherited from UNIVERSAL
# # Keeping the namespace clean

# ok(can Hash::AutoHash('import'),'can indirect syntax');
# ok(Hash::AutoHash->can('import'),'can -> syntax');

# $autohash->can('import');
# cmp_deeply(as_hash($autohash),{name=>'Joe',hobbies=>'kayaking',can=>'import'},'can object method');

my $autohash=new Hash::AutoHash(name=>'Joe');
cmp_deeply(as_hash($autohash),{name=>'Joe'},'new class method');
my $new=$autohash->new;
ok(!$new,'new object method');

################################################################################
# Constructors
################################################################################
# Typical usage
use Hash::AutoHash qw(autohash_hash autohash_tie);

my $autohash=autohash_hash name=>'Joe',hobbies=>['hiking','cooking'];
cmp_deeply(as_hash($autohash),{name=>'Joe',hobbies=>['hiking','cooking']},'autohash_hash');

my $autohash=autohash_tie Tie::Hash::MultiValue;
cmp_deeply(as_hash($autohash),{},'autohash_tie');
my $tied_object=tied %$autohash;    # note the '%' before the '$'
is(ref($tied_object),'Tie::Hash::MultiValue','tied object');

use Hash::AutoHash qw(autohash_set);
my $autohash=autohash_tie Tie::Hash::MultiValue;
autohash_set ($autohash,name=>'Joe',hobbies=>'hiking',hobbies=>'cooking');
cmp_deeply(as_hash($autohash),{name=>['Joe'],hobbies=>['hiking','cooking']},'autohash_set: key=>value form');
my $autohash=autohash_tie Tie::Hash::MultiValue;
autohash_set($autohash,['name','hobbies'],['Joe','hiking']);
cmp_deeply(as_hash($autohash),{name=>['Joe'],hobbies=>['hiking']},'autohash_set:separate ARRAYs form');

# Wrapping an existing hash or tied object
use Hash::AutoHash qw(autohash_wrap autohash_wrapobj autohash_wraptie);

undef %hash;
my $autohash=autohash_wrap %hash,name=>'Joe',hobbies=>['hiking','cooking'];
cmp_deeply(as_hash($autohash),{name=>'Joe',hobbies=>['hiking','cooking']},'autohash_wrap');

my $tied_object=tie %hash,'Tie::Hash::MultiValue'; # not in docs
my $autohash=autohash_wrapobj $tied_object,name=>'Joe',hobbies=>'hiking';
cmp_deeply(as_hash($autohash),{name=>['Joe'],hobbies=>['hiking']},'autohash_wrapobj');

my $autohash=autohash_wrapobj tie %hash,'Tie::Hash::MultiValue';
cmp_deeply(as_hash($autohash),{},'autohash_wrapobj typical');

my $autohash=autohash_wrapobj
  ((tie %hash,'Tie::Hash::MultiValue'),name=>'Joe',hobbies=>'hiking',hobbies=>'cooking');
cmp_deeply(as_hash($autohash),{name=>['Joe'],hobbies=>['hiking','cooking']},'autohash_wrapobj initial vallue');

my $autohash=autohash_wraptie %hash,Tie::Hash::MultiValue;
cmp_deeply(as_hash($autohash),{},'autohash_wraptie');

my $autohash=autohash_wrapobj tie %hash,'Tie::Hash::MultiValue';
cmp_deeply(as_hash($autohash),{},'autohash_wraptie equivalent');

# 'new' method and autohash_new function
use Hash::AutoHash qw(autohash_new);

my $autohash=new Hash::AutoHash name=>'Joe',hobbies=>['hiking','cooking'];
cmp_deeply(as_hash($autohash),{name=>'Joe',hobbies=>['hiking','cooking']},'new autohash_hash');

my $autohash=new Hash::AutoHash ['Tie::Hash::MultiValue'],name=>'Joe',hobbies=>'hiking',hobbies=>'cooking';
cmp_deeply(as_hash($autohash),{name=>['Joe'],hobbies=>['hiking','cooking']},'new autohash_tie');

undef %hash;
my $autohash=new Hash::AutoHash \%hash, name=>'Joe',hobbies=>'hiking',hobbies=>'cooking';
cmp_deeply(as_hash($autohash),{name=>['Joe'],hobbies=>['hiking','cooking']},'new autohash_wrap');
cmp_deeply(\%hash,{name=>['Joe'],hobbies=>['hiking','cooking']},'new autohash_wrap hash');

undef %hash;
my $tied_object=tie %hash,'Tie::Hash::MultiValue'; # not in docs
my $autohash=new Hash::AutoHash $tied_object, name=>'Joe',hobbies=>'hiking',hobbies=>'cooking';
cmp_deeply(as_hash($autohash),{name=>['Joe'],hobbies=>['hiking','cooking']},'new autohash_wrapobj');
cmp_deeply(\%hash,{name=>['Joe'],hobbies=>['hiking','cooking']},'new autohash_wrapobj hash');

undef %hash;
my $autohash=new Hash::AutoHash [\%hash,'Tie::Hash::MultiValue'], name=>'Joe',hobbies=>'hiking',hobbies=>'cooking';
cmp_deeply(as_hash($autohash),{name=>['Joe'],hobbies=>['hiking','cooking']},'new autohash_wraptie');
cmp_deeply(\%hash,{name=>['Joe'],hobbies=>['hiking','cooking']},'new autohash_wraptie hash');

my $autohash=autohash_new name=>'Joe',hobbies=>['hiking','cooking'];
cmp_deeply(as_hash($autohash),{name=>'Joe',hobbies=>['hiking','cooking']},'autohash_new autohash_hash');

my $autohash=autohash_new ['Tie::Hash::MultiValue'], name=>'Joe',hobbies=>'hiking',hobbies=>'cooking';
cmp_deeply(as_hash($autohash),{name=>['Joe'],hobbies=>['hiking','cooking']},'autohash_new autohash_tie');

undef %hash;
my $autohash=autohash_new \%hash, name=>'Joe',hobbies=>'hiking',hobbies=>'cooking';
cmp_deeply(as_hash($autohash),{name=>['Joe'],hobbies=>['hiking','cooking']},'autohash_new autohash_wrap');
cmp_deeply(\%hash,{name=>['Joe'],hobbies=>['hiking','cooking']},'autohash_new autohash_wrap hash');

undef %hash;
my $tied_object=tie %hash,'Tie::Hash::MultiValue'; # not in docs
my $autohash=autohash_new $tied_object, name=>'Joe',hobbies=>'hiking',hobbies=>'cooking';
cmp_deeply(as_hash($autohash),{name=>['Joe'],hobbies=>['hiking','cooking']},'autohash_new autohash_wrapobj');
cmp_deeply(\%hash,{name=>['Joe'],hobbies=>['hiking','cooking']},'autohash_new autohash_wrapobj hash');

undef %hash;
my $autohash=autohash_new [\%hash,'Tie::Hash::MultiValue'], name=>'Joe',hobbies=>'hiking',hobbies=>'cooking';
cmp_deeply(as_hash($autohash),{name=>['Joe'],hobbies=>['hiking','cooking']},'autohash_new autohash_wraptie');
cmp_deeply(\%hash,{name=>['Joe'],hobbies=>['hiking','cooking']},'autohash_new autohash_wraptie hash');

# Aliasing
undef %hash;
my $autohash=new Hash::AutoHash name=>'Joe',hobbies=>['hiking','cooking']; # not in docs
autohash_alias($autohash,%hash);
cmp_deeply(as_hash($autohash),{name=>'Joe',hobbies=>['hiking','cooking']},'alias');
cmp_deeply(\%hash,{name=>'Joe',hobbies=>['hiking','cooking']},'alias hash');

# Getting and setting hash elements
my $autohash=autohash_hash name=>'Joe',hobbies=>['hiking','cooking'];
my $name=$autohash->{name};
is($name,'Joe','access 1 element as hash');
my($name,$hobbies)=@$autohash{qw(name hobbies)};
cmp_deeply([$name,$hobbies],['Joe',['hiking','cooking']],'access 2 elements as hash');
$autohash->{name}='Moe';
cmp_deeply(as_hash($autohash),{name=>'Moe',hobbies=>['hiking','cooking']},'change 1 element as hash');
@$autohash{qw(name hobbies)}=('Joe',['running','rowing']);
cmp_deeply(as_hash($autohash),{name=>'Joe',hobbies=>['running','rowing']},'change 2 elements as hash');

$autohash->name;
$autohash->name('Moe');                   # sets name to 'Moe'
$autohash->hobbies(['blading','rowing']); # sets hobbies to ['blading','rowing']
cmp_deeply(as_hash($autohash),{name=>'Moe',hobbies=>['blading','rowing']},'change elements as hash');

$autohash->{first_name}='Joe';
$autohash->last_name('Plumber');
cmp_deeply(as_hash($autohash), {name=>'Moe',hobbies=>['blading','rowing'],
				first_name=>'Joe',last_name=>'Plumber'},'add elements');

use Hash::AutoHash qw(autohash_alias);
autohash_alias($autohash,%hash);
my $name=$hash{name};		# instead of $autohash->{name}
is($name,'Moe','access aliased hash');
my @keys=keys %hash;         # instead of keys %$autohash
cmp_set(\@keys,[qw(name hobbies first_name last_name)],'keys of aliased hash');

use Hash::AutoHash qw(autohash_get autohash_set);
 
my($name,$hobbies)=autohash_get($autohash,qw(name hobbies));
cmp_deeply([$name,$hobbies],['Moe',['blading','rowing']],'autohash_get');

autohash_set($autohash,name=>'Joe Plumber',first_name=>'Joe');
cmp_deeply(as_hash($autohash), {name=>'Joe Plumber',hobbies=>['blading','rowing'],
				first_name=>'Joe',last_name=>'Plumber'},'autohash_set: key=>value form');
autohash_set($autohash,['name','first_name'],['Joe Plumber','Joe']);
cmp_deeply(as_hash($autohash), {name=>'Joe Plumber',hobbies=>['blading','rowing'],
				first_name=>'Joe',last_name=>'Plumber'},'autohash_set: separate ARRAYs form');


# Functions for hash-like operations

use Hash::AutoHash 
  qw(autohash_clear autohash_delete autohash_each autohash_exists 
     autohash_keys autohash_values 
     autohash_count autohash_empty autohash_notempty);

autohash_clear($autohash);
cmp_deeply(as_hash($autohash),{},'autohash_clear');

my $autohash=autohash_hash name=>'Joe',hobbies=>['hiking','cooking']; # not in docs
my @keys=qw(hobbies);
autohash_delete($autohash,@keys);
cmp_deeply(as_hash($autohash),{name=>'Joe'},'autohash_delete');

my $key='hobbies';
if (autohash_exists($autohash,$key)) { fail('autohash_exists') } else {pass('autohash_exists') }

my %hash;
while (my($key,$value)=autohash_each($autohash)) { $hash{$key}=$value }
cmp_deeply(as_hash($autohash),\%hash,'autohash_each array context');

my @keys;
while (my $key=autohash_each($autohash)) { push(@keys,$key) }
# cmp_deeply(\@keys,['name'],'autohash_each scalar context');
cmp_set(\@keys,['name'],'autohash_each scalar context');

my @keys=autohash_keys($autohash);
# cmp_deeply(\@keys,['name'],'autohash_keys');
cmp_set(\@keys,['name'],'autohash_keys');

my @values=autohash_values($autohash);
# cmp_deeply(\@values,['Joe'],'autohash_values');
cmp_set(\@values,['Joe'],'autohash_values');

my $count=autohash_count($autohash);
is($count,1,'autohash_count');

if (autohash_empty($autohash)) { fail('autohash_empty') } else {pass('autohash_empty') };

if (autohash_notempty($autohash)) { pass('autohash_empty')  } else {fail('autohash_empty') };

# Subclassing

package TypicalChild;
use Hash::AutoHash;
our @ISA=qw(Hash::AutoHash);
our @NORMAL_EXPORT_OK=();
our %RENAME_EXPORT_OK=();
our @RENAME_EXPORT_OK=sub {s/^autohash/typicalchild/; $_};
our @EXPORT_OK=TypicalChild::helper->EXPORT_OK;
our @SUBCLASS_EXPORT_OK=TypicalChild::helper->SUBCLASS_EXPORT_OK;

#############################################################
# helper package to avoid polluting TypicalChild namespace
#############################################################
package TypicalChild::helper;
use Hash::AutoHash qw(autohash_tie autohash_set);
use Tie::Hash::MultiValue;
BEGIN {
  our @ISA=qw(Hash::AutoHash::helper);
}
sub _new {
  my($helper_class,$class,@args)=@_;
  my $self=autohash_tie Tie::Hash::MultiValue;
  autohash_set($self,@args);
  bless $self,$class;
}
1;

# following code not in doc. minimal test that subclass worked
package main;

import TypicalChild qw(typicalchild_keys);
my $child=new TypicalChild key1=>value11,key2=>value21;
cmp_deeply(as_hash($child),{key1=>['value11'],key2=>['value21']},'new TypicalChild');
my @keys=typicalchild_keys($child);
cmp_set(\@keys,[qw(key1 key2)],'typicalchild_keys');

# tests below just confirm syntax of examples
my @NORMAL_EXPORT_OK=qw(autohash_set typicalchild_function);
cmp_deeply(\@NORMAL_EXPORT_OK,[qw(autohash_set typicalchild_function)],'NORMAL_EXPORT_OK');

my %NORMAL_EXPORT_OK=(learn=>'autohash_set',forget=>'autohash_delete');
cmp_deeply(\%NORMAL_EXPORT_OK,{learn=>'autohash_set',forget=>'autohash_delete'},'NORMAL_EXPORT_OK');

my @RENAME_EXPORT_OK=sub {s/^autohash/typicalchild/; $_};
ok(@RENAME_EXPORT_OK==1 && CODE eq ref($RENAME_EXPORT_OK[0]),'RENAME_EXPORT_OK no functions');

my @RENAME_EXPORT_OK=(sub {s/^autohash/typicalchild/; $_}, qw(autohash_exists autohash_get));
ok(@RENAME_EXPORT_OK==3 && CODE eq ref($RENAME_EXPORT_OK[0]),'RENAME_EXPORT_OK w/ functions');

# no easy way to test this one
# my @EXPORT_OK=TypicalChild::helper->EXPORT_OK

my @EXPORT_OK=qw(learn forget);
cmp_deeply(\@EXPORT_OK,[qw(learn forget)],'EXPORT_OK');

# no easy way to test this one
# my @SUBCLASS_EXPORT_OK=TypicalChild::helper->SUBCLASS_EXPORT_OK

my @SUBCLASS_EXPORT_OK=qw(learn forget);
cmp_deeply(\@SUBCLASS_EXPORT_OK,[qw(learn forget)],'SUBCLASS_EXPORT_OK');

done_testing();
