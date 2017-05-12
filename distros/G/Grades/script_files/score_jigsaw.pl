#!/usr/bin/perl

# Created: 西元2010年04月04日 19時52分56秒
# Last Edit: 2013 May 29, 09:17:14 PM
# $Id: score_jigsaw.pl 1966 2014-03-24 14:15:49Z drbean $

=head1 NAME

score_jigsaw.pl - Convert individual responses to a total score correct

=cut

use strict;
use warnings;

use Cwd;
use File::Basename;
use List::MoreUtils qw/any/;
use YAML qw/Bless Dump/;
use Grades;

=head1 SYNOPSIS

score_jigsaw.pl -l emile -r 3 > exams/3/scores.yaml

=cut

my $answers = Grades::Script->new_with_options;
my $id = $answers->league || basename( getcwd );
my $exam = $answers->round;

my $league = League->new( id => $id );
my $grades = Grades->new({ league => $league });

=head1 DESCRIPTION

Convert individual question answers by players in exams/3/response.yaml to total scores for individual players in exams/3/scores.yaml.

=cut

my $groups = $grades->jigsawGroups( $exam );

my $response;
for my $group ( keys %$groups ) {
	$response->{Chinese}->{$group} = 0;
	my $quiz = $grades->quiz( $exam, $group );
	my $topic = $grades->topic($exam, $group);
	my $form = $grades->form($exam, $group);
	my ($codedvalue, $n);
	for my $item ( @$quiz ) {
	    my $answer = $item->{answer};
	    if ( $item->{option} ) {
		my $option = $item->{option};
		die "Right answer for " . ($n+1) . "th item in $topic" .
		    "$form quiz," unless any { $_ eq $answer } @$option;
		$codedvalue->[$n++] = { map {
			$option->[$_] => $_ } 0..$#$option };
	    }
	    elsif ( $answer eq 'True' or $answer eq 'False' ) {
		$codedvalue->[$n++] = { True => 'T', False => 'F' } }
	    elsif ( $answer eq 'Present' or $answer eq 'Absent' ) {
		$codedvalue->[$n++] = { Absent => 'Absent', Present => 'Present' } }
	    else {
		warn "Answer for " . ($n+1) . "th item in $topic$form quiz,";
		$codedvalue->[$n++] = { Other => 'Other' } }
	}
	my $idsbyRole = $grades->idsbyRole( $exam, $group );
	my $responses = $grades->responses( $exam, $group );
	for my $id ( @$idsbyRole ) {
		my $score = 0;
		for my $n ( 0 .. $#$quiz ) {
			my $myanswer = $responses->{$id}->{$n+1};
			my $theanswer = $codedvalue->[$n]->{
				$quiz->[$n]->{answer} };
			unless ( defined $myanswer ) {
				warn "$group, ${id}'s answer on question " .
				    ($n+1) . " in $topic$form quiz?";
				next;
			}
			unless ( defined $theanswer ) {
				die "Right answer on question " . ($n+1) .
					" in " . $topic . $form . " quiz?";
			}
			$score++ if $myanswer eq $theanswer;
		}
		$response->{letters}->{$group}->{$id} = $score;
		$response->{letters}->{$group}->{story} =
				$grades->topic( $exam, $group ) .
				$grades->form( $exam, $group );
	}
	Bless( $response->{letters}->{$group} )->keys([ @$idsbyRole, 'story' ]);
}

print Dump $response;

=head1 AUTHOR

Dr Bean C<< <drbean at cpan, then a dot, (.), and org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# End of score_jigsaw.pl

# vim: set ts=8 sts=4 sw=4 noet:
