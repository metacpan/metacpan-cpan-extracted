use lib qw(t);
use Carp;
use Hash::AutoHash::MultiValued;
use Test::More;
use Test::Deep;
use mvhashUtil;

################################################################################
# SYNOPSIS
################################################################################
use Hash::AutoHash::MultiValued;

# create object and set intial values
my $mvhash=new Hash::AutoHash::MultiValued name=>'Joe',hobbies=>'chess',hobbies=>'cooking';
cmp_mvhash('create object and set intial values',$mvhash,
	   {name=>[qw(Joe)],hobbies=>[qw(chess cooking)]});

# access or change hash elements via methods
my $name=$mvhash->name;		   # ['Joe']
cmp_deeply($name,[qw(Joe)],'access via methods: single value scalar context');
my $hobbies=$mvhash->hobbies;	   # ['chess','cooking']
cmp_deeply($hobbies,[qw(chess cooking)],'access via methods: multiple values scalar context');
my @hobbies=$mvhash->hobbies;	   # ('chess','cooking')
cmp_deeply(\@hobbies,[qw(chess cooking)],'access via methods: multiple values array context');
$mvhash->hobbies('go','rowing');   # new values added to existing ones
cmp_mvhash('update via methods',$mvhash,
	   {name=>[qw(Joe)],hobbies=>[qw(chess cooking go rowing)]});
my $hobbies=$mvhash->hobbies;	   # ['chess','cooking','go','rowing']
cmp_deeply($hobbies,[qw(chess cooking go rowing)],'access via methods after update');

# you can also use standard hash notation and functions
my($name,$hobbies)=@$mvhash{qw(name hobbies)};	# get 2 elements in one statement
cmp_deeply($name,[qw(Joe)],'access as hash: single value scalar context');
cmp_deeply($hobbies,[qw(chess cooking go rowing)],'access as hash: multiple values scalar context');
$mvhash->{name}='Plumber';	# set name to ['Joe','Plumber']   
cmp_mvhash('update as hash',$mvhash,
	   {name=>[qw(Joe Plumber)],hobbies=>[qw(chess cooking go rowing)]});

my @keys=keys %$mvhash;		# ('name','hobbies')
# NG 12-11-29: as of Perl 5.16 or so, the order of hash keys is randomized
# cmp_deeply(\@keys,[qw(name hobbies)],'keys as hash');
cmp_set(\@keys,[qw(name hobbies)],'keys as hash');

my @values=values %$mvhash;	# (['Joe','Plumber'],
                                #  ['chess','cooking','go','rowing'])
# cmp_deeply(\@values,[[qw(Joe Plumber)],[qw(chess cooking go rowing)]],'values as hash');
cmp_set(\@values,[[qw(Joe Plumber)],[qw(chess cooking go rowing)]],'values as hash');

my(@keys,@values);		# NOT in docs. needed for testing
while (my($key,$value)=each %$mvhash) {
#  print "$key => @$value\n";	# prints each element as usual
  push(@keys,$key);		# NOT in docs. needed for testing
  push(@values,$value);		# NOT in docs. needed for testing
}
# cmp_deeply(\@keys,[qw(name hobbies)],'each as hash (keys)');
# cmp_deeply(\@values,[[qw(Joe Plumber)],[qw(chess cooking go rowing)]],'each as hash (values)');
cmp_set(\@keys,[qw(name hobbies)],'each as hash (keys)');
cmp_set(\@values,[[qw(Joe Plumber)],[qw(chess cooking go rowing)]],'each as hash (values)');

delete $mvhash->{hobbies};	# no more hobbies
cmp_mvhash('delete',$mvhash,{name=>[qw(Joe Plumber)]});

# CAUTION: hash notation doesn't respect array context!
$mvhash->{hobbies}=('go','rowing'); # sets hobbies to last value only
cmp_mvhash('update as hash - does not handle lists',$mvhash,{name=>[qw(Joe Plumber)],hobbies=>[qw(rowing)]});
my @hobbies=$mvhash->{hobbies};	    # @hobbies is (['go'])
cmp_deeply(\@hobbies,[[qw(rowing)]],'access as hash does not respect array context');

# alias $mvhash to regular hash for more concise hash notation
use Hash::AutoHash::MultiValued qw(autohash_alias);
my %hash;
autohash_alias($mvhash,%hash);
cmp_mvhash('autohash_alias',$mvhash,
	   {name=>[qw(Joe Plumber)],hobbies=>[qw(rowing)]},'hash',undef,\%hash);

# access or change hash elements without using ->
$hash{hobbies}=['chess','cooking']; # append values to hobbies 
cmp_mvhash('update via alias',$mvhash,
	   {name=>[qw(Joe Plumber)],hobbies=>[qw(rowing chess cooking)]},'hash',undef,\%hash);
