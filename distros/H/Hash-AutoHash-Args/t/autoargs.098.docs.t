use lib qw(t);
use Carp;
use Hash::AutoHash::Args;
use Test::More;
use Test::Deep;

use Hash::AutoHash::Args;
my @correct=('Joe',['hiking','cooking']);
my $args=new Hash::AutoHash::Args(name=>'Joe',
				    HOBBIES=>'hiking',hobbies=>'cooking');

# access argument values as HASH elements
my $name=$args->{name};
my $hobbies=$args->{hobbies};
cmp_deeply([$name,$hobbies],\@correct,'access argument values as HASH elements');

# access argument values via methods
my $name=$args->name;
my $hobbies=$args->hobbies;
cmp_deeply([$name,$hobbies],\@correct,'access argument values via method');

# set local variables from argument values -- two equivalent ways
use Hash::AutoHash::Args qw(autoargs_get);
my($name,$hobbies)=@$args{qw(name hobbies)};
cmp_deeply([$name,$hobbies],\@correct,'set local variables from argument values as HASH elements');
my($name,$hobbies)=autoargs_get($args,qw(name hobbies));
cmp_deeply([$name,$hobbies],\@correct,'set local variables from argument values via autoargs_get');

# alias $args to regular hash for more concise hash notation
use Hash::AutoHash::Args qw(autoargs_alias);
autoargs_alias($args,%args);
my($name,$hobbies)=@args{qw(name hobbies)};
cmp_deeply([$name,$hobbies],\@correct,'set local variables from alias');
$args{name}='Joseph';
is($args->name,'Joseph','set argument via alias');
$args->{name}='Joe';		# restore previous value. NOT in docs

# Arguments can be accessed using HASH or method notation; the following are equivalent.

my $name=$args->{name};
is($name,'Joe','access argument as HASH element');
my $name=$args->name;
is($name,'Joe','access argument using method');

# Arguments values can also be changed using either notation:

$args->{name}='Jonathan';
is($args->name,'Jonathan','change argument value as HASH element');
$args->{name}='Joe';		# restore previous value. NOT in docs
$args->name('Jonathan');
is($args->{name},'Jonathan','change argument value via method');
$args->{name}='Joe';		# restore previous value. NOT in docs

# Keywords are normalized automatically; the following are all equivalent.

my $name=$args->{name};		# lower case HASH key
is($name,'Joe','lower case HASH key');
my $name=$args->{Name};		# capitalized HASH key
is($name,'Joe','capitalized HASH key');
my $name=$args->{NAME};		# upper case HASH key
is($name,'Joe','upper case HASH key');
my $name=$args->{NaMe};		# mixed case HASH key
is($name,'Joe','mixed case HASH key');
my $name=$args->{-name};	# leading - in HASH key
is($name,'Joe','leading - in HASH key');
my $name=$args->name;		# lower case method
is($name,'Joe','lower case method');
my $name=$args->Name;		# capitalized method
is($name,'Joe','capitalized method');
my $name=$args->NAME;		# upper case method
is($name,'Joe','upper case method');
my $name=$args->NaMe;		# mixed case method
is($name,'Joe','mixed case method');

# CAUTION: methods must be syntactically legal
eval 'my $name=$args->-name';		# leading dash in method - ILLEGAL
ok($@=~/syntax error/,'leading dash in method - ILLEGAL');

# Repeated keyword arguments are converted into an ARRAY of the values.

my $correct=['hiking','cooking'];
my $args=new Hash::AutoHash::Args(hobbies=>'hiking', hobbies=>'cooking');
cmp_deeply($args->hobbies,$correct,'repeated keyword arguments converted into ARRAY');
my $args=new Hash::AutoHash::Args(hobbies=>['hiking', 'cooking']);
cmp_deeply($args->hobbies,$correct,'ARRAY keyword argument stays ARRAY');

# Repeated assignment does not retain multiple values
@$args{qw(hobbies hobbies)}=qw(running rowing);
is($args->hobbies,'rowing','repeated assignment to HASH element does not retain multiple values');
my $args=new Hash::AutoHash::Args(hobbies=>['hiking', 'cooking']); # restore previous value - NOT in docs
$args->hobbies('running');
$args->hobbies('rowing');
is($args->hobbies,'rowing','repeated assignment via method does not retain multiple values');

# New keywords can be added using either notation
$args->{first_name}='Joe';
is($args->first_name,'Joe','new keyword added as HASH element');
$args->last_name('Plumber');
is($args->{last_name},'Plumber','new keyword added via method');

# Non-existent keywords behave differently with method vs. hash notation
my @list=$args->non_existent;   # @list will contain 0 elements
is(scalar @list,0,'non_existent keyword via method');
my @list=$args->{non_existent}; # @list will contain 1 element
is(scalar @list,1,'non_existent keyword as HASH element');

# Constructors
my %correct=(name=>'Joe',hobbies=>['hiking','cooking']);
my $i;
my $args;
$args=new Hash::AutoHash::Args (name=>'Joe',HOBBIES=>'hiking',hobbies=>'cooking');
my %actual=%$args;
cmp_deeply(\%actual,\%correct,'constructor form '.++$i);
my $another_args_object=$args;
$args=new Hash::AutoHash::Args($another_args_object);
my %actual=%$args;
cmp_deeply(\%actual,\%correct,'constructor form '.++$i);
$args=new Hash::AutoHash::Args
  ([name=>'Joe',HOBBIES=>'hiking',hobbies=>'cooking']);
my %actual=%$args;
cmp_deeply(\%actual,\%correct,'constructor form '.++$i);
$args=new Hash::AutoHash::Args
  ({name=>'Joe',HOBBIES=>'hiking',hobbies=>'cooking'});
my %actual=%$args;
# NG 12-11-29: as of Perl 5.16 or so, the order of hash keys is randomized, and so
#              we cannot assume that 'hiking' comes before 'cooking'
# cmp_deeply(\%actual,\%correct,'constructor form '.++$i);
my $label='constructor form '.++$i;
my $ok=1;
unless (eq_deeply([keys %actual],set(keys %correct))) {
  $ok=0;
  fail("$label wrong keys");
  diag('expected: ',join(', ',keys %correct),"\n",
       '     got: '.join(', ',keys %actual));
}
if (exists $actual{name} && $actual{name} ne $correct{name}) {
  $ok=0;
  fail("$label wrong name value");
  diag("expected: $correct{name}\n",
       "     got: $actual{name}");
}
if (exists $actual{hobbies} && !eq_deeply($actual{hobbies},set(@{$correct{hobbies}}))) {
  $ok=0;
  fail("$label wrong hobbies value");
  diag('expected: ',join(', ',@{$correct{hobbies}}),"\n",
       '     got: ',join(', ',@{$actual{hobbies}}));
}
pass($label) if $ok;
 
# Getting and setting argument values

my @correct=('Joe',['hiking','cooking']);
my $args=new Hash::AutoHash::Args(name=>'Joe',
				  HOBBIES=>'hiking',hobbies=>'cooking');
my $name=$args->{name};
is($name,'Joe','access argument as HASH element');
my($name,$hobbies)=@$args{qw(name hobbies)};
cmp_deeply([$name,$hobbies],['Joe',['hiking','cooking']],'access argument values as HASH elements');
$args->{name}='Jonathan';
is($args->name,'Jonathan','change argument value as HASH element');
@$args{qw(name hobbies)}=('Joseph',['running','rowing']);
my($name,$hobbies)=@$args{qw(name hobbies)};
cmp_deeply([$name,$hobbies],['Joseph',['running','rowing']],'change argument values as HASH elements');

my $args=new Hash::AutoHash::Args(name=>'Joe',
				  HOBBIES=>'hiking',hobbies=>'cooking');
my $name=$args->name;
is($name,'Joe','access argument via method');
$args->name('Joseph');                # sets name to 'Joseph'
is($args->{name},'Joseph','change argument value via method');
$args->hobbies('running','rowing');   # sets hobbies to ['running','rowing']
cmp_deeply($args->{hobbies},['running','rowing'],'change argument values via method');

# New keywords can be added using either notation
$args->{first_name}='Joe';
is($args->first_name,'Joe','new keyword added as HASH element');
$args->last_name('Plumber');
is($args->{last_name},'Plumber','new keyword added via method');

# Caveats

# CAUTION: methods must be syntactically legal
eval 'my $name=$args->-name';		# leading dash in method - ILLEGAL
ok($@=~/syntax error/,'leading dash in method - ILLEGAL');

# Setting individual keywords does not preserve multiple values

my $args=new Hash::AutoHash::Args(hobbies=>'hiking',hobbies=>'cooking');
cmp_deeply($args->hobbies,['hiking','cooking'],'repeated keywords converted to ARRAY');
@$args{qw(hobbies hobbies)}=qw(running rowing);
is($args->hobbies,'rowing','repeated assignment to HASH element does not retain multiple values');
my $args=new Hash::AutoHash::Args(hobbies=>'hiking',hobbies=>'cooking');
$args->hobbies('running');
$args->hobbies('rowing');
is($args->hobbies,'rowing','repeated assignment via method does not retain multiple values');

# Functions to get and set keywords

use Hash::AutoHash::Args
    qw(get_args getall_args set_args autoargs_get autoargs_set);
my $args=new Hash::AutoHash::Args(name=>'Joe',HOBBIES=>['hiking','cooking']);

my($name,$hobbies)=get_args($args,qw(-name hobbies));
cmp_deeply([$name,$hobbies],['Joe',['hiking','cooking']],'get_args');
my($name,$hobbies)=autoargs_get($args,qw(name -hobbies));
cmp_deeply([$name,$hobbies],['Joe',['hiking','cooking']],'get_args');
my %args=getall_args($args);
cmp_deeply(\%args,{name=>'Joe',hobbies=>['hiking','cooking']},'getall_args');
set_args($args,name=>'Joe the Plumber',-first_name=>'Joe',-last_name=>'Plumber');
my($name,$first_name,$last_name)=@$args{qw(name first_name last_name)};
cmp_deeply([$name,$first_name,$last_name],['Joe the Plumber','Joe','Plumber'],'set_args: keyword=>value form');

my $args=new Hash::AutoHash::Args(name=>'Joe',HOBBIES=>['hiking','cooking']);
set_args($args,['name','-first_name','-last_name'],['Joe the Plumber','Joe','Plumber']);
my($name,$first_name,$last_name)=@$args{qw(name first_name last_name)};
cmp_deeply([$name,$first_name,$last_name],['Joe the Plumber','Joe','Plumber'],'set_args: separate ARRAYs form');

my $args=new Hash::AutoHash::Args(name=>'Joe',HOBBIES=>['hiking','cooking']);
autoargs_set($args,name=>'Joe the Plumber',-first_name=>'Joe',-last_name=>'Plumber');
my($name,$first_name,$last_name)=@$args{qw(name first_name last_name)};
cmp_deeply([$name,$first_name,$last_name],['Joe the Plumber','Joe','Plumber'],'autoargs_set: keyword=>value form');
my $args=new Hash::AutoHash::Args(name=>'Joe',HOBBIES=>['hiking','cooking']);
autoargs_set($args,['name','-first_name','-last_name'],['Joe the Plumber','Joe','Plumber']);
my($name,$first_name,$last_name)=@$args{qw(name first_name last_name)};
cmp_deeply([$name,$first_name,$last_name],['Joe the Plumber','Joe','Plumber'],'autoargs_set: separate ARRAYs form');

# Functions to normalize keywords
use Hash::AutoHash::Args qw(fix_args fix_keyword fix_keywords);
my $hash=fix_args(-name=>'Joe',HOBBIES=>'hiking',hobbies=>'cooking');
cmp_deeply($hash,{name=>'Joe',hobbies=>['hiking','cooking']},'fix_args');
my $keyword=fix_keyword('-NaMe');
is($keyword,'name','fix_keyword scalar context');
my @keywords=fix_keyword('-NaMe','---hobbies');;
cmp_deeply(\@keywords,['name','hobbies'],'fix_keyword array context');
my $keyword=fix_keywords('-NaMe');
is($keyword,'name','fix_keywords scalar context');
cmp_deeply(\@keywords,['name','hobbies'],'fix_keywords array context');

# Functions to check format of argument list
use Hash::AutoHash::Args qw(is_keyword is_positional);
my $args;
my @args=(-name=>'Joe',-hobbies=>['hiking','cooking']);
if (is_keyword(@args)) {
  $args=new Hash::AutoHash::Args (@args);
  pass('is_keyword');
} else {
  fail('is_keyword');
}

my($arg1,$arg2,$arg3);
my @args=('Joe',['hiking','cooking']);
if (is_positional(@args)) {
  ($arg1,$arg2,$arg3)=@args; 
  pass('is_positional');
} else {
  fail('is_positional');
}

# Functions for hash-like operations
use Hash::AutoHash::Args qw(autoargs_clear autoargs_delete autoargs_each autoargs_exists 
			      autoargs_keys autoargs_values 
			      autoargs_count autoargs_empty autoargs_notempty);
my $args=new Hash::AutoHash::Args(name=>'Joe',HOBBIES=>['hiking','cooking']);
# autoargs_clear
autoargs_clear($args);
ok(!%$args,'autoargs_clear');

# autoargs_delete
my $args=new Hash::AutoHash::Args(name=>'Joe',HOBBIES=>['hiking','cooking']);
my @keywords=qw(sex hobbies);
autoargs_delete($args,@keywords);
my %correct=(name=>'Joe');
my %actual=%$args;
cmp_deeply(\%actual,\%correct,'autoargs_delete');

# autoargs_exists
my $keyword='name';
ok(autoargs_exists($args,$keyword),'autoargs_exists');

# autoargs_each
my $args=new Hash::AutoHash::Args(name=>'Joe',HOBBIES=>['hiking','cooking']);
my %correct=(name=>'Joe',hobbies=>['hiking','cooking']);
my @correct=keys %correct;
my(%actual,@actual);
while (my($keyword,$value)=autoargs_each($args)) { 
  $actual{$keyword}=$value;
}
cmp_deeply(\%actual,\%correct,'autoargs_each array context');
while (my $keyword=autoargs_each($args)) { 
  push(@actual,$keyword);
}
# cmp_deeply(\@actual,\@correct,'autoargs_each scalar context');
cmp_set(\@actual,\@correct,'autoargs_each scalar context');

# autoargs_keys
my @keys=autoargs_keys($args);
my @correct=keys %correct;
# cmp_deeply(\@keys,\@correct,'autoargs_keys');
cmp_set(\@keys,\@correct,'autoargs_keys');

# autoargs_values
my @values=autoargs_values($args);
my @correct=values %correct;
# cmp_deeply(\@values,\@correct,'autoargs_velues');
cmp_set(\@values,\@correct,'autoargs_velues');

# autoargs_count
my $count=autoargs_count($args);
is($count,2,'autoargs_count');

# autoargs_empty
ok(!autoargs_empty($args),'autoargs_exists');

# autoargs_notempty
ok(autoargs_notempty($args),'autoargs_exists');

# Object vs. class methods
my $can=can Hash::AutoHash::Args('import');
is(ref $can,'CODE','can as class method');
my $can=Hash::AutoHash::Args->can('import');
is(ref $can,'CODE','can as class method');
# is($args->can('import'),'import','can as object method');

ok(new Hash::AutoHash::Args(name=>'Joe'),'new as class method');
ok(!$args->new,'new as object method');

done_testing();
