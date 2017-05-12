#!/usr/bin/perl 

# Created: 02/19/2012 06:58:16 PM
# Last Edit: 2014  2月 15, 16時53分43秒
# $Id$

=head1 NAME

anterior_data.pl - Transfer names, passwords, ratings from previous semester

=cut

use strict;
use warnings;
use IO::All;
use YAML qw/LoadFile DumpFile Dump/;
use Cwd; use File::Basename;

=head1 SYNOPSIS

anterior_data.pl -l . -s 001 -o FLA0015 | sponge league.yaml

=cut

use Getopt::Long;
use Pod::Usage;
use Grades;


my $script = Grades::Script->new_with_options( league => basename(getcwd) );
pod2usage(1) if $script->help;
pod2usage(-exitstatus => 0, -verbose => 2) if $script->man;

my $leagueId = $script->league;
my $semester = $script->session;
$leagueId = basename( getcwd ) if $leagueId eq '.';
my $l = League->new( id => $leagueId );
my $g = Grades->new({ league => $l });
my $yaml = $l->yaml;
my $members = $l->members;
my %m = map { $_->{id} => $_ } @$members;

my $oldone = $script->one || $yaml->{anterior};
my $oldleagues = "/home/drbean/$semester";

=head1 DESCRIPTION

Copy old name, password, rating (grades) data from the league in league.yaml's 'anterior' field, or (old) 'one' argument, from old 'semester' argument, overwriting new data, in the case of password and rating, only if they don't exist. name is overwritten in the case it's a Chinese rather than English name.

TODO Not touching ratings because grades perhaps broken for old courses, and ratings not being used.

=cut

my $antel = League->new( leagues => $oldleagues,
	id => $oldone );
my $anteg = Grades->new({ league => $antel });
# my $grades = $anteg->grades;
my $oldmembers = $antel->yaml->{member};
my %oldm = map { $_->{id} => $_ } @$oldmembers;

my @updated;
for my $member ( @$members ) {
	my $id = $member->{id};
	# $member->{rating} ||= $grades->{ $id };
	$member->{password} ||=  $oldm{$id}->{password};
	$member->{name} = $oldm{$id}->{name} if $oldm{$id}->{name}
		and $member->{name} eq $member->{Chinese};
	push @updated, $member;
}

$yaml->{member} = \@updated;

print Dump $yaml;

=head1 AUTHOR

Dr Bean C<< <drbean at cpan, then a dot, (.), and org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# End of anterior_data.pl

# vim: set ts=8 sts=4 sw=4 noet:


