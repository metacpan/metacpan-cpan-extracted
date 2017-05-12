#!/usr/bin/env perl
#===============================================================================
#
#         FILE:  mcerunner.pl
#
#        USAGE:  ./mcerunner.pl
#
#  DESCRIPTION: Run jobs use MCE
#===============================================================================

#package Main;

my $cmd = "";
my $x = 1;

foreach $line ( <STDIN> ) {
    chomp( $line );
    next unless $line;
    next unless $line =~ m/\S/;
    next if $line =~ m/^#/;

    if($cmd){
        if($line =~ m/\\$/){
            $line =~ s/\\$//;
            $cmd .= $line;
            next;
        }
        else{
            $cmd .= $line;
            system("export SEQNUM=$x");
            print "$cmd\n";
            $x++;
            $cmd = "";
        }
    }
    else{
        if($line =~ m/\\$/){
            $line =~ s/\\$//;
            $cmd = $line;
            next;
        }
        else{
            $cmd = $line;
            system("export SEQNUM=$x");
            print "$cmd\n";
            $x++;
            $cmd = "";
        }
    }
}
