package _Auxiliary;
# Contains test subroutines for distribution with IO-Capture-Extended
# As of:  May 11, 2005
use strict;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
    print_fox
    print_fox_long
    print_fox_trailing
    print_fox_blank
    print_fox_empty
    print_fox_double
    print_greek
    print_greek_long
    print_greek_double
    print_week
); 
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

sub print_fox {
    print "The quick brown fox jumped over ... ";
    print "garden wall";
    print "The quick red fox jumped over ... ";
    print "garden wall";
}

sub print_fox_long {
    print "The quick brown fox jumped over ... ";
    print "a less adept fox\n";
    print "The quick red fox jumped over ... ";
    print "the garden wall\n";
}

sub print_fox_trailing {
    print "The quick brown fox jumped over ... ";
    print "a less adept fox\n";
    print "The quick red fox jumped over ... ";
}

sub print_fox_blank {
    print "The quick brown fox jumped over ... ";
    print "a less adept fox\n";
    print "\n";
    print "The quick red fox jumped over ... ";
}

sub print_fox_empty {
    print "The quick brown fox jumped over ... ";
    print "a less adept fox\n";
    print "";
    print "The quick red fox jumped over ... ";
}

sub print_fox_double {
    print "The quick brown fox jumped over ... ";
    print "a less adept fox\n\n";
    print "Furthermore, ";
    print "the quick red fox jumped again.\n";
}

sub print_greek {
    local $_;
    print "$_\n" for (qw| alpha beta gamma delta |);
}

sub print_greek_long {
    local $_;
    for (qw| alpha beta gamma delta |) {
        print $_;
        print "\n";
    }
}

sub print_greek_double {
    print "alpha\nbeta\ngamma\ndelta";
    print "\nepsilon\n";
}

sub print_week {
    my $weekref = shift;
    my @week = @{$weekref}; 
    for (my $day=0; $day<=$#week; $day++) {
        print "English:  $week[$day][0]\n";
        print "French:   $week[$day][1]\n";
        print "Spanish:  $week[$day][2]\n";
        print "\n";
    }
}
