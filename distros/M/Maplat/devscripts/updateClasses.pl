#!/usr/bin/perl

# MAPLAT  (C) 2008-2010 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz

use strict;
use warnings;

updateClass('lib/Maplat/Worker.pm', 'lib/Maplat/Worker', 'Maplat::Worker::');
updateClass('lib/Maplat/Web.pm', 'lib/Maplat/Web', 'Maplat::Web::');
print "Done\n";


sub updateClass {
    my ($filename, $dirname, $basename) = @_;

    print "updating $filename with $basename classes from $dirname\n";

    my @files = findModules($dirname, $basename);

    my @lines;
    open(my $ifh, "<", $filename) or die($! . ": $filename");
    @lines = <$ifh>;
    close($ifh);

    
    my $start = 0;
    my $end = 0;

    open(my $ofh, ">", $filename) or die($!);
    foreach my $line (@lines) {
        if(!$start || $end) {
            print $ofh $line;
        }
        if($line =~ /^\#\=\!\=START\-AUTO\-INCLUDES/o) {
            $start = 1;
            foreach my $newline (sort @files) {
                print $ofh 'use ' . $newline . ";\n";
                print 'use ' . $newline . ";\n";
            }
        } elsif($line =~ /^\#\=\!\=END\-AUTO\-INCLUDES/o) {
            print $ofh $line;
            $end = 1;
        }
    }
    close($ofh);
}

sub findModules {
    my ($dirname, $basename) = @_;

    my @files;

    opendir(my $dfh, $dirname) or die($!);
    while((my $fname = readdir($dfh))) {
        next if($fname =~ /^\./);

	my $fullname = $dirname . '/' . $fname;
	if(-d $fullname) {
		push @files, findModules($fullname, $basename . $fname . '::');
		next;
	} elsif($fname !~ /\.pm$/) {
		next;
	}
    $fname = $basename . $fname;
	$fname =~ s/\.pm$//g;
        push @files, $fname;
    }
    closedir($dfh);

    return @files;

}
