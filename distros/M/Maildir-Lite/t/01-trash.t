#!perl -T
##!/usr/bin/perl 
use warnings;
use strict;

use Test::More tests => 6;
use Test::Files;

#1
BEGIN { use_ok( 'Maildir::Lite' ); }

diag( "Testing additional directory actions for "
      ."Maildir::Lite $Maildir::Lite::VERSION, Perl $], $^X" );

my $dir_name="/tmp/.maildir_lit_t_$$/";
my $rc;
my $test_message="This is a trash test message $$";
my $mdir=Maildir::Lite->new(dir=>$dir_name);

#2
$rc=$mdir->mkdir("trash"); 
ok($rc==0, "Creating subdirectories");

#3
$rc=$mdir->creat_message($test_message);
ok($rc==0, "Create and deliver message");

SKIP: {
         skip "No message was created", 3 if $rc!=0;
#4
         $rc=$mdir->add_action('new','trash',\&new_to_trash);
         ok($rc==0,"Adding action for flag \'T\' when in folder new");

         my $fname;
         {
# get the last finame of the file:
            $_=$mdir->fname;
            my ($tp,$uniq,$host) = /(.*)_(\d+)\.(.*)/;
            $fname=$tp.'_'.($uniq-1).'.'.$host;
         }

#5
         my @lines;
         $rc=$mdir->get_next_message("new",\@lines,'T');
         ok($rc==0, "Get next message from new directory, "
               ."append \'T\' and move to trash");
#6
         dir_contains_ok("$dir_name/trash", ["$fname:2,T"],
               "Directory \'trash\' contains the read message");
      }

sub new_to_trash {
   my ($path, $filename,$action)=@_;
   my $flag=uc(substr($action,0,1));

   if($flag eq 'T') {
      if(-d "$path/trash/") { 
         my $old="$path/new/$filename";
         my $new="$path/trash/$filename:2,$flag";

         if(rename($old,$new)) {
            return 0;
         } else {
            die("failed to rename \'$old\' to \'$new\'");
         }
      } else {
         die("\'$path/trash\' directory does not exist");
      }
   }
   return -1;
}



