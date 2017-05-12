use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();

use LEOCHARRE::Basename qw/abs_dir_or_die abs_file_or_die abs_loc dirname basename filename/;


use Cwd;
my $absf = cwd().'/t/file.tmp';
my $absd = cwd().'/t/dirtmp';
mkdir $absd;
`touch $absf`;

ok -d $absd;
ok -f $absf;

my $r;



ok( $r = abs_dir_or_die($absd) ,'abs_dir_or_die()');

ok( $r = abs_loc($absd),'abs_loc()');

ok( $r = dirname($absd) ,'dirname()');
ok( $r eq 't','dirname()' );


ok( eval { abs_file_or_die($absf) }  ,'abs_file_or_die()');
ok( ! eval { abs_file_or_die($absd) }  ,'abs_file_or_die()');


ok( filename($absf) eq 'file.tmp' ) or die("got:" .filename($absf));
ok(  dirname($absf) eq 't' ) or die("got: ". basename($absf) );
ok( basename($absf) ne 'sdf' );


# test dirname

   # subname, arg, result desired
my @tests = (
   [ basename => $absf, 'file.tmp'],
   [ basename => $absd, 'dirtmp' ],
   [ basename => '', undef ],
   [qw(dirname ./t/dirtmp t)],
   [qw(dirname ./t 1)],
   [ dirname => '', 0],

   
);

for ( @tests ){
   no strict 'refs';
   my ($subname, $arg,$result_desired ) = @$_;

   my $result_desired_is_true   = $result_desired ? 1 : 0;
   my $result_desired_is_boolean = ($result_desired=~/^0$|^1$/ ? 1 : 0 );

   my $result_desired_is_string = $result_desired=~/[a-z]/ ? 1 : 0;
   my $result_desired_is_number= $result_desired=~/^\d+$/ ? 1 : 0;

   my $_result_now = &{$subname}($arg);

   printf "%s\n# subname '%s', arg '%s', result wanted: '%s'\n\n",
      '-'x80, $subname, $arg, $result_desired;

   if ($result_desired_is_true){
      ok( $_result_now, "$subname()") 
         or warn("# got instead: '$_result_now'\n");
   }
   else {      
      ok( ! $_result_now, "$subname()")
         or warn("# got instead: '$_result_now'\n");
   }


   if ($result_desired_is_string){
      ok( $_result_now eq $result_desired,"$subname() returned string expected" )
         or warn("# got instead: '$_result_now'\n");
   }
   elsif ( $result_desired_is_boolean ){
      ok( ($_result_now ? 1 : 0 ) == $result_desired, "$subname() returns boolean expected")
         or warn("# got instead: '$_result_now'\n");
   }      
   elsif( $result_desired_is_number){
      ok( $_result_now == $result_desired, "$subname() returns number expected")
         or warn("# got instead: '$_result_now'\n");
   }






}



sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}



