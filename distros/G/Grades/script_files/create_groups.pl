#!/usr/bin/perl 

# Created: 10/15/2011 07:52:09 PM
# Last Edit: 2014  2月 16, 21時36分31秒
# $Id$

=head1 NAME

create_groups.pl - Partition league into teams fairly on basis of ratings

=cut

use 5.10.0;
use strict;
use warnings;
use IO::All;
use YAML qw/LoadFile DumpFile Dump/;
use Cwd; use File::Basename;
use POSIX qw/floor ceil/;
use List::MoreUtils qw/all/;

use Getopt::Long;
use Pod::Usage;
use Grades;

use Try::Tiny;

=head1 SYNOPSIS

create_groups.pl -l . -s 2 -n 3 | sponge classwork/2/groups.yaml

=cut



=head1 DESCRIPTION

Takes league and individual members' grades and partititions into the teams in $league->yaml->{groupwork}/$session/groups.yaml, $n (or $n-1) players to a team, so that the sum of the grades of members of each team are similar.

If the number of groups already present in the groups.yaml files is the same as the number of groups which will be generated, the names of the groups are retained. If not, consecutive names in color order are chosen.

If there are rump groups, retain the rump players in the same groups they are already in in groups.yaml, by putting their groups at the end of the line.

=cut


my $script = Grades::Script->new_with_options( league => basename(getcwd) );
pod2usage(1) if $script->help;
pod2usage(-exitstatus => 0, -verbose => 2) if $script->man;
my $leagues = "/home/drbean/022";
my $leagueId = $script->league;
$leagueId = basename( getcwd ) if $leagueId eq '.';
my $l = League->new( leagues => $leagues, id => $leagueId );
my $g = Grades->new({ league => $l });
my $members = $l->members;
my %m = map { $_->{id} => $_ } @$members;
my $grades;
$grades = try { $g->grades } catch { warn "Not grouping on grades: $_";
    $grades = { map { $_ => $m{$_}->{rating} } keys %m } };

my $session = $script->session;
my $lastsession = $session > 1 ? $session - 1 : 1;
# my $lastsession = $session;

my $n = $script->beancan || 3;

my $gs;
$gs = try { LoadFile "classwork/$lastsession/groups.yaml" } catch
    { $gs = {} };
my @keys = keys %$gs;
my @colors = qw/1-1 1-2 2-1 2-2 3-1 3-2 4-1 4-2 5-1 5-2 6-1 6-2 
	8-1 8-2 9-1 9-2 10-1 10-2 11-1 11-2 12-1 12-2 13-1 13-2 14-1 14-2/;
my %g;
my @graded = sort { $grades->{$a} <=> $grades->{$b} }keys %m;
my @t = map  $m{$_}->{name}, @graded;
my $groups = ceil @t/$n;
my @groupname = ( @keys == $groups )? sort @keys: @colors[0 .. $groups-1];
my $rumpPlayers = @t % $n;
my $rumpGroups = $rumpPlayers == 0?	0: $n - $rumpPlayers;
my (@resortGroups, @rumpGroupname);
if ( $rumpGroups ) {
    for my $name ( @groupname ) {
	my $members = $gs->{$name};
	if ( $members ) {
	    push @resortGroups, $name if @$members == $n;
	    push @rumpGroupname, $name if @$members < $n;
	    die scalar @$members . " in $name group" if @$members > $n;
	}
    }
}
if ( @resortGroups ) {
    push @resortGroups, @rumpGroupname;
    @groupname = @resortGroups;
}

if ( $n == 4 ) {
    my $half =	$rumpPlayers == 1?	ceil @t/2:
		$rumpPlayers == 2?	@t/2:
		$rumpPlayers == 3?	floor @t/2:
		$rumpPlayers == 0?	@t/2 - 1:
					die "rumpPlayers greater than $n";
    if ( $rumpPlayers ) {
	    for my $k ( 0 .. $rumpGroups -1 ) {
		    $g{ $groupname[ -1 -$k ] } = [ $t[$k],
						$t[ ( $half - $k ) ],
						$t[ -1 -$k ] ];
	    }
    }
    for my $i ( $rumpGroups .. $groups-1 ) {
	    $g{ $groupname[ $i - $rumpGroups ] } = [ $t[ $i ],
						    $t[ $half - $i ],
						    $t[ $#t - ( $half - $i ) ],
						    $t[ -1 - $i ] ];
    }
}

if ( $n == 3 ) {
    if ( $rumpPlayers ) {
	    for my $k ( 0 .. $rumpGroups -1 ) {
		    $g{ $groupname[ -1 -$k ] } = [ $t[$k],
						$t[ -1 -$k ] ];
	    }
    }
    my $half = @t/2;
    my @sign = (-1,+1);
    for my $i ( $rumpGroups .. $groups-1 ) {
	    my $j = $i - $rumpGroups;
	    $g{ $groupname[ $j ] } = [ $t[ $i ],
						$t[ $half + $sign[$j % 2] * ($j)/2 ],
						$t[ -1 - $i ] ];
    }
}

if ( $n == 2 ) {
    my $half = @t/2;
    if ( $rumpPlayers ) {
	for my $k ( 0 .. $rumpGroups -1 ) {
	    $g{ $groupname[ -1 -$k ] } = [ $t[ $half ] ];
	}
    }
    for my $k ( $rumpGroups .. $groups-1 ) {
	my $i = $k - $rumpGroups;
	$g{ $groupname[ $i ] } = [ $t[ $i ],
						$t[ -1 - $i ] ];
    }
}

my %algocheck;
@algocheck{@t} = ( 0 ) x @t;
for my $group ( keys %g ) {
    for my $name ( @{ $g{$group} } ) {
	$algocheck{$name}++;
	print STDERR "$name dupe in $group group.\n" if $algocheck{$name} >= 2;
    }
}
for my $name ( @t ) {
    print STDERR "$name has no group.\n" unless $algocheck{$name};
}
print STDERR "No dupes in groups.\n" if all { $algocheck{$_} == 1 } @t;

print Dump \%g;

=head1 AUTHOR

Dr Bean C<< <drbean at cpan, then a dot, (.), and org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# End of create_groups.pl

# vim: set ts=8 sts=4 sw=4 noet:


