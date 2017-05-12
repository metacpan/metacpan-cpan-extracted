#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper qw/Dumper/;

use Getopt::Alt qw/get_options/;

main();

sub main {

    my $opt = get_options(
        'test|t',
        'inc|i+',
        'str|s=s',
        'verbose|v+',
    );

    if ($opt->test) {
        print "In test mode!\n";
        }
        if ($opt->inc) {
        print "Inc\n" x $opt->inc;
    }
    if ($opt->str) {
        print "You said: " . $opt->str . "\n";
    }
    if ($opt->verbose) {
        print Dumper $opt;
    }
}

__DATA__

=head1 NAME

simple.pl - a simple example file using Getopt::Alt

=head1 SYNOPSIS

  simple.pl --help
  simple.pl [-t | --test] [--inc num |-inum] [--str str | -s str]

  OPTION:
   -t --test     Test mode
   -i --inc=numb Pass in a number
   -s --str=str  Pass in a string

   -v --verbose  Out put dump of Getopt::Alt object use twice for more details
      --help     Should display this message and is defined in Getopt::Alt itself

=head1 REST

=cut
