#!/usr/bin/perl

# Last Edit: 2014 Jan 14, 01:12:46 PM
# $Id: /dic/branches/ctest/grade 1160 2007-03-29T09:31:06.466606Z greg  $

use strict;
use warnings;

use List::Util qw/max min sum/;

use Text::Template;
use IO::All;
use YAML qw/ LoadFile Dump DumpFile /;
use Grades;
use Cwd; use File::Basename;

my $script = Grades::Script->new_with_options;
my $id = $script->league || basename( getcwd );
my $exam = $script->round;
my $beansInCan = $script->beancan || 3;

my $league = League->new( id => $id );
my $grades = Grades->new({ league => $league });

my $config = $grades->config('Jigsaw', $exam);
my $members = $league->members;
my %ids = map { $_->{name} => $_->{id} } @$members;
my %names = map { $_->{id} => $_->{name} } @$members;
my $groups = $grades->jigsawGroups( $exam );
my $sixtypercentScore = $config->{pass};
my $topGrade = $grades->examMax;
my $totalQuestions = $config->{questions}->[0];

my @examinees = map { @{ $groups->{$_} } } keys %$groups;
my $absentees;
$absentees = $league->{absent} if $league->{absent}; 
push @$absentees, @{$config->{absent}} if $config->{absent};
my @absenteeIds = map { $ids{$_} } @$absentees;

my $assistants = $config->{assistant};
$assistants = undef if grep m/No.*ne/i, @$assistants;
my @assistantIds = map { $ids{$_} } @$assistants;

my %groupName = map {
	my $groupId = $_;
	my $members = $groups->{$groupId};
	map { $_ => $groupId } @$members;
						} keys %$groups;
my $gradesheets = $league->{$exam};

my %indScores = ();
my %assistantRecords = ();
my %indScoresByScore = ();
my %groupScores = ();
my %groupScoresByScore = ();
my %points = ();
my %pointsByPoints = ();
my @number = qw/First Second Third Fourth Fifth Sixth/;

my $questions2grade = sub {
        my $questionsRight = shift;
	my $passingGrade = $topGrade * 60 / 100;
	# return sprintf '%.0f', ( $passingGrade +
        return ( $passingGrade +
		($questionsRight-$sixtypercentScore)*( $topGrade-$passingGrade)/
		($totalQuestions-$sixtypercentScore));
};

#my $grade2questions = sub {
#        my $grade = shift;
#        return 1 + int ( $passquestions +
#		($grade-$passGrade)*($totalQuestions-$passquestions)/
#		($perfectGrade-$passGrade));
#};

foreach my $group ( keys %$groups )
{
	my $members = $groups->{$group};
	my @letters = ('A' .. 'D')[0..$beansInCan-1]; 
	my %group; @group{ @letters } =  @$members; 
	my $score = $grades->rawJigsawScores( $exam, $group );
	my $chinese = $grades->jigsawDeduction( $exam, $group );
	my $story = $grades->topic($exam, $group) . $grades->form($exam, $group);
	my %rolebearers = reverse %group;
	my @assistantPlayers;
	my (@noexam, $groupGrade);
	my $totalScore = 0;
	foreach my $player ( @$members )
	{
		my $playerId = $ids{$player};
		warn "$player has no id.\n" unless $playerId;
		my $role = $rolebearers{$player};
		warn "$player has no role.\n" if not defined $role;
		warn "$player in $group group has no score\n" if not defined
							$score->{$playerId};
		my $personalScore = sum map
			{
				$score->{$playerId}
			} 0;
		$totalScore += $personalScore;

		if (grep m/$playerId/, @assistantIds)
		{
			push @assistantPlayers, $playerId;
			my $assistantId = $playerId;
			my %assistedRecord;
			$assistedRecord{personalScore} = $personalScore,
			$assistedRecord{Chinese} = $chinese;
			$assistedRecord{group} = $group;
			$assistantRecords{$assistantId}->{$group} = 
				\%assistedRecord;
		}
		$indScores{$playerId} = $personalScore;
		push @{$indScoresByScore{$personalScore}},
							"$player $playerId\\\\";
	}
	foreach my $assistantId ( @assistantPlayers )
	{
		$assistantRecords{$assistantId}->{$group}->{totalScore} =
						$totalScore;
	}
	$groupScores{$group} = $totalScore;
	my @memberNames = values %group;
	my @groupsIds = @ids{@memberNames};
	my @memberScores = map { "$names{$_}($indScores{$_})" } @groupsIds;
	push @{$groupScoresByScore{$groupScores{$group}}},
				"$group. @memberScores. Chinese: $chinese\\\\ ";
	# $groupGrade = int (((60/100)*$topGrade/sqrt($sixtypercentScore)) *
	# 					sqrt($totalScore));
	# $groupGrade = int ((($totalScore/$beansInCan)*( 9**2.3/$sixtypercentScore ))**(1/2.3) );
	$groupGrade = $questions2grade->($totalScore/$beansInCan);
	$groupGrade = $groupGrade > $topGrade? $topGrade: $groupGrade;
	@points{ @groupsIds } = ($groupGrade) x @groupsIds;
	push @{$pointsByPoints{$groupGrade}},
		"$group. @names{@groupsIds} ($story)\\\\";
}

