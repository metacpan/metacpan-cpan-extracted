#!/usr/bin/perl

use warnings;
use strict;
use POSIX qw(strftime);
use MD5Check;


if ( @ARGV == 0 ) {
    warn "$0: 请输入需要初始化的目录!\n";
}
else {
    if ( @ARGV > 1 ) {
        warn "Usage: $0 目录名\n";
    }
}

my $mydir = shift;
print "$mydir \n";

$mydir = $ENV{'PWD'} if !defined($mydir);

my $month1 = strftime "%m", localtime();
my $day    = strftime "%d", localtime();
my $year   = strftime "%Y", localtime();
my $out    = $mydir . "/md5file-" . $year . $month1 . $day;

open my $Ofile, ">>", $out or die $!;

my $result = md5init($mydir,$Ofile);

print $Ofile $result;

close $Ofile;
