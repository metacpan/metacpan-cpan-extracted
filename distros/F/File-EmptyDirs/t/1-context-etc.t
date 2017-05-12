use Test::Simple 'no_plan';
use strict;
use lib './lib';
use File::EmptyDirs 'remove_empty_dirs';
use File::Find::Rule;
use Cwd;


use vars qw/@abs_empties @abs_notempties $abs_base/;



#INIT { # SETUP
   require Cwd;
   require File::Path;
   
   $abs_base = Cwd::cwd().'/t/emptyhere';

   @abs_empties = (
      Cwd::cwd().'/t/emptyhere/more',
      Cwd::cwd().'/t/emptyhere/more/stuff',
   );

   @abs_notempties = (
      Cwd::cwd().'/t/emptyhere/NOTEMPTY',
      Cwd::cwd().'/t/emptyhere/NOTEMPTY2',

   );
      
   
   File::Path::rmtree($abs_base); # reset



   for my $d ($abs_base, @abs_empties){
      mkdir $d;
      -d $d or die("not ondisk '$d', $!");
   }



   for my $dir (@abs_notempties){

      mkdir $dir, 0777;

      open( FILE, '>', "$dir/testfile" ) or die("cannot create '$dir/testfile', $!");
      close FILE;
   }
#}

END {

   File::Path::rmtree( $abs_base );
   
}






my @ed = File::Find::Rule->directory->in( $abs_base );

ok(scalar @ed);

### directories present: @ed



warn "\n\n";



my @removed = remove_empty_dirs( $abs_base);
ok( (scalar @removed) == 2 , "removed 2 == @removed");

### directories removed: @removed

my @ed2 = File::Find::Rule->directory->in( $abs_base );
### directories present afterwards: @ed2

for ( @abs_notempties ){
   ok( -d $_, 'not empty dir still there' );
}

for ( @abs_empties ){
   ok( ! -d $_,'empty dir gone' );
}





warn"\n\n# bogus data??\n\n";


my $result = remove_empty_dirs(Cwd::cwd().'/t/notreallyadir');
ok( ! defined $result,'wikth bogus data, returns undef' );



# if run again on same path as before..
#
$result = remove_empty_dirs( $abs_base );

ok( defined $result, 'if run again on same path as before, returns defined' );
ok( $result == 0 , 'and that defined is false (0)');


my @result = remove_empty_dirs( $abs_base );
### @result


warn 'defined? '.( defined @result ? 'yes' : 'no' );

ok( 1, 'done.');
