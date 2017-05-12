use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use LEOCHARRE::Debug;

use vars qw($_part $cwd);
$cwd = cwd();



#open(SAVEERR, ">&STDERR");
close(STDERR);
open(STDERR, '>', \my $BUF) or die $!;
# warn warn./.
#print "buf = $buf\n";    # "buf = foo"
# NOW BUF HOLDS STUFF






$DEBUG        = 0;
$TestD::DEBUG = 0;
$TestF::DEBUG = 0;

ok( defined $DEBUG );

ok( !$DEBUG, "main::DEBUG not true ($DEBUG)") or print " had $DEBUG \n" and exit;


ok( lookie(),'lookie' );

ok( $BUF!~/lookiehere/, 'did not print to stderr') or print("buf has $BUF") and exit;




$DEBUG = 1;
ok( debug('amimain???') );
ok( should() );
ok( $BUF=~/YOU SHOULD SEE ME/,'did have what was expected');


$DEBUG = 0;
ok debug("notmenotme");
ok( $DEBUG!~/notmenotme/ );



$DEBUG        = 0;
$TestD::DEBUG = 0;
$TestF::DEBUG = 1;



TestD::testme();
TestF::testme();
maind();

ok( $BUF=~/testftest/ );
ok( $BUF!~/testdtest/ );
ok( $BUF!~/maindhere/ );


print "BUF : $BUF\n\n";


# what are the refs to?>??
my @r = (\$DEBUG, \$TestD::DEBUG, \$TestF::DEBUG);
ok( $r[0] != $r[1]," diff refs: @r" );
ok( $r[1] != $r[2] );
ok( $r[0] != $r[2] );




sub should { debug("YOU SHOULD SEE ME") }


sub maind { debug("maindhere") }
sub lookie { debug("lookiehere") }

sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}







package TestD;

use LEOCHARRE::Debug;


sub testme {  debug('testdtest') }

1;


package TestF;
use LEOCHARRE::Debug;

sub testme {  debug("testftest") }

1;
