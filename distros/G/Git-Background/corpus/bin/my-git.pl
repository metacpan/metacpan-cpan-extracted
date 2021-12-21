#!perl

use 5.006;
use strict;
use warnings;

if ( @ARGV == 1 && $ARGV[0] eq '--version' ) {
    print "git version 2.33.1\n";
    exit 0;
}

my $exit_code = 0;
for my $arg (@ARGV) {
    if ( $arg =~ m{ \A -x ( [0-9]+ ) \z }xsm ) {
        $exit_code = $1;
    }
    elsif ( $arg =~ s{ \A -e }{}xsm ) {
        chomp $arg;
        print STDERR "$arg\n";
    }
    elsif ( $arg =~ s{ \A -o }{}xsm ) {
        chomp $arg;
        print STDOUT "$arg\n";
    }
    else {
        die "Invalid argument: $arg";
    }
}

exit $exit_code;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
