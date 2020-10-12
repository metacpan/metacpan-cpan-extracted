use Test::Simple 'no_plan';
use lib './lib';
use LEOCHARRE::Dir ':all';
use strict;
use File::Path 'rmtree';

my $x = 0;
sub ok_part {
   no warnings;
   printf STDERR "\n# PART %02d %s\n", $x++, join(', ',@_);
   return 1;
}

ok_part('reqdir() stuff');


=pod 

some of these test involve creating directories, testing for them etc
if the test fails and leaves things in t/ as a mess.. we need a cleanup of
sorts.

=cut
my $test_directory_relative_path = './t/testdir';
if ( -d $test_directory_relative_path ){
   rmdir $test_directory_relative_path or die("cant delete dir $? $!");
   map { 
      rmdir "$test_directory_relative_path/$_" 
      } (qw(one two three));

}




my $_d = './t/testdir';

#rmtree($_d) if -d $_d;

ok ( ! -d $_d, "Not -d : '$_d'" );

#my $dir = reqdir($_d);
#ok($dir, "dir $dir");

my $dir;
ok( $dir = reqdir($_d), 'reqdir()');
ok (-d $dir, "-d $dir");

ok( ! lsa($dir), 'lsa() nothing there yet');

ok( reqdir("$dir/one"), 'reqdir()' );
ok( reqdir("$dir/two"), 'reqdir()' );
ok( reqdir("$dir/three"), 'reqdir()' );




ok_part('ls type subs');

for ( 0 .. 1 ) {
   touch("$dir/f$_");
   #`touch '$dir/f$_'`;
   ok( -f "$dir/f$_",'touch() made file');
}


my @l = ls($dir);
ok( scalar @l, "ls() have [@l]");

@l = lsa($dir);
ok( scalar @l, "lsa() have [@l]");

@l = lsf($dir);
ok( scalar @l, "lsf() have [@l]");
for (@l ){ -f "$dir/$_" or die("lsf() NOT FILE $_"); }

@l = lsd($dir);
ok( scalar @l, "lsd() have [@l]");
for (@l ){ -d "$dir/$_" or die("lsd() NOT DIR $_"); }


@l = lsda($dir);
ok( scalar @l, "lsda() have [@l]");
for (@l ){ -d "$_" or die("lsda() NOT DIR $_"); }

@l = lsfa($dir);
ok( scalar @l, "lsfa() have [@l]");
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
