#!/usr/bin/perl 

# Created: 08/28/2012 02:53:15 PM
# Last Edit: 2014  2月 15, 15時58分23秒
# $Id$

=head1 NAME

school_data.pl - Get Chinese names, id info from school data about league members

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

use strict;
use warnings;
use Pod::Usage;

=head1 SYNOPSIS

[drbean@sac FIA0033] school_data.pl -s 011 -l FIA0033 | sponge league.yaml

=cut

use IO::All;
use YAML qw/Dump LoadFile DumpFile/;
use Cwd; use File::Basename;
use Encode;
use Lingua::Han::PinYin;

my $script = Grades::Script->new_with_options( league => basename(getcwd) );
pod2usage(1) if $script->help;
pod2usage(-exitstatus => 0, -verbose => 2) if $script->man;

my $leagueId = $script->league;
my $semester = $script->session;
my $leagues = "/home/drbean/$semester";
$leagueId = basename( getcwd ) if $leagueId eq '.';

=head1 DESCRIPTION

UTF-16LE Windows files in ~/admin/$semester/$school/$leagueId.txt must be converted to UTF-8 by removing non-member lines, setting fileencoding to utf-8. Make sure the characters in 2-character names are not separated by a space.

Make sure that there is a sensible member in the members field before running the script.

The second character in the Chinese name is used to generate the pinyin password.

=cut

use Grades;
my $l = League->new( leagues => "/home/drbean/$semester", id => $leagueId );
my $g = Grades->new({ league => $l });
my $c = $l->yaml;
my $school = $c->{school};
my %m = map { $_->{id} => $_ } @{ $l->members };
my $io = io("../../admin/$semester/$school/$leagueId.txt");
my @members;
my @lines = $io->slurp;
my $h2p = Lingua::Han::PinYin->new;
for my $line ( @lines ) {
        my $dline = decode( 'UTF-8', $line);
        chomp $dline;
        my ($n, $id, $name, $other) = split ' ', $dline;
	my $char = substr $name, 1, 1;
	my $password = $h2p->han2pinyin1( encode_utf8( $char) );
        push @members, {
                id => $id,
                Chinese => $name,
                name => $name,
                password => $password,
                rating => undef,
        };
}
$c->{member} = \@members;

print Dump $c;

=head1 AUTHOR

Dr Bean C<< <drbean at cpan, then a dot, (.), and org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# End of school_data.pl

# vim: set ts=8 sts=4 sw=4 noet:


