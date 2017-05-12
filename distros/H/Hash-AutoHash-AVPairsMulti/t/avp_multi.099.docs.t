use lib qw(t);
use Carp;
use Hash::AutoHash::AVPairsMulti;
use Test::More;
use Test::Deep;
use autohashUtil;

################################################################################
# SYNOPSIS
################################################################################
use Hash::AutoHash::AVPairsMulti;

# create object and set intial values
my $avp=new Hash::AutoHash::AVPairsMulti pets=>'Spot',hobbies=>'chess',hobbies=>'cooking';
cmp_autohash('create object and set intial values',$avp,
	     {pets=>[qw(Spot)],hobbies=>[qw(chess cooking)]});

# access or change hash elements via methods
my $pets=$avp->pets;		   # ['Spot']
cmp_deeply($pets,[qw(Spot)],'access via methods: single value scalar context');
my @pets=$avp->pets;		   # ['Spot']
cmp_deeply(\@pets,[qw(Spot)],'access via methods: single value array context');
my $hobbies=$avp->hobbies;	   # ['chess','cooking']
cmp_deeply($hobbies,[qw(chess cooking)],'access via methods: multiple values scalar context');
my @hobbies=$avp->hobbies;	   # ('chess','cooking')
cmp_deeply(\@hobbies,[qw(chess cooking)],'access via methods: multiple values array context');
$avp->hobbies('go','rowing');      # new values added to existing ones
cmp_autohash('update via methods',$avp,
	   {pets=>[qw(Spot)],hobbies=>[qw(chess cooking go rowing)]});
my $hobbies=$avp->hobbies;	   # ['chess','cooking','go','rowing']
cmp_deeply($hobbies,[qw(chess cooking go rowing)],'access via methods after update');
eval {$avp->family({kids=>'Joey'})};# illegal - reference
ok($@=~/Trying to store reference/,'ILLEGAL. reference');

# you can also use standard hash notation and functions
my($pets,$hobbies)=@$avp{qw(pets hobbies)};	# get 2 elements in one statement
cmp_deeply([$pets,$hobbies],
	   [[qw(Spot)],[qw(chess cooking go rowing)]],'access as hash: multiple values');
$avp->{pets}='Felix';	                 # set pets to ['Spot','Felix']   
cmp_autohash('update as hash',$avp,
	     {pets=>[qw(Spot Felix)],hobbies=>[qw(chess cooking go rowing)]});
my @keys=keys %$avp;		# ('pets','hobbies')
# NG 12-11-29: as of Perl 5.16 or so, the order of hash keys is randomized
# cmp_deeply(\@keys,[qw(pets hobbies)],'keys as hash');
cmp_set(\@keys,[qw(pets hobbies)],'keys as hash');
my @values=values %$avp;	# (['Spot','Felix'],
                                #  ['chess','cooking','go','rowing'])
# cmp_deeply(\@values,[[qw(Spot Felix)],[qw(chess cooking go rowing)]],'values as hash');
cmp_set(\@values,[[qw(Spot Felix)],[qw(chess cooking go rowing)]],'values as hash');

my(@keys,@values);		# NOT in docs. needed for testing
while (my($key,$value)=each %$avp) {
#  print "$key => @$value\n";	# prints each element as usual
  push(@keys,$key);		# NOT in docs. needed for testing
  push(@values,$value);		# NOT in docs. needed for testing
}
# NG 12-11-29: as of Perl 5.16 or so, the order of hash keys is randomized
# cmp_deeply(\@keys,[qw(pets hobbies)],'each as hash (keys)');
# cmp_deeply(\@values,[[qw(Spot Felix)],[qw(chess cooking go rowing)]],'each as hash (values)');
cmp_set(\@keys,[qw(pets hobbies)],'each as hash (keys)');
cmp_set(\@values,[[qw(Spot Felix)],[qw(chess cooking go rowing)]],'each as hash (values)');

delete $avp->{hobbies};	# no more hobbies
cmp_autohash('delete',$avp,{pets=>[qw(Spot Felix)]});

# CAUTION: hash notation doesn't respect array context!
$avp->{hobbies}=('go','rowing'); # sets hobbies to last value only
cmp_autohash('update as hash - does not handle lists',$avp,
	     {pets=>[qw(Spot Felix)],hobbies=>[qw(rowing)]});
my @hobbies=$avp->{hobbies};	    # @hobbies is (['rowing'])
cmp_deeply(\@hobbies,[[qw(rowing)]],'access as hash does not respect array context');

# alias $avp to regular hash for more concise hash notation
use Hash::AutoHash::AVPairsMulti qw(autohash_alias);
my %hash;
autohash_alias($avp,%hash);
cmp_autohash('autohash_alias',$avp,
	   {pets=>[qw(Spot Felix)],hobbies=>[qw(rowing)]},'hash',undef,\%hash);

# access or change hash elements without using ->
$hash{hobbies}=['chess','cooking']; # append values to hobbies 
cmp_autohash('update via alias',$avp,
	   {pets=>[qw(Spot Felix)],hobbies=>[qw(rowing chess cooking)]},'hash',undef,\%hash);
my $pets=$hash{pets};		    # ['Spot','Felix']
cmp_deeply($pets,[qw(Spot Felix)],'access via alias: name');
my $hobbies=$hash{hobbies};	    # ['go','chess','cooking']
cmp_deeply($hobbies,[qw(rowing chess cooking)],'access via alias: hobbies');
# another way to do the same thing
my($pets,$hobbies)=@hash{qw(pets hobbies)};
cmp_deeply([$pets,$hobbies],
	   [[qw(Spot Felix)],[qw(rowing chess cooking)]],'access via alias: multiple values');

# set 'unique' in tied object to eliminate duplicates
use Hash::AutoHash::AVPairsMulti qw(autohash_tied);
autohash_tied($avp)->unique(1);
$avp->hobbies('cooking','baking');
cmp_autohash('unique',$avp,
	   {pets=>[qw(Spot Felix)],hobbies=>[qw(rowing chess cooking baking)]},
	   'hash',undef,\%hash);
my @hobbies=$avp->hobbies;	# ('rowing','chess','cooking','baking')
cmp_deeply(\@hobbies,[qw(rowing chess cooking baking)],'access after unique');

################################################################################
# DESCRIPTION
################################################################################
#### Duplicate elimination and filtering
my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>'go',hobbies=>'go';
cmp_autohash('create example for unique',$avp,{hobbies=>[qw(go go)]});
my @hobbies=$avp->hobbies;         # ('go','go')
cmp_deeply(\@hobbies,[qw(go go)],'access duplicate values');

autohash_tied($avp)->unique(1);
cmp_autohash('setting unique removes duplicates',$avp,{hobbies=>[qw(go)]});
my @hobbies=$avp->hobbies;         # now ('go')
cmp_deeply(\@hobbies,[qw(go)],'access after setting unique');

my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>['GO','go'];
cmp_autohash('create example for unique sub',$avp,{hobbies=>[qw(GO go)]});
autohash_tied($avp)->unique(sub {my($a,$b)=@_; lc($a) eq lc($b)});
cmp_autohash('setting unique sub removes case insensitve duplicates',$avp,{hobbies=>[qw(GO)]});
my @hobbies=$avp->hobbies;         # @hobbies is ('GO')
cmp_deeply(\@hobbies,[qw(GO)],'access after setting unique sub');

sub uniq_nocase_sort {
  my %uniq;
  my @values_lc=map { lc($_) } @_;
  @uniq{@values_lc}=@_;
  sort values %uniq;  
}

my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>['GO','go','dance'];
cmp_autohash('example for filter sub',$avp,{hobbies=>[qw(GO go dance)]});
autohash_tied($avp)->filter(\&uniq_nocase_sort);
cmp_autohash('setting filter sub removes duplicates and sorts',$avp,{hobbies=>[qw(dance go)]});
my @hobbies=$avp->hobbies;	# @hobbies is ('dance','go')
cmp_deeply(\@hobbies,[qw(dance go)],'access after setting filter sub');

my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>['GO','go','dance'];
cmp_autohash('example for filter one-liner',$avp,{hobbies=>[qw(GO go dance)]});
autohash_tied($avp)->filter(sub {my %u; @u{map {lc $_} @_}=@_; sort values %u});
cmp_autohash('filter one-liner removes duplicates and sorts',$avp,{hobbies=>[qw(dance go)]});

#### Functions and methods
$avp=new Hash::AutoHash::AVPairsMulti pets=>'Spot',hobbies=>'chess',hobbies=>'cooking';
cmp_autohash('new',$avp, {pets=>[qw(Spot)],hobbies=>[qw(chess cooking)]});
$avp=new Hash::AutoHash::AVPairsMulti [pets=>'Spot',hobbies=>'chess',hobbies=>'cooking'];
cmp_autohash('new ARRAY',$avp, {pets=>[qw(Spot)],hobbies=>[qw(chess cooking)]});
$avp=new Hash::AutoHash::AVPairsMulti {pets=>'Spot',hobbies=>['chess','cooking']};
cmp_autohash('new HASH',$avp, {pets=>[qw(Spot)],hobbies=>[qw(chess cooking)]});

## unique
my $boolean=1;
sub function1 {lc($_[0]) eq lc($_[1])}

my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>'go',hobbies=>'go';
cmp_autohash('create example for unique form 1',$avp,{hobbies=>[qw(go go)]});
my $unique=tied(%$avp)->unique;
cmp_autohash('unique form 1',$avp,{hobbies=>[qw(go go)]});
ok(!$unique,'value returned by unique form 1');

my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>'go',hobbies=>'go';
cmp_autohash('create example for unique form 2',$avp,{hobbies=>[qw(go go)]});
tied(%$avp)->unique($boolean);
cmp_autohash('unique form 2',$avp,{hobbies=>[qw(go)]});

my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>'chess',hobbies=>'GO',hobbies=>'go';
cmp_autohash('create example for unique form 3',$avp,{hobbies=>[qw(chess GO go)]});
tied(%$avp)->unique(\&function1);
cmp_autohash('unique form 3',$avp,{hobbies=>[qw(chess GO)]});

my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>'go',hobbies=>'go';
cmp_autohash('create example for unique form 4',$avp,{hobbies=>[qw(go go)]});
my $unique=autohash_tied($avp)->unique;
cmp_autohash('unique form 4',$avp,{hobbies=>[qw(go go)]});
ok(!$unique,'value returned by unique form 4');

my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>'go',hobbies=>'go';
cmp_autohash('create example for unique form 5',$avp,{hobbies=>[qw(go go)]});
autohash_tied($avp)->unique($boolean);
cmp_autohash('unique form 5',$avp,{hobbies=>[qw(go)]});

my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>'chess',hobbies=>'GO',hobbies=>'go';
cmp_autohash('create example for unique form 6',$avp,{hobbies=>[qw(chess GO go)]});
autohash_tied($avp)->unique(\&function1);
cmp_autohash('unique form 6',$avp,{hobbies=>[qw(chess GO)]});

## filter
my $boolean=1;
sub function2 {my %u; @_=map {lc $_} @_; @u{@_}=@_; values %u}

my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>'go',hobbies=>'go';
cmp_autohash('create example for filter form 1',$avp,{hobbies=>[qw(go go)]});
my $filter=tied(%$avp)->filter;
cmp_autohash('filter form 1',$avp,{hobbies=>[qw(go go)]});
ok(!$filter,'value returned by filter form 1');

my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>'go',hobbies=>'go';
cmp_autohash('create example for filter form 2',$avp,{hobbies=>[qw(go go)]});
tied(%$avp)->filter($boolean);
cmp_autohash('filter form 2',$avp,{hobbies=>[qw(go)]});

my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>'GO',hobbies=>'go';
cmp_autohash('create example for filter form 3',$avp,{hobbies=>[qw(GO go)]});
tied(%$avp)->filter(\&function2);
cmp_autohash('filter form 3',$avp,{hobbies=>[qw(go)]});

my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>'go',hobbies=>'go';
cmp_autohash('create example for filter form 4',$avp,{hobbies=>[qw(go go)]});
my $filter=autohash_tied($avp)->filter;
cmp_autohash('filter form 4',$avp,{hobbies=>[qw(go go)]});
ok(!$filter,'value returned by filter form 4');

my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>'go',hobbies=>'go';
cmp_autohash('create example for filter form 5',$avp,{hobbies=>[qw(go go)]});
autohash_tied($avp)->filter($boolean);
cmp_autohash('filter form 5',$avp,{hobbies=>[qw(go)]});

my $avp=new Hash::AutoHash::AVPairsMulti hobbies=>'GO',hobbies=>'go';
cmp_autohash('create example for filter form 6',$avp,{hobbies=>[qw(GO go)]});
autohash_tied($avp)->filter(\&function2);
cmp_autohash('filter form 6',$avp,{hobbies=>[qw(go)]});

## functions inherited from Hash::AutoHash

use Hash::AutoHash::AVPairsMulti
  qw(autohash_alias autohash_tied autohash_get autohash_set
     autohash_clear autohash_delete autohash_each autohash_exists 
     autohash_keys autohash_values 
     autohash_count autohash_empty autohash_notempty);
my $avp=new Hash::AutoHash::AVPairsMulti pets=>'Spot',hobbies=>'chess',hobbies=>'cooking';
my(%hash,$tied,$result);
autohash_alias($avp,%hash);
cmp_autohash('create example for autohash_alias',$avp,
	   {pets=>[qw(Spot)],hobbies=>[qw(chess cooking)]},'hash',undef,\%hash);

$tied=autohash_tied($avp);
cmp_autohash('autohash_tied form 1',$avp,
	   {pets=>[qw(Spot)],hobbies=>[qw(chess cooking)]},'hash','object',\%hash,$tied);
$tied=autohash_tied(%hash);
cmp_autohash('autohash_tied form 2',$avp,
	   {pets=>[qw(Spot)],hobbies=>[qw(chess cooking)]},'hash','object',\%hash,$tied);
$result=autohash_tied($avp,'FETCH','pets');
cmp_deeply($result,[qw(Spot)],'autohash_tied form 3');
$result=autohash_tied(%hash,'FETCH','pets');
cmp_deeply($result,[qw(Spot)],'autohash_tied form 4');

($pets,$hobbies)=autohash_get($avp,qw(pets hobbies));
cmp_deeply([$pets,$hobbies],[[qw(Spot)],[qw(chess cooking)]],'autohash_get');

autohash_set($avp,pets=>'Felix',new_key=>'Spot');
cmp_autohash('autohash_set',$avp,
	   {pets=>[qw(Spot Felix)],new_key=>[qw(Spot)],hobbies=>[qw(chess cooking)]});

autohash_clear($avp);
cmp_autohash('autohash_clear',$avp,{});

my $avp=new Hash::AutoHash::AVPairsMulti pets=>'Spot',new_key=>'Spot',hobbies=>[qw(chess cooking)];
cmp_autohash('create example again',$avp,
	   {pets=>[qw(Spot)],new_key=>[qw(Spot)],hobbies=>[qw(chess cooking)]});
my @keys=qw(pets hobbies);
autohash_delete($avp,@keys);
cmp_autohash('autohash_delete',$avp,{new_key=>[qw(Spot)]});

my $key='new_key';
if (autohash_exists($avp,$key)) {pass('autohash_exists')} else {fail('autohash_exists')}

my(@keys,@values);
my $avp=new Hash::AutoHash::AVPairsMulti pets=>'Spot',hobbies=>[qw(chess cooking)];
cmp_autohash('create example again',$avp,{pets=>[qw(Spot)],hobbies=>[qw(chess cooking)]});
while (my($key,$value)=autohash_each($avp)) { push(@keys,$key); push(@values,$value); }
# cmp_deeply(\@keys,[qw(pets hobbies)],'autohash_each form 1 (keys)');
# cmp_deeply(\@values,[[qw(Spot)],[qw(chess cooking)]],'autohash_each form 1 (values)');
cmp_set(\@keys,[qw(pets hobbies)],'autohash_each form 1 (keys)');
cmp_set(\@values,[[qw(Spot)],[qw(chess cooking)]],'autohash_each form 1 (values)');
my(@keys,@values);
while (my $key=autohash_each($avp)) { push(@keys,$key); }
# cmp_deeply(\@keys,[qw(pets hobbies)],'autohash_each form 2 (keys)');
cmp_set(\@keys,[qw(pets hobbies)],'autohash_each form 2 (keys)');

my(@keys,@values);
@keys=autohash_keys($avp);
# cmp_deeply(\@keys,[qw(pets hobbies)],'autohash_keys');
cmp_set(\@keys,[qw(pets hobbies)],'autohash_keys');
@values=autohash_values($avp);
# cmp_deeply(\@values,[[qw(Spot)],[qw(chess cooking)]],'autohash_values');
cmp_set(\@values,[[qw(Spot)],[qw(chess cooking)]],'autohash_values');

my $count;
$count=autohash_count($avp);
is($count,2,'autohash_count');

if (autohash_empty($avp)) {fail('autohash_empty')} else {pass('autohash_empty')}
if (autohash_notempty($avp)) {pass('autohash_empty')} else {fail('autohash_empty')}

done_testing();
