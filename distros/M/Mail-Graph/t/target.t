#!/usr/bin/perl -w

use Test;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  chdir 't' if -d 't';
  plan tests => 8;
  }

use Mail::Graph;

my $mg = Mail::Graph->new( valid_forwarders => [ 'forwarder-example.com' ], );

opendir DIR, '.' or die("cannot read dir .: $!\n");
my @files = readdir DIR;
closedir DIR;

foreach my $file (sort @files)
  {
  next if $file !~ /\.[0-9]+$/;
  open FILE, $file or die ("Cannot read file $file: $!\n");
  my $mail = "";
  while (<FILE>)
    {
    $mail .= $_;
    }
  close FILE;
  # throw away body and extract header only
  my ($header) = split /\nBODY\n/, $mail;
  $mail =~ /SHOULD-BE: '(.*?)', '(.*?)'/;
  my $res_tar = $1 
   or die ("Couldn't extract should-be target value from sample $file");
  my $res_dom = $2 
   or die ("Couldn't extract should-be domain value from sample $file");

  my @header_lines = split /\n/, $header;

  my ($target,$domain) = $mg->_extract_target(\@header_lines);

  ok ($target, $res_tar);  
  ok ($domain, $res_dom);  
  }

