use Test::Simple 'no_plan';
use strict;
use lib './lib';
use File::Trash ':all';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();
$File::Trash::DEBUG =1;

$File::Trash::ABS_TRASH = $cwd.'/t/trash';
$File::Trash::ABS_BACKUP = $cwd.'/t/backup';

my @files = qw(./t/a.tmp t/b.tmp t/c.tmp);

ok_part('make files and trash one by one');
_makefiles();

for my $rel (@files){
   my $newpath;
   ok( $newpath = trash($rel),"trashed $rel" );
}


ok_part('make files and delete all at once');

_makefiles();

my $trashed_count;
ok( $trashed_count = trash(@files), "called trash() for @files");

ok($trashed_count == 3, "trashed 3 files == $trashed_count");





ok_part("bogus things.. not on disk..");
# attempt to remove something not there
ok ! trash('./t/bogusthing');

# a thing that won't even resolve to disk..
ok ! trash('.../t/dir/bogusser');





ok_part( "doing it a many times on same files.. ");
_makefiles();
for my $rel (@files){
   my $newpath;
   ok( $newpath = trash($rel),"trashed $rel" );
   ok( $newpath=~/\.(\d+)$/,'newpath has a .digit') ;
   my $c = $1;
   ok($c, "baknum is $c");
}



ok_part( "try backup..");

_makefiles();

for my $rel (@files){
   my $newpath;
   ok( $newpath = backup($rel),"backed up $rel" );
   ok( $newpath=~/backup/ , "newpath contains 'backup'");
   print STDERRR " = $newpath\n";
   ok( -f $rel, "Still there: $rel");

}

_makefiles();

for my $rel (@files){
   my $newpath;
   ok( $newpath = backup($rel),"backe up $rel" );
   ok( $newpath=~/\.(\d+)$/,'newpath has a .digit') ;
   my $c = $1;
   ok( defined $c, "baknum is $c");
}








sub _makefiles {
   for my $rel (@files){
      system('touch',$rel) ==0 or die("cant touch $rel, $!");
   }
   ok 1;
}








sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


