use Test::Simple 'no_plan';
use strict;
use lib './lib';
use LEOCHARRE::CLI2 qw/:all/;

ok(1,'compiled');




my $r;


ok( $r = cwd(). 'cwd()');
ok( $r = abs_path($r), 'abs_path()');

my $testout = './t/temp.yml';
my %thing = ( qw/name leo age 34/);
ok( YAML::DumpFile($testout, \%thing ),'YAML::DumpFile()');
unlink $testout;



my $arg = '/home/leo/strangely stupidly named path';


ok( ($r = sq $arg ),'sq()');

warn " # quoted: $r\n";


my $dir = "./t/anxample bad name tm,'p";
mkdir $dir;

my $quoted = sq $dir ;
`touch $quoted/temp.tmp`;

my $cmd ="ls $quoted/";
my $badcmd ="ls $dir/";

ok( (system($cmd) == 0 ),
   'quoted works' );



ok( system($cmd) == 0 ,'unquoted fails' );

ok( system($badcmd) != 0 ,'unquoted fails' );

if ( _interactive() ){ 

   ok( yn('does it work? please type yes'),'yn()');
}

ok( system( sprintf 'rm -rf %s', sq($dir) ) == 0, 'del');

ok( ! -e $dir );


warn " # $quoted\n";
sub _interactive {
  return -t STDIN && -t STDOUT;
}
