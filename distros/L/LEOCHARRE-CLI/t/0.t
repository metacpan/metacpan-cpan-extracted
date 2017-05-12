use Test::Simple 'no_plan';
use lib './lib';

use base 'LEOCHARRE::CLI';
use Cwd;


# is env HOME set?

$DEBUG = 1;
ok( DEBUG , 'DEBUG ok a');
ok( DEBUG() , 'DEBUG()');
ok( debug('debug sub'), 'debug()');




# scriptname
my $scriptname;
ok( $scriptname = _scriptname(),'scriptname returns');
ok( $scriptname eq '0.t', 'scriptname is what we expect');



# Can  we get env home
if( !$ENV{HOME}  ){
   print STDERR "Could not determine ENV HOME\n";   
   $ENV{HOME} = cwd().'/t';
}



# because we change for a tiny test... so we want to remember the original value
my $home = $ENV{HOME};
{

   # because we change for a tiny test...

   $ENV{HOME} = cwd().'/t';

   my $abs_conf = suggest_abs_conf();
   ok($abs_conf, "suggests $abs_conf conf");

   my $abs_log = suggest_abs_log();
   ok($abs_log, "suggests $abs_log log");

   my $conf = config();
   ok( ! defined $conf );


   open(FI,'>',$abs_conf) or die;
   print FI "---\ntest: gotten\n";
   close FI;

   ok( $conf = config() );
   ok($conf->{test} eq 'gotten','gotten');

   unlink $abs_conf;
}

$ENV{HOME} = $home;


#print STDERR " scriptname $scriptname\n";
#ok( yn('please enter y to confirm this works..'),'yn works');




ok( -f './t/test.conf', 'test conf file exists');


my $cwd = cwd();
my $c;

if (defined $cwd and $cwd){
   ok(1,'cwd() does return');
   $c = config( $cwd.'/t/test.conf' );

}

else {
   ok(1,'cwd() does NOT return.. trying without..');
   $c = config('./t/test.conf');
}

ok($c," config returned ");
   
ok( $c->{result} == 4,'config innards have what we expect');








