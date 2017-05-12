use lib qw(t);
use Carp;
use Hash::AutoHash::Args::V0;
use Test::More;
use Test::Deep;

########################################
# SYNOPSIS
use Hash::AutoHash::Args::V0;
my @correct=('Joe',['hiking','cooking']);
my $args=new Hash::AutoHash::Args::V0(name=>'Joe',
				    HOBBIES=>'hiking',hobbies=>'cooking');

# access argument values as HASH elements
my $name=$args->{name};
my $hobbies=$args->{hobbies};
cmp_deeply([$name,$hobbies],\@correct,'access argument values as HASH elements');

# access argument values via methods
my $name=$args->name;
my $hobbies=$args->hobbies;
cmp_deeply([$name,$hobbies],\@correct,'access argument values via method');

# set local variables from argument values -- three equivalent ways
use Hash::AutoHash::Args qw(autoargs_get);
my($name,$hobbies)=@$args{qw(name hobbies)};
cmp_deeply([$name,$hobbies],\@correct,'set local variables from argument values as HASH elements');
my($name,$hobbies)=autoargs_get($args,qw(name hobbies));
cmp_deeply([$name,$hobbies],\@correct,'set local variables from argument values via autoargs_get');
my($name,$hobbies)=$args->get_args(qw(name hobbies));
cmp_deeply([$name,$hobbies],\@correct,'set local variables from argument values via get_args method');

# alias $args to regular hash for more concise hash notation
use Hash::AutoHash::Args qw(autoargs_alias);
autoargs_alias($args,%args);
my($name,$hobbies)=@args{qw(name hobbies)};
cmp_deeply([$name,$hobbies],\@correct,'set local variables from alias');
$args{name}='Joseph';
is($args->name,'Joseph','set argument via alias');
$args->{name}='Joe';		# restore previous value. NOT in docs

########################################
# DESCRIPTION
# Methods to get and set keywords

my $args=new Hash::AutoHash::Args::V0(name=>'Joe',HOBBIES=>['hiking','cooking']);

my($name,$hobbies)=$args->get_args(qw(-name hobbies));
cmp_deeply([$name,$hobbies],['Joe',['hiking','cooking']],'get_args');

my %args=$args->getall_args;
cmp_deeply(\%args,{name=>'Joe',hobbies=>['hiking','cooking']},'getall_args');

$args->set_args(name=>'Joe the Plumber',-first_name=>'Joe',-last_name=>'Plumber');
my($name,$first_name,$last_name)=@$args{qw(name first_name last_name)};
cmp_deeply([$name,$first_name,$last_name],['Joe the Plumber','Joe','Plumber'],'set_args');

done_testing();
