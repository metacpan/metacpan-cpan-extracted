use lib qw(t);
use Carp;
use Hash::AutoHash::Record;
use Test::More;
use Test::Deep;
use recordUtil;

################################################################################
# SYNOPSIS
################################################################################

use Hash::AutoHash::Record qw(autohash_set);

# create object and define field-types
#   name- single-valued, hobbies- multi-valued,
#   favorites- attribute-(single-)value pairs, 
#   family- attribute-(multi-)value pairs
# note: when used as initial value, 
#   {}  means empty attribute-(single-)value pairs
#   \{} means empty attribute-(multi-)value pairs

my $record=
  new Hash::AutoHash::Record name=>'',hobbies=>[],favorites=>{},family=>\{};
cmp_record('create object and set intial values',$record,
	   {name=>'',hobbies=>[],favorites=>new_SV,family=>new_MV});

# set fields
autohash_set($record,
	     name=>'Joe',hobbies=>['chess','cooking'],
	     favorites=>{color=>'purple',food=>'pie'},
	     family=>{wife=>'Mary',sons=>['Tom','Dick']});
cmp_record('set fields',$record,
	   {name=>'Joe',hobbies=>[qw(chess cooking)],
	    favorites=>new_SV(color=>'purple',food=>'pie'),
	    family=>new_MV(wife=>'Mary',sons=>'Tom',sons=>'Dick')});

# update fields one-by-one
$record->name('Joey');		      # change name to 'Joey'
$record->hobbies('go');		      # add 'go' to hobbies
$record->favorites(color=>'red');     # change favorite color to 'red'
$record->family(daughters=>'Jane');   # add daughter 'Jane' to family
cmp_record('update fields one-by-one',$record,
	   {name=>'Joey',hobbies=>[qw(chess cooking go)],
	    favorites=>new_SV(color=>'red',food=>'pie'),
	    family=>new_MV(wife=>'Mary',sons=>['Tom','Dick'],daughters=>'Jane')});

# access fields one-by-one
my $name=$record->name;		    # 'Joey'
is($name,'Joey','access fields one-by-one: single-valued');
my $hobbies=$record->hobbies;	    # ['chess','cooking','go']
cmp_deeply($hobbies,[qw(chess cooking go)],
	   'access fields one-by-one: multi-valued. scalar context');
my @hobbies=$record->hobbies;	    # ('chess','cooking','go')
cmp_deeply(\@hobbies,[qw(chess cooking go)],
	   'access fields one-by-one: multi-valued. array context');
my $favorites=$record->favorites;   # Hash::AutoHash in scalar context
cmp_deeply($favorites,new_SV(color=>'red',food=>'pie'),
	   'access fields one-by-one: attribute-(single-)-valued. scalar context');
my %favorites=$record->favorites;   # regular hash in array context
cmp_deeply(\%favorites,{color=>'red',food=>'pie'},
	   'access fields one-by-one: attribute-(single-)-valued. array context');
my $family=$record->family;	    # Hash::AutoHash::MultiValued
cmp_deeply($family,new_MV(wife=>'Mary',sons=>['Tom','Dick'],daughters=>'Jane'),
	   'access fields one-by-one: attribute-(multi-)valued. scalar context');
my %family=$record->family;	    # regular hash
cmp_deeply(\%family,{wife=>['Mary'],sons=>['Tom','Dick'],daughters=>['Jane']},
	   'access fields one-by-one: attribute-(multi-)valued. array context');

# you can also use standard hash notation and functions
$record->{name}='Joseph';	# set name to 'Joseph'
$record->{hobbies}='rowing';	# add 'rowing' to hobbies
$record->{favorites}={holiday=>'Christmas'}; # add favorite holiday
$record->{family}={daughters=>'Sue'}; # add 2nd daughter 'Sue' to family
cmp_record('update fields one-by-one using standard hash notation',$record,
	   {name=>'Joseph',hobbies=>[qw(chess cooking go rowing)],
	    favorites=>new_SV(color=>'red',food=>'pie',holiday=>'Christmas'),
	    family=>new_MV(wife=>'Mary',sons=>['Tom','Dick'],daughters=>['Jane','Sue'])});

# CAUTION: hash notation doesn't respect array context!
$record->{hobbies}=('hiking','baking');	# adds last value only
cmp_record('update fields: hash notation does not respect array context',$record,
	   {name=>'Joseph',hobbies=>[qw(chess cooking go rowing baking)],
	    favorites=>new_SV(color=>'red',food=>'pie',holiday=>'Christmas'),
	    family=>new_MV(wife=>'Mary',sons=>['Tom','Dick'],daughters=>['Jane','Sue'])});
my @hobbies=$record->{hobbies};	      # list of ARRAY (['chess',...])
cmp_deeply(\@hobbies,[['chess','cooking','go','rowing','baking']],
	   'access fields: hash notation does not respect array context');

my @keys=keys %$record;		      # list of all 4 keys
cmp_bag(\@keys,[qw(name hobbies favorites family)],'keys');
my @values=values %$record;	      # list of all 4 values
cmp_bag(\@values,['Joseph',[qw(chess cooking go rowing baking)],
		  new_SV(color=>'red',food=>'pie',holiday=>'Christmas'),
		  new_MV(wife=>'Mary',sons=>['Tom','Dick'],daughters=>['Jane','Sue'])],'values');
delete $record->{hobbies};	      # no more hobbies
cmp_record('delete hobbies',$record,
	   {name=>'Joseph',
	    favorites=>new_SV(color=>'red',food=>'pie',holiday=>'Christmas'),
	    family=>new_MV(wife=>'Mary',sons=>['Tom','Dick'],daughters=>['Jane','Sue'])});

# clearing object restores initial values and preserves field-types
%$record=();                             
cmp_record('clearing object restores initial values',$record,
	   {name=>'',hobbies=>[],favorites=>new_SV,family=>new_MV});

# alias $record to regular hash for more concise hash notation
use Hash::AutoHash::Record qw(autohash_alias);
my %hash;
autohash_alias($record,%hash);
cmp_record('autohash_alias',$record,
	   {name=>'',hobbies=>[],favorites=>new_SV,family=>new_MV},
	   \%hash);

# access or change hash elements without using ->
$hash{name}='Joe';		      # set name to 'Joe'
@hash{qw(hobbies favorites family)}=   # set remaining fields
  (['chess','cooking'],
   {color=>'purple',food=>'pie'},
   {wife=>'Mary',sons=>['Tom','Dick']});
cmp_record('update via alias',$record,
	   {name=>'Joe',hobbies=>['chess','cooking'],
	    favorites=>new_SV(color=>'purple',food=>'pie'),
	    family=>new_MV(wife=>'Mary',sons=>['Tom','Dick'])},
	   \%hash);

my $name=$hash{name};	   # get 1 field
is($name,'Joe','access 1 field via alias');
my($hobbies,$favorites,$family)=   # get remaining fields
  @hash{qw(hobbies favorites family)};
cmp_deeply([$hobbies,$favorites,$family],
	   [['chess','cooking'],
	    new_SV(color=>'purple',food=>'pie'),
	    new_MV(wife=>'Mary',sons=>['Tom','Dick'])],'access remaining fields via alias');

# set 'unique' in tied object to eliminate duplicates in multi-valued fields
use Hash::AutoHash::Record qw(autohash_tied);
autohash_tied($record)->unique(1);
$record->hobbies('chess','skiing'); # duplicate 'chess' not added
cmp_record('update after setting unique',$record,
	   {name=>'Joe',hobbies=>['chess','cooking','skiing'],
	    favorites=>new_SV(color=>'purple',food=>'pie'),
	    family=>new_MV(wife=>'Mary',sons=>['Tom','Dick'])},
	   \%hash);

# field can also be any Hash::AutoHash object, including Record (!!)
my $address=new Hash::AutoHash::Record lines=>[],city=>'',state=>'',zip=>'';
cmp_record('create address',$address,{lines=>[],city=>'',state=>'',zip=>''});
$record->address($address);	# add empty address to record
cmp_record('add address to record',$record,
	   {name=>'Joe',hobbies=>['chess','cooking','skiing'],
	    favorites=>new_SV(color=>'purple',food=>'pie'),
	    family=>new_MV(wife=>'Mary',sons=>['Tom','Dick']),address=>$address},
	   \%hash);
# set fields of nested record
$record->address(lines=>['Suite 123','456 Main St'],city=>'Anytown',
		 state=>'WA',zip=>98765);
cmp_record('set fields of nested record via address',$address,
	   {lines=>['Suite 123','456 Main St'],city=>'Anytown',state=>'WA',zip=>98765});
cmp_record('check record after setting fields of nested record',$record,
	   {name=>'Joe',hobbies=>['chess','cooking','skiing'],
	    favorites=>new_SV(color=>'purple',food=>'pie'),
	    family=>new_MV(wife=>'Mary',sons=>'Tom',sons=>'Dick'),address=>$address},
	   \%hash);
my $state=$record->address->state; # get field from nested record
is($state,'WA','get field from nested record');

################################################################################
# DESCRIPTION
################################################################################
#### Capabilities inherited from Hash::AutoHash
use Hash::AutoHash::Record qw(autohash_keys autohash_delete);
my $record=new Hash::AutoHash::Record name=>'',hobbies=>[];
cmp_record('hash functions inherited from Hash::AutoHash: create object',$record,
	   {name=>'',hobbies=>[]});
my @keys=autohash_keys($record);
cmp_bag(\@keys,[qw(name hobbies)],'autohash_keys');
for my $key (@keys) {
  my $value=$record->$key;
  autohash_delete($record,$key) if 'ARRAY' eq ref $value && !@$value;
}
cmp_record('autohash_delete',$record,{name=>''});

#### Initial values
my $record=new Hash::AutoHash::Record
  avp_single=>{attr1=>'value1'},avp_multi=>{attr2=>['value21','value22']},
  hash=>{key3=>{key31=>'value31'}};
cmp_record('initial unblessed HASH',$record,
	   {avp_single=>new_SV(attr1=>'value1'),avp_multi=>new_MV(attr2=>['value21','value22']),
	    hash=>{key3=>{key31=>'value31'}}});
my $record=new Hash::AutoHash::Record hash=>bless {};
cmp_record('initial value workaround hash',$record,{hash=>bless {}});

my $record=new Hash::AutoHash::Record
  avp_multi1=>\{attr1=>'value1'},avp_multi2=>{attr2=>['value21','value22']},
hash=>{key3=>{key31=>'value31'}};
cmp_record('initial unblessed reference to unblessed HASH',$record,
	   {avp_multi1=>new_MV(attr1=>'value1'),avp_multi2=>new_MV(attr2=>['value21','value22']),
	    hash=>{key3=>{key31=>'value31'}}});
my $record=new Hash::AutoHash::Record ref_to_hash=>\bless {};
cmp_record('initial value workaround ref hash',$record,{ref_to_hash=>\bless {}});

#### Field-update semantics
## Single-valued
$record=new Hash::AutoHash::Record single=>'value1';
$record->single('value2');                  # sets field to 'value2'
cmp_record('update semantics: scalar',$record,{single=>'value2'});
eval {$record->single('value3','value4')};  # illegal. multiple new values
ok($@=~/Trying to store multiple values in single-valued/,'ILLEGAL. scalar: multiple new values');

## Multi-valued
$record=new Hash::AutoHash::Record multi=>['value1'];
$record->multi('value2');                  # appends 'value2' to old value
$record->multi('value3','value4');         # appends 'value3','value4'
$record->multi(['value4','value5']);       # appends 'value4','value5'
eval {$record->multi({key6=>'value6'})};   # illegal - reference  
ok($@=~/Trying to store reference in multi-valued/,'ILLEGAL. multi-valued: storing reference');
cmp_record('update semantics: multi-valued',$record,
	   {multi=>[qw(value1 value2 value3 value4 value4 value5)]});

## Collection of attribute-(single-)value pairs
$record=new Hash::AutoHash::Record avp_single=>{attr1=>'value1'};
$record->avp_single(attr1=>'new_value1'); # sets attr1 to 'new_value1'
$record->avp_single(attr2=>'value2');	  # adds attr2=>'value2'
$record->avp_single([attr3=>'value3']);	  # adds attr3=>'value3'
$record->avp_single({attr4=>'value4'});	  # adds attr4=>'value4'
eval {$record->avp_single(attr5=>['value5'])}; # illegal - value is reference
ok($@=~/Trying to store reference/,'ILLEGAL. atribute-single-value: storing reference');
  $record->avp_single('attr6');              # ignored. no value
  cmp_record('update semantics: avp-single-valued',$record,
	     {avp_single=>
	      new_SV(attr1=>'new_value1',attr2=>'value2',attr3=>'value3',attr4=>'value4')});

## Collection of attribute-(multi-)value pairs
$record=new Hash::AutoHash::Record avp_multi=>\{attr1=>'value1'};
$record->avp_multi(attr1=>'new_value1');   # appends 'new_value1' to attr1
$record->avp_multi(attr2=>'value2');	   # adds attr2=>'value2'
$record->avp_multi([attr2=>'new_value2']); # appends 'new_value2 to attr2
$record->avp_multi({attr3=>'value3'});	   # adds attr3=>'value3'
$record->avp_multi(attr3=>['new_value3']); # appends new_value3 to attr3
eval {$record->avp_multi(attr4=>{key=>value})};   # illegal - value is reference
ok($@=~/Trying to store reference/,'ILLEGAL. atribute-multi-value: storing reference');
  $record->avp_multi('attr5');               # ignored. no value
  cmp_record('update semantics: avp-multi-valued',$record,
	     {avp_multi=>
	      new_MV(attr1=>['value1','new_value1'],
		     attr2=>['value2','new_value2'],
		     attr3=>['value3','new_value3'])});

##  Hash::AutoHash object
$autohash=new Hash::AutoHash key1=>'value1';
$record=new Hash::AutoHash::Record autohash=>$autohash;
$record->autohash(key1=>'new_value1');     # runs $autohash->key1('new_value1')
$record->autohash(key2=>'value2');         # runs $autohash->key2('value2')
$record->autohash('key3');	           # ignored. no value
cmp_record('update semantics: autohash',$record,
	   {autohash=>new Hash::AutoHash(key1=>'new_value1',key2=>'value2')});

#### Duplicate elimination and filtering (multi-valued fields only!!)
use Hash::AutoHash::Record qw(autohash_tied);
my $record=new Hash::AutoHash::Record hobbies=>['chess','chess'];
autohash_tied($record)->unique(1);        # hobbies now ['chess']
$record->hobbies('chess');                # duplicate 'chess' not added
cmp_record('unique',$record,{hobbies=>['chess']});
$record->hobbies('go');                   # hobbies now ['chess','go']
%$record=();                              # hobbies now ['chess']
cmp_record('unique clear',$record,{hobbies=>['chess']});

sub uniq_nocase_sort {
  my %uniq;
  my @values_lc=map { lc($_) } @_;
  @uniq{@values_lc}=@_;
  sort values %uniq;  
}

my $record=new Hash::AutoHash::Record hobbies=>['CHESS','chess','go'];
autohash_tied($record)->filter(\&uniq_nocase_sort);
cmp_record('filter function',$record,{hobbies=>['chess','go']});

my $record=new Hash::AutoHash::Record hobbies=>['CHESS','chess','go'];
autohash_tied($record)->filter(sub {my %u; @u{map {lc $_} @_}=@_; sort values %u});
cmp_record('filter cryptic one-liner',$record,{hobbies=>['chess','go']});

#### Functions and methods
## new
my $record=new Hash::AutoHash::Record name=>'',hobbies=>[],favorites=>{},family=>\{};
cmp_record('new',$record,{name=>'',hobbies=>[],favorites=>new_SV,family=>new_MV});

## defaults
my $i=1;
my $record=new Hash::AutoHash::Record name=>'',hobbies=>[],favorites=>{},family=>\{};
%defaults=tied(%$record)->defaults;
cmp_deeply(\%defaults,{name=>'',hobbies=>[],favorites=>new_SV,family=>new_MV},
	   "defaults form ".$i++);

$defaults=tied(%$record)->defaults;
cmp_deeply($defaults,{name=>'',hobbies=>[],favorites=>new_SV,family=>new_MV},
	   "defaults form ".$i++);

my $record=new Hash::AutoHash::Record name=>'',hobbies=>[],favorites=>{},family=>\{};
tied(%$record)->defaults(name=>'Joe',hobbies=>['chess']);
$defaults=tied(%$record)->defaults;
cmp_deeply($defaults,{name=>'Joe',hobbies=>['chess']},"defaults form ".$i++);

my $record=new Hash::AutoHash::Record name=>'',hobbies=>[],favorites=>{},family=>\{};
tied(%$record)->defaults([name=>'Joe',hobbies=>['chess']]);
$defaults=tied(%$record)->defaults;
cmp_deeply($defaults,{name=>'Joe',hobbies=>['chess']},"defaults form ".$i++);

my $record=new Hash::AutoHash::Record name=>'',hobbies=>[],favorites=>{},family=>\{};
tied(%$record)->defaults({name=>'Joe',hobbies=>['chess']});
$defaults=tied(%$record)->defaults;
cmp_deeply($defaults,{name=>'Joe',hobbies=>['chess']},"defaults form ".$i++);

my $record=new Hash::AutoHash::Record name=>'',hobbies=>[],favorites=>{},family=>\{};
%defaults=autohash_tied($record)->defaults;
cmp_deeply(\%defaults,{name=>'',hobbies=>[],favorites=>new_SV,family=>new_MV},
	   "defaults form ".$i++);

my $record=new Hash::AutoHash::Record name=>'',hobbies=>[],favorites=>{},family=>\{};
$defaults=autohash_tied($record)->defaults;
cmp_deeply($defaults,{name=>'',hobbies=>[],favorites=>new_SV,family=>new_MV},
	   "defaults form ".$i++);

my $record=new Hash::AutoHash::Record name=>'',hobbies=>[],favorites=>{},family=>\{};
autohash_tied($record)->defaults(name=>'Joe',hobbies=>['chess']);
$defaults=autohash_tied($record)->defaults;
cmp_deeply($defaults,{name=>'Joe',hobbies=>['chess']},"defaults form ".$i++);

my $record=new Hash::AutoHash::Record name=>'',hobbies=>[],favorites=>{},family=>\{};
autohash_tied($record)->defaults([name=>'Joe',hobbies=>['chess']]);
$defaults=autohash_tied($record)->defaults;
cmp_deeply($defaults,{name=>'Joe',hobbies=>['chess']},"defaults form ".$i++);

my $record=new Hash::AutoHash::Record name=>'',hobbies=>[],favorites=>{},family=>\{};
autohash_tied($record)->defaults({name=>'Joe',hobbies=>['chess']});
$defaults=autohash_tied($record)->defaults;
cmp_deeply($defaults,{name=>'Joe',hobbies=>['chess']},"defaults form ".$i++);

## force
my $i=1;
my $record=new Hash::AutoHash::Record name=>'',hobbies=>[],favorites=>{},family=>\{};
my $force=tied(%$record)->force('favorites',{colors=>['red','blue']});
cmp_record("force form $i",$record,
	   {name=>'',hobbies=>[],favorites=>new_MV(colors=>['red','blue']),family=>new_MV});
cmp_deeply($force,new_MV(colors=>['red','blue']),'force form '.$i++.' return value');
my $force=tied(%$record)->force('favorites');
cmp_record("force form $i",$record,{name=>'',hobbies=>[],favorites=>undef,family=>new_MV});
is($force,undef,'force form '.$i++.' return value');
my $force=autohash_tied($record)->force('favorites',{colors=>['red','blue']});
cmp_record("force form $i",$record,
	   {name=>'',hobbies=>[],favorites=>new_MV(colors=>['red','blue']),family=>new_MV});
cmp_deeply($force,new_MV(colors=>['red','blue']),'force form '.$i++.' return value');
my $force=autohash_tied($record)->force('favorites');
cmp_record("force form $i",$record,{name=>'',hobbies=>[],favorites=>undef,family=>new_MV});
is($force,undef,'force form '.$i++.' return value');

## unique
my $boolean=1;
sub function1 {lc($_[0]) eq lc($_[1])}

my $record=new Hash::AutoHash::Record hobbies=>['go','go'];
my $unique=tied(%$record)->unique;
cmp_record('unique form 1',$record,{hobbies=>[qw(go go)]});
ok(!$unique,'value returned by unique form 1');

my $record=new Hash::AutoHash::Record hobbies=>['go','go'];
tied(%$record)->unique($boolean);
cmp_record('unique form 2',$record,{hobbies=>[qw(go)]});

my $record=new Hash::AutoHash::Record hobbies=>['chess','GO','go'];
tied(%$record)->unique(\&function1);
cmp_record('unique form 3',$record,{hobbies=>[qw(chess GO)]});

my $record=new Hash::AutoHash::Record hobbies=>['go','go'];
my $unique=autohash_tied($record)->unique;
cmp_record('unique form 4',$record,{hobbies=>[qw(go go)]});
ok(!$unique,'value returned by unique form 4');

my $record=new Hash::AutoHash::Record hobbies=>['go','go'];
autohash_tied($record)->unique($boolean);
cmp_record('unique form 5',$record,{hobbies=>[qw(go)]});

my $record=new Hash::AutoHash::Record hobbies=>['chess','GO','go'];
autohash_tied($record)->unique(\&function1);
cmp_record('unique form 6',$record,{hobbies=>[qw(chess GO)]});

## filter
my $boolean=1;
sub function2 {my %u; @_=map {lc $_} @_; @u{@_}=@_; values %u}

my $record=new Hash::AutoHash::Record hobbies=>['go','go'];
my $filter=tied(%$record)->filter;
cmp_record('filter form 1',$record,{hobbies=>[qw(go go)]});
ok(!$filter,'value returned by filter form 1');

my $record=new Hash::AutoHash::Record hobbies=>['go','go'];
tied(%$record)->filter($boolean);
cmp_record('filter form 2',$record,{hobbies=>[qw(go)]});

my $record=new Hash::AutoHash::Record hobbies=>['GO','go'];
tied(%$record)->filter(\&function2);
cmp_record('filter form 3',$record,{hobbies=>[qw(go)]});

my $record=new Hash::AutoHash::Record hobbies=>['go','go'];
my $filter=autohash_tied($record)->filter;
cmp_record('filter form 4',$record,{hobbies=>[qw(go go)]});
ok(!$filter,'value returned by filter form 4');

my $record=new Hash::AutoHash::Record hobbies=>['go','go'];
autohash_tied($record)->filter($boolean);
cmp_record('filter form 5',$record,{hobbies=>[qw(go)]});

my $record=new Hash::AutoHash::Record hobbies=>['GO','go'];
autohash_tied($record)->filter(\&function2);
cmp_record('filter form 6',$record,{hobbies=>[qw(go)]});

## functions inherited from Hash::AutoHash
use Hash::AutoHash::Record
  qw(autohash_alias autohash_tied autohash_get autohash_set
     autohash_clear autohash_delete autohash_each autohash_exists 
     autohash_keys autohash_values 
     autohash_count autohash_empty autohash_notempty);
my $record=new Hash::AutoHash::Record name=>'Joe',hobbies=>['chess','cooking'];
my(%hash,$tied,$result);
autohash_alias($record,%hash);
cmp_record('create example for autohash_alias',$record,
	   {name=>'Joe',hobbies=>[qw(chess cooking)]},\%hash);

$tied=autohash_tied($record);
cmp_record('autohash_tied form 1',$record,
	   {name=>'Joe',hobbies=>[qw(chess cooking)]},\%hash,$tied);
$tied=autohash_tied(%hash);
cmp_record('autohash_tied form 2',$record,
	   {name=>'Joe',hobbies=>[qw(chess cooking)]},\%hash,$tied);
$result=autohash_tied($record,'FETCH','name');
cmp_deeply($result,'Joe','autohash_tied form 3');
$result=autohash_tied(%hash,'FETCH','name');
cmp_deeply($result,'Joe','autohash_tied form 4');

($name,$hobbies)=autohash_get($record,qw(name hobbies));
cmp_deeply([$name,$hobbies],['Joe',[qw(chess cooking)]],'autohash_get');

autohash_set($record,name=>'Plumber',first_name=>'Joe');
cmp_record('autohash_set',$record,
	   {name=>'Plumber',first_name=>'Joe',hobbies=>[qw(chess cooking)]});

autohash_clear($record);
cmp_record('autohash_clear',$record,
	   {name=>'Joe',hobbies=>[qw(chess cooking)]},\%hash);
### TBD clear @keys

my $record=new Hash::AutoHash::Record name=>'Joe',first_name=>'Joe',hobbies=>[qw(chess cooking)];
cmp_record('create example again',$record,
	   {name=>'Joe',first_name=>'Joe',hobbies=>[qw(chess cooking)]});
my @keys=qw(name hobbies);
autohash_delete($record,@keys);
cmp_record('autohash_delete',$record,{first_name=>'Joe'});

my $key='first_name';
if (autohash_exists($record,$key)) {pass('autohash_exists')} else {fail('autohash_exists')}

my(@keys,@values);
my $record=new Hash::AutoHash::Record name=>'Joe',hobbies=>[qw(chess cooking)];
cmp_record('create example again',$record,{name=>'Joe',hobbies=>[qw(chess cooking)]});
while (my($key,$value)=autohash_each($record)) { push(@keys,$key); push(@values,$value); }
# cmp_deeply(\@keys,[qw(name hobbies)],'autohash_each form 1 (keys)');
# cmp_deeply(\@values,['Joe',[qw(chess cooking)]],'autohash_each form 1 (values)');
cmp_set(\@keys,[qw(name hobbies)],'autohash_each form 1 (keys)');
cmp_set(\@values,['Joe',[qw(chess cooking)]],'autohash_each form 1 (values)');
my(@keys,@values);
while (my $key=autohash_each($record)) { push(@keys,$key); }
# cmp_deeply(\@keys,[qw(name hobbies)],'autohash_each form 2 (keys)');
cmp_set(\@keys,[qw(name hobbies)],'autohash_each form 2 (keys)');

my(@keys,@values);
@keys=autohash_keys($record);
# cmp_deeply(\@keys,[qw(name hobbies)],'autohash_keys');
cmp_set(\@keys,[qw(name hobbies)],'autohash_keys');
@values=autohash_values($record);
# cmp_deeply(\@values,['Joe',[qw(chess cooking)]],'autohash_values');
cmp_set(\@values,['Joe',[qw(chess cooking)]],'autohash_values');

my $count;
$count=autohash_count($record);
is($count,2,'autohash_count');

if (autohash_empty($record)) {fail('autohash_empty')} else {pass('autohash_empty')}
if (autohash_notempty($record)) {pass('autohash_empty')} else {fail('autohash_empty')}

done_testing();
