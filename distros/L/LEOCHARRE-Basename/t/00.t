use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();

use LEOCHARRE::Basename ':all';




use Cwd;
my $absf = cwd().'/t/file.tmp';
my $absd = cwd().'/t/dirtmp';
mkdir $absd;
`touch $absf`;

ok -d $absd;
ok -f $absf;


my $r;


ok_part('absolutes');

ok( $r = abs_dir($absd),'abs_dir' );
### $r
ok( $r = abs_file($absf) , 'abs_file()');
### $r
ok( $r = abs_loc($absf) , 'abs_loc()');
### $r
ok( $r = abs_path($absf) , 'abs_path()');
### $r
ok( $r = filename($absf) , 'filename()');
### $r
ok( $r = filename_ext($absf) , 'filename_ext()');
### $r
ok( $r = filename_only($absf) , 'filename_only()');
### $r


ok_part("rels");

ok( $r = abs_dir('./t/dirtmp'),'abs_dir' );
### $r
ok( $r = abs_file('./t/file.tmp') , 'abs_file()');
### $r
ok( $r = abs_loc('./t/dirtmp') , 'abs_loc()');
### $r
ok( $r = abs_path('./t/dirtmp') , 'abs_path()');
### $r
ok( $r = filename('./t/file.tmp') , 'filename()');
ok( $r eq 'file.tmp');
### $r
ok( $r = filename_ext('./t/file.tmp') , 'filename_ext()');
ok($r eq 'tmp');
### $r
ok( $r = filename_only('./t/file.tmp') , 'filename_only()');
### $r
ok( $r = filename_only('./t/dirtmp') , 'filename_only()');
### $r











sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}



