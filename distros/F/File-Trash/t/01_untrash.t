use Test::Simple 'no_plan';
use strict;
use lib './lib';
use File::Trash ':all';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();
#$File::Trash::DEBUG =1;

$File::Trash::ABS_TRASH = $cwd.'/t/trash';
$File::Trash::ABS_BACKUP = $cwd.'/t/backup';

system('rm -rf ./t/fileshere');
system('rm -rf ./t/trash');




mkdir './t/fileshere';
mkdir './t/trash';
my @files = qw(./t/fileshere/a.tmp ./t/fileshere/b.tmp ./t/fileshere/c.tmp);

ok_part('make files and trash one by one');
_makefiles();

for my $rel (@files){

   my $newpath = trash($rel) 
      or die($File::Trash::errstr);
   
   
   ok( $newpath,"trash() $rel" );
   ok( ! -f $rel,"now rel !-f");
   
   ok( -f $newpath,"now -f newpath");
   

   my $untrash = restore($newpath) 
      or die($File::Trash::errstr);   
   ok($untrash,'restore()');

   ok( -f $rel,"now rel -f");   
   ok( ! -f $newpath,"now !-f newpath");

   warn "\n\n";   
   
}






ok_part("untrash failures.. expected..");

my @trashed = map { trash($_) } @files;

ok (( scalar @trashed), 'trashed works ');
ok( _makefiles(), 'made files again.');

for my $trashed  (@trashed){
   $trashed=~/trash\// or die;
   ok -f $trashed, "-f $trashed";
   ok( (! restore($trashed)),"cannot restore() $trashed");
   print STDERR "    # err is : '$File::Trash::errstr'\n";
   ok -f $trashed, "-f $trashed";
   

   
  print STDERR "\n---\n"; 
}


system('rm -rf t/fileshere');




sub _makefiles {
   print STDERR "\n   #  making files # \n\n";
   for my $rel (@files){
      system('touch',$rel) ==0 or die("cant touch $rel, $!");
   }
   1;
}








sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


