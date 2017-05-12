#!/usr/bin/perl -w
use strict;
use lib '../lib';
use File::SortedSeek 'get_last';
use Getopt::Long;
my $help;
my $n = 10;
GetOptions( 'help|?|h' => \$help, 'n=i' => \$n, );
usage() if $help;

for my $file (@ARGV) {
    if (open F, $file) {
        print "$_\n" for get_last(*F, $n);
        close F;
    }
    else {
        warn "Can't read $file: $!\n";
    }
}

sub usage {
    my $script = (split /[\/\\]+/,$0)[-1];
    print "
Usage: $script -n DD <files>

  Does the opposite of head(1) and grabs the tail end of a file

  -n DD specifies last DD lines (default $n)\n";
    exit;
}

=head1 NAME

tail.pl - Grok the last n lines of a file

=cut
