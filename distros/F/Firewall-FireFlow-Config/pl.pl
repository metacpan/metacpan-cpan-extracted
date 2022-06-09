#!/usr/bin/env perl
use strict;
use warnings;

my $parentDir = './';
my $partInfo  = '.+\.pm$|.+\.pl$';    #正则表达

&search_file( $parentDir, $partInfo );

sub search_file {
  my ( $dir, $partInfo ) = @_;

  #print $partInfo, "\n";
  opendir my $dh, $dir or die "Cannot open dir $dir\n";
  my @files = readdir $dh;    #标量上下文和列表上下文
  foreach my $file (@files) {
    my $filePath = "$dir/$file";
    if (
      ( $file =~ /$partInfo/i )

      #-f 判断是否是文件
      and ( -f $filePath )
      )
    {
      print "$filePath\n";
      system "perltidy -pbp -l 120 -mbl=1 -nst -i=2 -ci=2 -bt=2 -b -bext='/' $filePath";

      # system "perltidy -iob -wn -pbp -l 120 -mbl=2 -nst -i=2 -ci=2 -bt=2 -cab=0 -b -bext='/'  $filePath";

# system "perltidy -w -nst -iob -l=120 -mbl=2 -i=2 -ci=2 -vt=0 -pt=2 -bt=2 -sbt=2 -wn -isbc -pbp -cab=0 -b -bext='/'  $filePath";
    }
    if ( ( -d $filePath ) and ( $file ne '.' ) and ( $file !~ '.vs' ) and ( $file ne '..' ) )    #-d判断是否是目录
    {
      &search_file( $filePath, $partInfo );
    }
  } ## end foreach my $file (@files)
} ## end sub search_file

