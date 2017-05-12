#!/usr/bin/perl

#
# test_command.t
# Copyright (C) 1997-2013 by John Heidemann
# $Id$
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

=head1 NAME

generate_ints.pl - make a repeating, controled stream of random integers

=head1 SYNOPSIS

generate_ints.pl N

=cut

use Getopt::Long;
Getopt::Long::Configure ("bundling");
pod2usage(2) if ($#ARGV >= 0 && $ARGV[0] eq '-?');
my $debug = 0;
my $x = 0;
my $a = 6364136223846793005;
my $c = 1442695040888963407;
&GetOptions('d|debug+' => \$debug,   
 	'help' => sub { pod2usage(1); },
	'man' => sub { pod2usage(-verbose => 2); },
	'n|number=i' => \$number,
	's|seed=i' => \$seed,
         'v|verbose+' => \$verbose) or &pod2usage(2);

print "#fsdb n\n";
while ($number-- > 0) {
    $x = ($a * $x + $c) % 0xefffffff;
    print "$x\n";
};
exit 0;
