#!perl -w

use strict;
use Language::Zcode::Parser;

=head1 NAME

tuxedo.pl - find subs in a Z-code file

=head1 DESCRIPTION

This program finds the locations of the subroutines in a Z-code file.

Right now, the program is actually used to confirm that the pure Perl
parser is working - it compares the results with the results from
the state-of-the-art (1992) txd parser, and lists any differences.

(Note: some differences are OK. It appears that txd sometimes ignores
a @ret in a file if there's another returning opcode just before it;
in weird cases, this can lead to significant differences in the reported
last command in the sub.)

=cut

# Get args
my $infile = shift;

# We're going to open a txd AND Perl parser in order to compare results.
# Of course, some stuff, like reading the header, only needs to be done once
my $tParser = new Language::Zcode::Parser "TXD";
my $pParser = new Language::Zcode::Parser "Perl";

# If they didn't put ".z5" at the end, find it anyway
$infile = $tParser->find_zfile($infile) || exit;

# Read in the file, store it in memory
$tParser->read_memory($infile);

# Parse header of the Z-file
$tParser->parse_header();

# Run txd to get the address of each subroutine
my %tSubs = map {$_->address, $_->last_command_address} 
    $tParser->find_subs($infile);
my %pSubs = map {$_->address, $_->last_command_address} $pParser->find_subs();

# Analyze results
my @found = sort {$a <=> $b} keys(%tSubs); # assume txd found everything
print "Found ",scalar(keys %pSubs)," routines out of ", $#found+1,".\n";
my $ct = 0;
foreach my $r (@found) {
    my $t = exists $pSubs{$r} ? $pSubs{$r} : "UNFOUND";
    my $txd_end = $tSubs{$r};
    if (my $diff = exists $pSubs{$r} ? $pSubs{$r} - $txd_end : "N/A") {
	print "Rtn Start\tLast Cmd: Perl\ttxd\tDiff\n" unless $ct++;
	printf "%x (%d)\t\t$t\t$txd_end\t$diff\n", $r, $r;
    }
}
foreach my $r (keys %pSubs) {
    printf "BAD: found extra sub %x (%d) ending at $pSubs{$r}\n", $r, $r
	if !exists $tSubs{$r};
}
delete @tSubs{keys %pSubs};
print "Unfound subs: ";
print keys %tSubs ? map({sprintf "%x ",$_} keys %tSubs) : "None!";
print "\n";

exit;

=head1 NOTES

If I had but world enough and time, tuxedo could become a fancy (more
"formal") version of txd and its companion, infodump. But in reality,
it's more of a black-and-white version of txd.

=head1 AUTHOR

Amir Karger <akarger@cpan.org>

=head1 LICENSE

Copyright (c) 2004 Amir Karger.  All rights reserved.  

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