@indScores{@assistantIds} = map {
		my $assistant = $_;
		my $score = max map { $assistantRecords{$assistant}->{$_}->{personalScore} }
			keys %{$assistantRecords{$assistant}};
		$score;
				} @assistantIds if $assistants;
@points{@assistantIds} = map {
		my $assistant = $_;
		my $points = max map {
			my $totalScore = $assistantRecords{$assistant}->{$_}->{totalScore};
		my $groupGrade = $questions2grade->($totalScore/$beansInCan);
		# my $groupGrade = int ((($totalScore/$beansInCan)*( 9**2.3/$sixtypercentScore ))**(1/2.3) );
			$groupGrade > $topGrade? $topGrade: $groupGrade;
		} keys %{$assistantRecords{$assistant}};
		$points;
		} @assistantIds;

# @indScores{@absenteeIds} = (0)x@absenteeIds;
# push @{$indScoresByScore{0}}, "$names{$_} $_\\\\" foreach @absenteeIds;
# @points{ @absenteeIds } = (0)x@absenteeIds;
# push @{$pointsByPoints{0}}, "$names{$_} $_\\\\" foreach @absenteeIds;

# =begin comment text

my %adjusted = map
	{
	die "$_?" unless exists $points{$ids{$_}}
		&& defined $grades->jigsawDeduction( $exam, $groupName{$_} );
	$ids{$_} => $points{$ids{$_}}
		- $grades->jigsawDeduction( $exam, $groupName{$_} )
	} @examinees;
@adjusted{@assistantIds} = map
	{
		my $assistant = $_;
		my @adjusted =
			map { die "$assistant Chinese: $assistantRecords{$assistant}->{$_}->{Chinese}?"
			unless defined $assistantRecords{$assistant}->{$_}->{Chinese};
			my $totalScore = $assistantRecords{$assistant}->{$_}->{totalScore};
			my $groupGrade = $questions2grade->($totalScore/$beansInCan);
			my $adjusted = $groupGrade -
				$assistantRecords{$assistant}->{$_}->{Chinese}
			}
					keys %{$assistantRecords{$assistant}};
		max @adjusted;
	} @assistantIds;
# @adjusted{@absenteeIds} = (0)x@absenteeIds;
my %adjustedByGrades = ();
map
{
	# die "$names{$_} $_?" unless exists $adjusted{$_}
					# && exists $names{$_} && defined $_;
	push @{$adjustedByGrades{$adjusted{$_}}}, "$names{$_} $_ \\\\ "
		unless $points{$_} == 0;
} values %ids;

print Dump \%adjusted;

@{$pointsByPoints{$_}} = sort @{$pointsByPoints{$_}} foreach keys %pointsByPoints;
@{$adjustedByGrades{$_}} = sort @{$adjustedByGrades{$_}}
						foreach keys %adjustedByGrades;

@{ $indScoresByScore{$_} } = sort @{ $indScoresByScore{$_} }
			for keys %indScoresByScore;

my @indReport = map
	{ "\\vspace{-0.4cm} \\item [$_:] \\hspace*{0.5cm}\\\\@{$indScoresByScore{$_}}" }
		sort {$a<=>$b} keys %indScoresByScore;
my @groupReport = map 
	{ "\\vspace{-0.4cm} \\item [$_:] \\hspace*{0.5cm}\\\\@{$groupScoresByScore{$_}}" }
		sort {$a<=>$b} keys %groupScoresByScore;
my @pointReport = map 
	{ "\\vspace{-0.4cm} \\item [$_:] \\hspace*{0.5cm}\\\\@{$pointsByPoints{$_}}" }
		sort {$a<=>$b} keys %pointsByPoints;
my @adjustedReport = map 
	{ "\\vspace{-0.4cm} \\item [$_:] \\hspace*{0.5cm}\\\\@{$adjustedByGrades{$_}}" }
		sort {$a<=>$b} keys %adjustedByGrades;

my $report;
$report->{id} = $league->id;
$report->{league} = $league->name;
$report->{week} = $config->{week};
$report->{round} = $config->{round};
$report->{indScores} = join '', @indReport;
$report->{groupScores} = join '', @groupReport;
$report->{points} = join '', @pointReport;
$report->{grades} = join '', @adjustedReport;



$report->{autogen} = "% This file, report.tex was autogenerated on " . localtime() . "by grader.pl out of report.tmpl";
my $template = Text::Template->new(	TYPE => 'FILE',
					SOURCE => '../../../class/tmpl/report.tmpl',
					DELIMITERS => [ '<TMPL>', '</TMPL>' ] );
open TEX, ">report.tex";
print TEX $template->fill_in( HASH => $report );

=begin comment text
sub scores2grade {
	my $score = shift;
	$groupGrade = int ((($totalScore/$beansInCan)*( 9**2.3/$sixtypercentScore ))**(1/2.3) );
	$groupGrade = $groupGrade > $topGrade? $topGrade: $groupGrade;
	return $groupGrade;
}