my $name=$hash{name};		    # ['Joe','Plumber']
cmp_deeply($name,[qw(Joe Plumber)],'access via alias: name');
my $hobbies=$hash{hobbies};	    # ['go','chess','cooking']
cmp_deeply($hobbies,[qw(rowing chess cooking)],'access via alias: hobbies');
# another way to do the same thing
my($name,$hobbies)=@hash{qw(name hobbies)};
cmp_deeply([$name,$hobbies],
	   [[qw(Joe Plumber)],[qw(rowing chess cooking)]],'access via alias: name,hobbies');

# set 'unique' in tied object to eliminate duplicates
use Hash::AutoHash::MultiValued qw(autohash_tied);
autohash_tied($mvhash)->unique(1);
$mvhash->hobbies('go','cooking','rowing');
cmp_mvhash('unique',$mvhash,
	   {name=>[qw(Joe Plumber)],hobbies=>[qw(rowing chess cooking go)]},
	   'hash',undef,\%hash);
my @hobbies=$mvhash->hobbies;	# @hobbies is ('go','chess','cooking','rowing')
cmp_deeply(\@hobbies,[qw(rowing chess cooking go)],'access after unique');

################################################################################
# DESCRIPTION
################################################################################
#### autohash functions
use Hash::AutoHash::MultiValued qw(autohash_keys autohash_delete);
my $mvhash=new Hash::AutoHash::MultiValued name=>[],hobbies=>'chess';
cmp_mvhash('key with empty value',$mvhash,{name=>[],hobbies=>[qw(chess)]});
my @keys=autohash_keys($mvhash);
for my $key (@keys) {
  my @values=$mvhash->$key;
  autohash_delete($mvhash,$key) unless @values;
}
cmp_mvhash('after deleting key with empty value',$mvhash,{hobbies=>[qw(chess)]});

#### Duplicate elimination and filtering
my $mvhash=new Hash::AutoHash::MultiValued hobbies=>'go',hobbies=>'go';
cmp_mvhash('create example for unique',$mvhash,{hobbies=>[qw(go go)]});
my @hobbies=$mvhash->hobbies;         # ('go','go')
cmp_deeply(\@hobbies,[qw(go go)],'access duplicate values');

autohash_tied($mvhash)->unique(1);
cmp_mvhash('setting unique removes duplicates',$mvhash,{hobbies=>[qw(go)]});
my @hobbies=$mvhash->hobbies;         # now ('go')
cmp_deeply(\@hobbies,[qw(go)],'access after setting unique');

my $mvhash=new Hash::AutoHash::MultiValued hobbies=>['GO','go'];
cmp_mvhash('create example for unique sub',$mvhash,{hobbies=>[qw(GO go)]});
autohash_tied($mvhash)->unique(sub {my($a,$b)=@_; lc($a) eq lc($b)});
cmp_mvhash('setting unique sub removes case insensitve duplicates',$mvhash,{hobbies=>[qw(GO)]});
my @hobbies=$mvhash->hobbies;         # @hobbies is ('GO')
cmp_deeply(\@hobbies,[qw(GO)],'access after setting unique sub');

sub uniq_nocase_sort {
  my %uniq;
  my @values_lc=map { lc($_) } @_;
  @uniq{@values_lc}=@_;
  sort values %uniq;  
}

my $mvhash=new Hash::AutoHash::MultiValued hobbies=>['GO','go','dance'];
cmp_mvhash('example for filter sub',$mvhash,{hobbies=>[qw(GO go dance)]});
autohash_tied($mvhash)->filter(\&uniq_nocase_sort);
cmp_mvhash('setting filter sub removes duplicates and sorts',$mvhash,{hobbies=>[qw(dance go)]});
my @hobbies=$mvhash->hobbies;	# @hobbies is ('dance','go')
cmp_deeply(\@hobbies,[qw(dance go)],'access after setting filter sub');

my $mvhash=new Hash::AutoHash::MultiValued hobbies=>['GO','go','dance'];
cmp_mvhash('example for filter one-liner',$mvhash,{hobbies=>[qw(GO go dance)]});
autohash_tied($mvhash)->filter(sub {my %u; @u{map {lc $_} @_}=@_; sort values %u});
cmp_mvhash('filter one-liner removes duplicates and sorts',$mvhash,{hobbies=>[qw(dance go)]});

#### Functions and methods
$mvhash=new Hash::AutoHash::MultiValued name=>'Joe',hobbies=>'chess',hobbies=>'cooking';
cmp_mvhash('new',$mvhash, {name=>[qw(Joe)],hobbies=>[qw(chess cooking)]});
$mvhash=new Hash::AutoHash::MultiValued [name=>'Joe',hobbies=>'chess',hobbies=>'cooking'];
cmp_mvhash('new ARRAY',$mvhash, {name=>[qw(Joe)],hobbies=>[qw(chess cooking)]});
$mvhash=new Hash::AutoHash::MultiValued {name=>'Joe',hobbies=>['chess','cooking']};
cmp_mvhash('new HASH',$mvhash, {name=>[qw(Joe)],hobbies=>[qw(chess cooking)]});

## unique
my $boolean=1;
sub function1 {lc($_[0]) eq lc($_[1])}

my $mvhash=new Hash::AutoHash::MultiValued hobbies=>'go',hobbies=>'go';
cmp_mvhash('create example for unique form 1',$mvhash,{hobbies=>[qw(go go)]});
my $unique=tied(%$mvhash)->unique;
cmp_mvhash('unique form 1',$mvhash,{hobbies=>[qw(go go)]});
ok(!$unique,'value returned by unique form 1');

my $mvhash=new Hash::AutoHash::MultiValued hobbies=>'go',hobbies=>'go';
cmp_mvhash('create example for unique form 2',$mvhash,{hobbies=>[qw(go go)]});
tied(%$mvhash)->unique($boolean);
cmp_mvhash('unique form 2',$mvhash,{hobbies=>[qw(go)]});

my $mvhash=new Hash::AutoHash::MultiValued hobbies=>'chess',hobbies=>'GO',hobbies=>'go';
cmp_mvhash('create example for unique form 3',$mvhash,{hobbies=>[qw(chess GO go)]});
tied(%$mvhash)->unique(\&function1);
cmp_mvhash('unique form 3',$mvhash,{hobbies=>[qw(chess GO)]});

my $mvhash=new Hash::AutoHash::MultiValued hobbies=>'go',hobbies=>'go';
cmp_mvhash('create example for unique form 4',$mvhash,{hobbies=>[qw(go go)]});
my $unique=autohash_tied($mvhash)->unique;
cmp_mvhash('unique form 4',$mvhash,{hobbies=>[qw(go go)]});
ok(!$unique,'value returned by unique form 4');

my $mvhash=new Hash::AutoHash::MultiValued hobbies=>'go',hobbies=>'go';
cmp_mvhash('create example for unique form 5',$mvhash,{hobbies=>[qw(go go)]});
autohash_tied($mvhash)->unique($boolean);
cmp_mvhash('unique form 5',$mvhash,{hobbies=>[qw(go)]});

my $mvhash=new Hash::AutoHash::MultiValued hobbies=>'chess',hobbies=>'GO',hobbies=>'go';
cmp_mvhash('create example for unique form 6',$mvhash,{hobbies=>[qw(chess GO go)]});
autohash_tied($mvhash)->unique(\&function1);
cmp_mvhash('unique form 6',$mvhash,{hobbies=>[qw(chess GO)]});

## filter
my $boolean=1;
sub function2 {my %u; @_=map {lc $_} @_; @u{@_}=@_; values %u}

my $mvhash=new Hash::AutoHash::MultiValued hobbies=>'go',hobbies=>'go';
cmp_mvhash('create example for filter form 1',$mvhash,{hobbies=>[qw(go go)]});
my $filter=tied(%$mvhash)->filter;
cmp_mvhash('filter form 1',$mvhash,{hobbies=>[qw(go go)]});
ok(!$filter,'value returned by filter form 1');

my $mvhash=new Hash::AutoHash::MultiValued hobbies=>'go',hobbies=>'go';
cmp_mvhash('create example for filter form 2',$mvhash,{hobbies=>[qw(go go)]});
tied(%$mvhash)->filter($boolean);
cmp_mvhash('filter form 2',$mvhash,{hobbies=>[qw(go)]});

my $mvhash=new Hash::AutoHash::MultiValued hobbies=>'GO',hobbies=>'go';
cmp_mvhash('create example for filter form 3',$mvhash,{hobbies=>[qw(GO go)]});
tied(%$mvhash)->filter(\&function2);
cmp_mvhash('filter form 3',$mvhash,{hobbies=>[qw(go)]});

my $mvhash=new Hash::AutoHash::MultiValued hobbies=>'go',hobbies=>'go';
cmp_mvhash('create example for filter form 4',$mvhash,{hobbies=>[qw(go go)]});
my $filter=autohash_tied($mvhash)->filter;
cmp_mvhash('filter form 4',$mvhash,{hobbies=>[qw(go go)]});
ok(!$filter,'value returned by filter form 4');

my $mvhash=new Hash::AutoHash::MultiValued hobbies=>'go',hobbies=>'go';
cmp_mvhash('create example for filter form 5',$mvhash,{hobbies=>[qw(go go)]});
autohash_tied($mvhash)->filter($boolean);
cmp_mvhash('filter form 5',$mvhash,{hobbies=>[qw(go)]});

