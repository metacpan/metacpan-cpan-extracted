#!/usr/bin/env perl 

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use File::Basename qw/basename/;

use FindBin qw/$RealBin/;

use lib "$RealBin/../lib";
use File::MagicPP qw/file $VERSION/;

local $0 = basename $0;
sub logmsg{local $0=basename $0; print STDERR "$0: @_\n";}
exit(main());

sub main{
  my $settings={};
  GetOptions($settings,qw(help version)) or die $!;
  if($$settings{version}){
    print basename($0)." v$VERSION\n";
    return 0;
  }
  
  usage() if(!@ARGV || $$settings{help});

  for my $file(@ARGV){
    print file($file);
    print "\n";
  }

  return 0;
}

sub usage{
  print "$0: determines file type from magic
  Usage: $0 [options] file
  --version  Print version and exit
  --help     This useful help menu
  \n";
  exit 0;
}
