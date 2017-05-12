#!/usr/bin/perl 

# Created: 04/28/2013 04:26:17 PM
# Last Edit: 2014 Mar 25, 08:31:30 AM
# $Id$

=head1 NAME

sum_g1_g2.pl - Mean of jigsaw scores and compcomp scores

=cut

use strict;
use warnings;

=head1 SYNOPSIS

sum_g1_g2.pl -r 3 > exam/3/g.yaml

=cut

use Cwd;
use File::Basename;
use List::MoreUtils qw/any/;
use YAML qw/LoadFile DumpFile Dump/;
use Grades;

my $script = Grades::Script->new_with_options;
my $id = $script->league || basename( getcwd );
my $exam = $script->round;

my $league = League->new( id => $id );
my $grades = Grades->new({ league => $league });
my $co = Compcomp->new({ league => $league });
my %m = map { $_->{id} => $_ } @{ $league->members };

=head1 DESCRIPTION

Exams are simultaneous jigsaw and compcomp activities. Average those 2 scores.
Jigsaw scores are already in g1.yaml. We could use inspect, instead of LoadFile.
Averages jigsaw and compComp scores. Be careful with absent players

=cut

my $leagues = $league->leagues;
my $g1 = LoadFile "$leagues/$id/exam/$exam/g1.yaml" or die "g1.yaml?";
my $g2 = $co->points($exam);
DumpFile "$leagues/$id/exam/$exam/g2.yaml", $g2 or die "g2.yaml?";
my $g2_again = $league->inspect("$leagues/$id/exam/$exam/g2.yaml");
my %g = map {
		die "Player $_ missing from g1.yaml" if not defined $g1->{$_};
		die "Player $_ missing from g2.yaml" if not defined $g2_again->{$_};
		$_ => ( $g1->{$_} + $g2_again->{$_} ) / 2
	    } keys %m;


print Dump \%g;

=head1 AUTHOR

Dr Bean C<< <drbean at cpan, then a dot, (.), and org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2013 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# End of sum_g1_g2.pl

# vim: set ts=8 sts=4 sw=4 noet:


