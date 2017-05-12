use lib './lib';
use LEOCHARRE::Test 'no_plan';
use warnings;

ok_part('db stuff');


if( $ARGV[0]  ){
   print STDERR "setting LEOCHARE::Test::ABS_MYSQLD to $ARGV[0]\n";
   $LEOCHARRE::Test::ABS_MYSQLD = $ARGV[0];
   -e $ARGV[0] or die("does not exist on disk $ARGV[0]");
}
   
my $sqld = $LEOCHARRE::Test::ABS_MYSQLD or die('missing default ABS_MYSQLD');


ok(1,"1.Trying sqld $sqld");

-e $sqld 
   ? print STDERR "Is present: $sqld\n"
   : ( print STDERR "Skipping 01_mysqld.t, Not present: $sqld\n" and exit );


print STDERR "# testing that status wont fail.. \n";

my $sstatus = system( $sqld, 'status');

ok(!$!, "didnt bonk on status call to $sqld") 
   or print STDERR " # failing status on $sqld? err = '$!  - status $sstatus'\n" 
   and exit;






ok_part('testing actual mysql serverfor localhost... ');

   

my $status = `$sqld status`;

if ( $status =~/stopped/i ){
   print STDERR " = is stopped... \n";
   
   #ok( ! eval { ok_mysqld('localhost') },   'we are returning stopped' );
   exit;
   

   
}
elsif ( $status=~/running/i ){
   print STDERR " = is running... \n";

   ok( ok_mysqld('localhost'), 'we report running and is running');
}

else {
   print STDERR "4. dunno what to do with status '$status'\n";
   exit;
}




ok_part('other helpsubs');

ok( mysqld_exists(), 'mysqld_exists');
ok( mysqld_running(), 'mysqld_running');
