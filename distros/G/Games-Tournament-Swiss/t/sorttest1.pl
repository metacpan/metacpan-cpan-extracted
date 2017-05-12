#!/usr/bin/perl

use warnings;
use strict;

my @words1 = qw(1Remainder 1.5 1 1.5Remainder 1Bye);
my @words2 = qw(1.5 1Remainder 1.5Remainder 1 1Bye);

sub sort_brackets1 {
    if ( $a =~ /Bye$/ ) {
        return -1;
    }
    elsif ( $b =~ /Bye$/ ) {
        return 1;
    }
    elsif ( $a =~ /^(\d+\.?5?)Remainder$/ ) {
        if ( $1 eq $b ) {
            return -1;
        }
        else {
            my $numbers_a = $1;
            if ( $b =~ /^(\d+\.?5?)Remainder$/ ) {
                return $numbers_a <=> $1;
            }
            else {
                return $numbers_a <=> $b;
            }
        }
    }
    elsif ( $b =~ /^(\d+\.?5?)Remainder$/ ) {
        if ( $1 eq $a ) {
            return 1;
        }
        else {
            my $numbers_b = $1;
            if ( $a =~ /^(\d+\.?5?)Remainder$/ ) {
                return $1 <=> $numbers_b;
            }
            else {
                return $a <=> $numbers_b;
            }
        }
    }
    else { return $a <=> $b; }
}

sub sort_brackets15 {
    if ( $a =~ /Bye$/ ) {
        return -1;
    }
    elsif ( $b =~ /Bye$/ ) {
        return 1;
    }
    elsif ( $a =~ /^(\d+\.?5?)Remainder$/ ) {
        if ( $1 eq $b ) {
            return -1;
        }
        else {
            my $numbers_a = $1;
            if ( $b =~ /^(\d+\.?5?)Remainder$/ ) {
                return $numbers_a <=> $1;
            }
            else {
                return $numbers_a <=> $b;
            }
        }
    }
    elsif ( $b =~ /^(\d+\.?5?)Remainder$/ ) {
            return $a <=> $1;
    }
    else { return $a <=> $b; }
}

sub sort_brackets2 {
    if ( $a =~ /Bye$/ ) {
        return -1;
    }
    elsif ( $b =~ /Bye$/ ) {
        return 1;
    }
    elsif ( $a =~ /^(\d+\.?5?)Remainder$/ ) {
        if ( $1 eq $b ) {
            return -1;
        }
        else {
            my $numbers_a = $1;
            if ( $b =~ /^(\d+\.?5?)Remainder$/ ) {
                return $numbers_a <=> $1;
            }
            else {
                return $numbers_a <=> $b;
            }
        }
    }
    elsif ( $b =~ /^(\d+\.?5?)Remainder$/ ) {
        if ( $1 eq $a ) {
            return 1;
        }
    }
    else { return $a <=> $b; }
}

print "Print sorted \@words1 with sort_brackets1()\n";
print "(Works as expected.)\n";
foreach my $group (reverse sort { sort_brackets1() } @words1) {
    print "$group\n";
}

print "\n";
print "Print sorted \@words2 with sort_brackets1()\n";
print "(Works as expected.)\n";
foreach my $group (reverse sort { sort_brackets1() } @words2) {
    print "$group\n";
}

print "\n";
print "Print sorted \@words1 with sort_brackets15()\n";
print "(Works as expected.)\n";
foreach my $group (reverse sort { sort_brackets15() } @words1) {
    print "$group\n";
}

print "\n";
print "Print sorted \@words2 with sort_brackets15()\n";
print "(Oops, doesn't work as expected!!!!?.)\n";
foreach my $group (reverse sort { sort_brackets15() } @words2) {
    print "$group\n";
}

print "\n";
print "Print sorted \@words1 with sort_brackets2()\n";
print "(Works as expected.)\n";
foreach my $group (reverse sort { sort_brackets2() } @words1) {
    print "$group\n";
}

print "\n";
print "Print sorted \@words2 with sort_brackets2()\n";
print "(Oops, doesn't work as expected.)\n";
foreach my $group (reverse sort { sort_brackets2() } @words2) {
    print "$group\n";
}
