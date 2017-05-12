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



ok( $r = filename_ext($absf) , 'filename_ext()');
### $r

ok( $r = filename_ext($absf,'tmp') , 'filename_ext() string');
### $r



ok( $r = filename_ext($absf,qr/tmp/) , 'filename_ext() qr ');
### $r



ok( ! filename_ext($absf,qr/TMP/) , 'filename_ext() another qr ');



ok( $r = filename_ext($absf,qw/tmp TMP/) , 'filename_ext() list 1');

### $r

ok( ! filename_ext($absf,[qw/Tmp abb/]) , 'filename_ext() list ref');

ok( ! filename_ext($absf,qw/jpg tm mp/) , 'filename_ext() list 2');











sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}



