#!perl -T
use warnings;
use strict;

use Test::More tests => 18;
use Test::Files;

#1
BEGIN { use_ok( 'Maildir::Lite' ); }

diag( "Testing sorting function for "
      ."Maildir::Lite $Maildir::Lite::VERSION, Perl $], $^X" );

my $dir_name="/tmp/.maildir_lit_t_$$/";
my $rc;
my $test_message="This is a sort test message $$;sort: ";
my $mdir=Maildir::Lite->new(dir=>$dir_name,sort=>\&sort_func);

#2
$rc=$mdir->mkdir("sort"); 
ok($rc==0, "Creating subdirectories");

#3
$rc=$mdir->add_action('new','S',\&new_to_sort);
ok($rc==0,"Adding action for flag \'S\' when in folder new");

#4-8
for(my $i=5;$i>=1;$i--) {
   $rc=$mdir->creat_message($test_message.$i);
   ok($rc==0, "Create and deliver message $i");
}

#9-18
for(my $i=1;$i<=5;$i++) {
   my @lines;
   $rc=$mdir->get_next_message("new",\@lines,'S');
   ok($rc==0, "Get message $i from new directory, "
         ."append \'S\' and move to sort");

SKIP: {
         skip "Did not read a message", 1 if $rc!=0;
         my $line=join(' ',@lines);
         if($line=~m/.*sort:\s*(\d+)/) {
            my $num=$1;
            ok($num==$i, "File with sort id $i (in order)");
         }
      }
}

sub new_to_sort {
   my ($path, $filename,$action)=@_;
   my $flag=uc(substr($action,0,1));

   if($flag eq 'S') {
      if(-d "$path/sort/") { 
         my $old="$path/new/$filename";
         my $new="$path/sort/$filename:2,$flag";

         if(rename($old,$new)) {
            return 0;
         } else {
            die("failed to rename \'$old\' to \'$new\'");
         }
      } else {
         die("\'$path/sort\' directory does not exist");
      }
   }
   return -1;
}


sub sort_func {
   my ($path,@messages)=@_;
   my %files; my @newmessages;

   foreach my $file (@messages) {
      my $f;
      open($f,"<$path/$file") or return @messages; #don't sort
         while(my $line=<$f>) {
            if($line=~m/sort:\s*(\d)+$/) { # string where sort info is
               $files{$file}=$1;
               close($f);
               last;
            }
         }
   }

   @newmessages= sort { $files{$a} <=> $files{$b}} keys %files;

   return @newmessages;
}
