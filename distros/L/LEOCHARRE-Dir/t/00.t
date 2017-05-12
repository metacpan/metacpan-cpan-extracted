use Test::Simple 'no_plan';
use lib './lib';
use LEOCHARRE::Dir ':all';
use strict;
use File::Path 'rmtree';

my $x = 0;
sub ok_part {
   no warnings;
   printf STDERR "\n\n===\nPART %s %s\n\n", $x++, (+shift);
   return 1;
}

ok_part();

my $_d = './t/testdir';

rmtree($_d) if -d $_d;


ok ( ! -d $_d );

my $dir = reqdir($_d);
ok($dir, "dir $dir");

ok -d $dir, 'made';

ok ! lsa($dir), 'nothing there yet';

ok reqdir( "$dir/one" );
ok reqdir( "$dir/two" );
ok reqdir( "$dir/three");

ok_part();



for ( 0 .. 1 ) {
   touch("$dir/f$_");
   #`touch '$dir/f$_'`;
   ok -f "$dir/f$_",'made file';
}


my @l = ls($dir);
ok( scalar @l, "have [@l]");

@l = lsa($dir);
ok( scalar @l, "lsa have [@l]");

@l = lsf($dir);
ok( scalar @l, "lsf have [@l]");
for (@l ){ -f "$dir/$_" or die("lsf() NOT FILE $_"); }

@l = lsd($dir);
ok( scalar @l, "lsd have [@l]");
for (@l ){ -d "$dir/$_" or die("lsd() NOT DIR $_"); }


@l = lsda($dir);
ok( scalar @l, "lsda have [@l]");
for (@l ){ -d "$_" or die("lsda() NOT DIR $_"); }

@l = lsfa($dir);
ok( scalar @l, "lsfa have [@l]");
for (@l ){ -f "$_" or die("NOT FILE $_"); }

ok_part('failtest');

ok( ! eval { ls(); } );




ok_part('rels');
require Cwd;
$ENV{DOCUMENT_ROOT} = Cwd::cwd() .'/t';

my @r = lsr($dir);
ok scalar @r, "have rels [@r]";

@r = lsfr($dir);
ok scalar @r, "lsfr have rels [@r]";

@r = lsdr($dir);
ok scalar @r, "lsdr have rels [@r]";







rmtree($_d);
#ystem( "rm -rf $_d");
exit;


sub touch {
   my $where = shift;
   $where or die;
   open(FILE,'>',$where) or warn("Cant open for writing '$where', $!") and return;
   close FILE;
}