my $mvhash=new Hash::AutoHash::MultiValued hobbies=>'GO',hobbies=>'go';
cmp_mvhash('create example for filter form 6',$mvhash,{hobbies=>[qw(GO go)]});
autohash_tied($mvhash)->filter(\&function2);
cmp_mvhash('filter form 6',$mvhash,{hobbies=>[qw(go)]});

## functions inherited from Hash::AutoHash

use Hash::AutoHash::MultiValued
  qw(autohash_alias autohash_tied autohash_get autohash_set
     autohash_clear autohash_delete autohash_each autohash_exists 
     autohash_keys autohash_values 
     autohash_count autohash_empty autohash_notempty);
my $mvhash=new Hash::AutoHash::MultiValued name=>'Joe',hobbies=>'chess',hobbies=>'cooking';
my(%hash,$tied,$result);
autohash_alias($mvhash,%hash);
cmp_mvhash('create example for autohash_alias',$mvhash,
	   {name=>[qw(Joe)],hobbies=>[qw(chess cooking)]},'hash',undef,\%hash);

$tied=autohash_tied($mvhash);
cmp_mvhash('autohash_tied form 1',$mvhash,
	   {name=>[qw(Joe)],hobbies=>[qw(chess cooking)]},'hash','object',\%hash,$tied);
$tied=autohash_tied(%hash);
cmp_mvhash('autohash_tied form 2',$mvhash,
	   {name=>[qw(Joe)],hobbies=>[qw(chess cooking)]},'hash','object',\%hash,$tied);
$result=autohash_tied($mvhash,'FETCH','name');
cmp_deeply($result,[qw(Joe)],'autohash_tied form 3');
$result=autohash_tied(%hash,'FETCH','name');
cmp_deeply($result,[qw(Joe)],'autohash_tied form 4');

($name,$hobbies)=autohash_get($mvhash,qw(name hobbies));
cmp_deeply([$name,$hobbies],[[qw(Joe)],[qw(chess cooking)]],'autohash_get');

autohash_set($mvhash,name=>'Plumber',first_name=>'Joe');
cmp_mvhash('autohash_set',$mvhash,
	   {name=>[qw(Joe Plumber)],first_name=>[qw(Joe)],hobbies=>[qw(chess cooking)]});

autohash_clear($mvhash);
cmp_mvhash('autohash_clear',$mvhash,{});

my $mvhash=new Hash::AutoHash::MultiValued name=>'Joe',first_name=>'Joe',hobbies=>[qw(chess cooking)];
cmp_mvhash('create example again',$mvhash,
	   {name=>[qw(Joe)],first_name=>[qw(Joe)],hobbies=>[qw(chess cooking)]});
my @keys=qw(name hobbies);
autohash_delete($mvhash,@keys);
cmp_mvhash('autohash_delete',$mvhash,{first_name=>[qw(Joe)]});

my $key='first_name';
if (autohash_exists($mvhash,$key)) {pass('autohash_exists')} else {fail('autohash_exists')}

my(@keys,@values);
my $mvhash=new Hash::AutoHash::MultiValued name=>'Joe',hobbies=>[qw(chess cooking)];
cmp_mvhash('create example again',$mvhash,{name=>[qw(Joe)],hobbies=>[qw(chess cooking)]});
while (my($key,$value)=autohash_each($mvhash)) { push(@keys,$key); push(@values,$value); }
# cmp_deeply(\@keys,[qw(name hobbies)],'autohash_each form 1 (keys)');
# cmp_deeply(\@values,[[qw(Joe)],[qw(chess cooking)]],'autohash_each form 1 (values)');
cmp_set(\@keys,[qw(name hobbies)],'autohash_each form 1 (keys)');
cmp_set(\@values,[[qw(Joe)],[qw(chess cooking)]],'autohash_each form 1 (values)');
my(@keys,@values);
while (my $key=autohash_each($mvhash)) { push(@keys,$key); }
# cmp_deeply(\@keys,[qw(name hobbies)],'autohash_each form 2 (keys)');
cmp_set(\@keys,[qw(name hobbies)],'autohash_each form 2 (keys)');

my(@keys,@values);
@keys=autohash_keys($mvhash);
# cmp_deeply(\@keys,[qw(name hobbies)],'autohash_keys');
cmp_set(\@keys,[qw(name hobbies)],'autohash_keys');
@values=autohash_values($mvhash);
# cmp_deeply(\@values,[[qw(Joe)],[qw(chess cooking)]],'autohash_values');
cmp_set(\@values,[[qw(Joe)],[qw(chess cooking)]],'autohash_values');

my $count;
$count=autohash_count($mvhash);
is($count,2,'autohash_count');

if (autohash_empty($mvhash)) {fail('autohash_empty')} else {pass('autohash_empty')}
if (autohash_notempty($mvhash)) {pass('autohash_empty')} else {fail('autohash_empty')}

done_testing();
