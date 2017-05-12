#!/usr/bin/perl 
##!perl -T
use warnings;
use strict;

use Test::More tests => 11;
use Test::Files;

#1
BEGIN { use_ok( 'Maildir::Lite' ); }

diag( "Testing Maildir::Lite $Maildir::Lite::VERSION, Perl $], $^X" );

#2
require_ok( 'Sys::Hostname' );
#3
require_ok( 'File::Sync' );

my $dir_name="/tmp/.maildir_lit_t_$$/";
my $rc;
my $test_message="This is a basic test message $$";
my $mdir=Maildir::Lite->new(dir=>$dir_name);

#4
$rc=$mdir->mkdir("basic"); 
ok($rc==0, "Creating subdirectories");

#5
$rc=$mdir->creat_message($test_message);
ok($rc==0, "Create and deliver message");

my $fname;
{
# get th last fname of the file:
   $_=$mdir->fname;
   my ($tp,$uniq,$host) = /(.*)_(\d+)\.(.*)/;
   $fname=$tp.'_'.($uniq-1).'.'.$host;
}

SKIP: {
         skip "Message was not created", 2 if $rc!=0;
#6
         dir_contains_ok("$dir_name/new", [$fname],
               "Directory \'new\' contains the delivered message");

#7
         file_ok("$dir_name/new/$fname",$test_message,
               "Message content was written correctly");
      }

{
   my ($fh,$stat)=$mdir->get_next_message("new");
#8
   ok($stat==0, "Get next message from new directory");

SKIP: {
         skip "Filehandle is undefined", 3 if $stat!=0;

         my @lines=<$fh>;
         my $line=join(' ',@lines);
#9
         is( $line, $test_message, "Message read was correct");
         $rc=$mdir->act($fh,'D');

#10
         ok($rc==0, "Appended info \':2,D\' and moved file to \'cur\'");

#11
         dir_contains_ok("$dir_name/cur", ["$fname:2,D"],
               "Directory \'cur\' contains the read message");
      }
}




