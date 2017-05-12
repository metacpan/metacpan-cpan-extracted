use lib qw(t);
use Carp;
use Hash::AutoHash::AVPairsSingle;
use Test::More;
use Test::Deep;
use autohashUtil;

################################################################################
# SYNOPSIS
################################################################################
use Hash::AutoHash::AVPairsSingle;

# create object and set intial values
my $avp=new Hash::AutoHash::AVPairsSingle name=>'Joe',hobby=>'chess';
cmp_autohash('create object and set intial values',$avp,{name=>'Joe',hobby=>'chess'});

# access or change hash elements via methods
my $name=$avp->name;                        # 'Joe'
is($name,'Joe','access via methods: single value');
$avp->name('Joey');                         # change name to 'Joey'
cmp_autohash('update via methods',$avp,{name=>'Joey',hobby=>'chess'});
eval {$avp->pets({dog=>'Spot'})};          # illegal - reference
ok($@=~/Trying to store reference/,'ILLEGAL. reference');

# you can also use standard hash notation and functions
my $name=$avp->{name};                      # 'Joey'
is($name,'Joey','access as hash: single value');
$avp->{name}='Joe';                         # change name back to 'Joe'
cmp_autohash('update as hash',$avp,{name=>'Joe',hobby=>'chess'});
my($name,$hobby)=@$avp{qw(name hobby)};     # get 2 elements in one statement
cmp_deeply([$name,$hobby],['Joe','chess'],'access as hash: multiple values ');

my @keys=keys %$avp;		# ('name','hobby')
cmp_set(\@keys,[qw(name hobby)],'keys as hash');
my @values=values %$avp;	# ('Joe','chess')
cmp_set(\@values,['Joe','chess'],'values as hash');
my(@keys,@values);		# NOT in docs. needed for testing
while (my($key,$value)=each %$avp) {
#  print "$key => @$value\n";	# prints each element as usual
  push(@keys,$key);		# NOT in docs. needed for testing
  push(@values,$value);		# NOT in docs. needed for testing
}
cmp_set(\@keys,[qw(name hobby)],'each as hash (keys)');
cmp_set(\@values,['Joe','chess'],'each as hash (values)');

delete $avp->{hobby};	# no more hobby
cmp_autohash('delete',$avp,{name=>'Joe'});

# alias $avp to regular hash for more concise hash notation
use Hash::AutoHash::AVPairsSingle qw(autohash_alias);
my %hash;
autohash_alias($avp,%hash);
cmp_autohash('autohash_alias',$avp,{name=>'Joe'},'hash',undef,\%hash);

# access or change hash elements without using ->
$hash{hobby}='go';                         # change hobby to 'go'
cmp_autohash('update via alias',$avp,{name=>'Joe',hobby=>'go'});
my $hobby=$hash{hobby};                       # 'Joey'
is($hobby,'go','access via alias: hobby');
my($name,$hobby)=@hash{qw(name hobby)};
cmp_deeply([$name,$hobby],['Joe','go'],'access via alias: name,hobby');

################################################################################
# DESCRIPTION
################################################################################
#### Functions and methods
$avp=new Hash::AutoHash::AVPairsSingle name=>'Joe',hobby=>'chess';
cmp_autohash('new',$avp, {name=>'Joe',hobby=>'chess'});
$avp=new Hash::AutoHash::AVPairsSingle [name=>'Joe',hobby=>'chess'];
cmp_autohash('new ARRAY',$avp,{name=>'Joe',hobby=>'chess'});
$avp=new Hash::AutoHash::AVPairsSingle {name=>'Joe',hobby=>'chess'};
cmp_autohash('new HASH',$avp,{name=>'Joe',hobby=>'chess'});

## functions inherited from Hash::AutoHash

use Hash::AutoHash::AVPairsSingle
  qw(autohash_alias autohash_tied autohash_get autohash_set
     autohash_clear autohash_delete autohash_each autohash_exists 
     autohash_keys autohash_values 
     autohash_count autohash_empty autohash_notempty);
my $avp=new Hash::AutoHash::AVPairsSingle name=>'Joe',hobby=>'chess';
my(%hash,$tied,$result);
autohash_alias($avp,%hash);
cmp_autohash('create example for autohash_alias',$avp,
	   {name=>'Joe',hobby=>'chess'},'hash',undef,\%hash);

$tied=autohash_tied($avp);
cmp_autohash('autohash_tied form 1',$avp,
	   {name=>'Joe',hobby=>'chess'},'hash','object',\%hash,$tied);
$tied=autohash_tied(%hash);
cmp_autohash('autohash_tied form 2',$avp,
	   {name=>'Joe',hobby=>'chess'},'hash','object',\%hash,$tied);
$result=autohash_tied($avp,'FETCH','name');
cmp_deeply($result,'Joe','autohash_tied form 3');
$result=autohash_tied(%hash,'FETCH','name');
cmp_deeply($result,'Joe','autohash_tied form 4');

($name,$hobby)=autohash_get($avp,qw(name hobby));
cmp_deeply([$name,$hobby],['Joe','chess'],'autohash_get');

autohash_set($avp,name=>'Joe Plumber',first_name=>'Joe');
cmp_autohash('autohash_set',$avp,
	   {name=>'Joe Plumber',first_name=>'Joe',hobby=>'chess'});
my $avp=new Hash::AutoHash::AVPairsSingle name=>'Joe',hobby=>'chess';
autohash_set($avp,['name','first_name'],['Joe Plumber','Joe']);
cmp_autohash('autohash_set separate arrays form',$avp,
	   {name=>'Joe Plumber',first_name=>'Joe',hobby=>'chess'});

autohash_clear($avp);
cmp_autohash('autohash_clear',$avp,{});

my $avp=new Hash::AutoHash::AVPairsSingle name=>'Joe',first_name=>'Joe',hobby=>'chess';
my @keys=qw(name hobby);
autohash_delete($avp,@keys);
cmp_autohash('autohash_delete',$avp,{first_name=>'Joe'});

my $key='first_name';
if (autohash_exists($avp,$key)) {pass('autohash_exists')} else {fail('autohash_exists')}

my(@keys,@values);
my $avp=new Hash::AutoHash::AVPairsSingle name=>'Joe',hobby=>'chess';
while (my($key,$value)=autohash_each($avp)) { push(@keys,$key); push(@values,$value); }
cmp_set(\@keys,[qw(name hobby)],'autohash_each form 1 (keys)');
cmp_set(\@values,['Joe','chess'],'autohash_each form 1 (values)');
my(@keys,@values);
while (my $key=autohash_each($avp)) { push(@keys,$key); }
cmp_set(\@keys,[qw(name hobby)],'autohash_each form 2 (keys)');

my(@keys,@values);
@keys=autohash_keys($avp);
cmp_set(\@keys,[qw(name hobby)],'autohash_keys');
@values=autohash_values($avp);
cmp_set(\@values,['Joe','chess'],'autohash_values');

my $count;
$count=autohash_count($avp);
is($count,2,'autohash_count');

if (autohash_empty($avp)) {fail('autohash_empty')} else {pass('autohash_empty')}
if (autohash_notempty($avp)) {pass('autohash_empty')} else {fail('autohash_empty')}

done_testing();
