#!/usr/bin/env perl

use File::Basename;
use Config::IniFiles;
use strict;
use warnings;

my $outfile = shift;

my $cfg = Config::IniFiles->new ( -file => 'config' ) or die "Can't open build configuration";

open (INBIN, "<", "lemonldap-ng-cli.in") or die "Can't open file 'lemonldap-ng-cli.in' for reading";
my @contents = <INBIN>;
close (INBIN);

my $dir = dirname ($outfile);
if (not -d $dir)
{
     mkdir ($dir);
}

open (OUTBIN, ">", "$outfile") or die "Can't open file '$outfile' for writting";

foreach (@contents)
{
     my $line = $_;

     if ($line =~ /__CONFPATH__/)
     {
          my $confpath = $cfg->val ('build', 'confpath');

          $line =~ s/__CONFPATH__/$confpath/g;
     }

     print OUTBIN $line;
}

close (OUTBIN);
