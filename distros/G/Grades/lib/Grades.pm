package Grades;
{
  $Grades::VERSION = '0.16';
}

#Last Edit: 2014  2月 15, 16時23分02秒
#$Id: Grades.pm 1960 2014-02-15 08:27:09Z drbean $

use MooseX::Declare;

package Grades::Script;
{
  $Grades::Script::VERSION = '0.16';
}
use Moose;
with 'MooseX::Getopt';

has 'man' => (is => 'ro', isa => 'Bool');
has 'help' => (is => 'ro', isa => 'Bool');
has 'league' => (metaclass => 'Getopt', is => 'ro', isa => 'Str',
		cmd_flag => 'l',);
has 'exam' => ( metaclass => 'Getopt', is => 'ro', isa => 'Str',
		cmd_flag => 'e',);
has 'session' => ( metaclass => 'Getopt', is => 'ro', isa => 'Str',
		cmd_flag => 's',);
has 'beancan' => ( metaclass => 'Getopt', is => 'ro', isa => 'Int',
		cmd_flag => 'n',);
has 'tables' => ( metaclass => 'Getopt', is => 'ro', isa => 'Str',
		cmd_flag => 'g',);


has 'round' => ( metaclass => 'Getopt', is => 'ro', isa => 'Str',
		cmd_flag => 'r',);

# letters2score.pl
has 'exercise' => ( metaclass => 'Getopt', is => 'ro', isa => 'Str',
		cmd_flag => 'x',);
has 'one' => ( metaclass => 'Getopt', is => 'ro', isa => 'Str',
		cmd_flag => 'o',);
has 'two' => ( metaclass => 'Getopt', is => 'ro', isa => 'Str',
		cmd_flag => 't',);

has 'weights' => (metaclass => 'Getopt', is => 'ro', isa => 'Str',
		cmd_flag => 'w',);
has 'player' => (metaclass => 'Getopt', is => 'ro', isa => 'Str',
		cmd_flag => 'p',);

package Grades;

=head1 NAME

Grades - A collocation of homework, classwork and exams

=head1 SYNOPSIS

	use Grades;

	my $script = Grades::Script->new_with_options( league => getcwd );
	my $league = League->new( id => $script->league );
	my $grades = Grades->new( league => $league );

	$league->approach->meta->apply( $grades );
	my $classworkgrades = $grades->classwork;
	my $homeworkgrades = $grades->homework;
	my $examgrades = $grades->examGrade;

=head1 DESCRIPTION

An alternative to a spreadsheet for grading students, using YAML files and scripts. The students are the players in a league ( class.) See the README and example emile league in t/emile in the distribution for the layout of the league directory in which homework, classwork and exam scores are recorded.

Grades are a collocation of Classwork, Homework and Exams roles, but the Classwork role 'delegates' its methods to one of a number of approaches, each of which has a 'total' and 'totalPercent' method. Current approaches, or forms of curriculum, include Compcomp, Groupwork and Jigsaw.

Keywords: gold stars, token economies, bean counter

=cut

=head1 ATTRIBUTES & METHODS

=cut

=head2 LEAGUE CLASS

=cut

class League {
	use YAML qw/LoadFile DumpFile/;
	use List::MoreUtils qw/any/;
	use Grades::Types qw/PlayerName PlayerNames Members/;
	use Try::Tiny;
	use Carp;

=head3 leagues

The path to the league directory.

=cut

	has 'leagues' => (is => 'ro', isa => 'Str', required => 1, lazy => 1,
	    default => '/home/drbean/022' );

=head3 id

Actually, it's a path to the league directory, below the $grades->leagues dir.

=cut

	has 'id' => (is => 'ro', isa => 'Str', required => 1);

=head3 yaml

The content of the league configuration file.

=cut

	has 'yaml' => (is => 'ro', isa => 'HashRef', lazy_build => 1);
	method _build_yaml {
			my $leaguedirs = $self->leagues;
			my $league = $self->id;
			$self->inspect( "$leaguedirs/$league/league.yaml" );
	}

=head3 name

The name of the league (class).

=cut

	has 'name' => (is => 'ro', isa => 'Str', lazy_build => 1);
	method _build_name {
		my $data = $self->yaml;
		$data->{league};
	}


=head3 field

The field of the league (class). What is the subject or description, the area of endeavor?

=cut

	has 'field' => (is => 'ro', isa => 'Str', lazy_build => 1);
	method _build_field {
		my $data = $self->yaml;
		$data->{field};
	}


=head3 approach

The style of classwork competition, eg Compcomp, or Groupwork. This is the name of the class (think OOP) to which 'classwork' and other methods are delegated.

=cut

	has 'approach' => (is => 'ro', isa => 'Str', lazy => 1,
	    default => sub { shift->yaml->{approach} } );

=head3 members

Hash refs of the players (students) in the league. The module assumes each of the members in the arrayref returned by this attribute is a hash ref containing an id and name of the member.

=cut

	has 'members', is => 'ro', isa => Members, lazy_build => 1;
	method _build_members {
		my $data = $self->yaml;
		$data->{member};
	}

=head3 session

The first week in each session, like { 1 => 1, 2 => 5, 3 => 10, 4 => 14 }, monotonically increasing week numbers.

=cut

	has 'session', (is => 'ro', isa => 'HashRef',
	    lazy => 1, default => sub { shift->yaml->{session} } );


=head3 absentees

Students who have stopped coming to class and so won't be included in classwork scoring.

=cut

	has 'absentees', (is => 'ro', isa => PlayerNames,
	    lazy => 1, default => sub { shift->yaml->{out} } );


=head3 transfer

    $oldleague = $newleague->transfer->{V9731059}

Players who have transferred to this league from some other league at some point and the leagues they transferred from.

=cut

	has 'transfer', (is => 'ro', isa => 'HashRef',
	    lazy => 1, default => sub { shift->yaml->{transfer} } );


=head3 is_member

Whether the passed id is that of a member in the league (class).

=cut

	method is_member (Str $id) {
		my $data = $self->yaml;
		any { $_->{id} eq $id } @{$data->{member}};
	}


=head3 ided

The id of the member with the given player name.

=cut

    method ided( Str $player) {
	my $members = $self->members;
	my %ids = map { $_->{id} => $_->{name} }
	    grep { $_->{name} eq $player } @$members;
	my @ids = keys %ids;
	my @names = values %ids;
	local $" = ', ';
	carp @ids . " players named @names, with ids: @ids," unless @ids==1;
	if ( @ids == 1 ) { return $ids[0] }
	else { return $ids{$player}; }  
    }

=head3 inspect

Loads a YAML file.

=cut

    method inspect (Str $file) {
	my ($warning, $data);
	try { $data = LoadFile $file }
	    catch { carp "Couldn't open $file," };
	return $data;
	}

=head3 save

Dumps a YAML file

=cut

    method save (Str $file, HashRef $data) {
	try { DumpFile $file, $data }
	    catch { warn "Couldn't save $data to $file," };
	}

}


=head2	PLAYER CLASS

=cut

class Player {
	use List::MoreUtils qw/firstval/;
	use List::Util qw/sum/;
	use POSIX;

=head3 league

The league the player is in. This is required.

=cut

	has 'league' => (is => 'ro', isa => 'League', required => 1);

=head3 id

The id of the player. This is required.

=cut

	has 'id' => (is => 'ro', isa => 'Str', required => 1);

=head3 id

The name of the player.

=cut

	has 'name' => (is => 'ro', isa => 'Str', lazy_build => 1);
	method _build_name {
		my $league = $self->league;
		my $id = $self->id;
		my $members = $league->members;
		my $member = firstval { $_->{id} eq $id } @$members;
		$member->{name};
	}

	has 'Chinese' => (is => 'ro', isa => 'Str');
}


=head2 NONENTITY CLASS

=cut 

class Nonentity extends Player {

=head3 name

The name is 'Bye'. The id is too, as a matter of fact.

=cut

    has 'name' => (is => 'ro', isa => 'Str', required => 1 );

}


=head2	GRADES CLASS

=head2 Grades' Homework Methods
=cut

role Homework {
	use YAML qw/LoadFile DumpFile/;
	use List::Util qw/min sum/;
	use Scalar::Util qw/looks_like_number/;
	use Carp;
    use Grades::Types qw/PlayerId HomeworkResult HomeworkRound HomeworkRounds
	RoundsResults/;

=head3 hwdir

The directory where the homework is.

=cut

    has 'hwdir' => (is => 'ro', isa => 'Str', lazy_build => 1);
    method _build_hwdir {
	my $league = $self->league->id;
	my $leaguedir = $self->league->leagues . "/" . $league;
	my $basename = shift->league->yaml->{hw} || "exams";
	my $hwdir = $leaguedir . '/' . $basename;
    }

=head3 rounds

An arrayref of the rounds for which there are homework grades for players in the league, in round order, of the form, [1, 3 .. 7, 9 ..].

=cut

	has 'rounds', (is => 'ro', isa => 'ArrayRef[Int]', lazy_build => 1);
	method _build_rounds {
		my $hwdir = $self->hwdir;
		my @hw = glob "$hwdir/*.yaml";
		[ sort {$a<=>$b} map m/^$hwdir\/(\d+)\.yaml$/, @hw ];
	}

=head3 roundIndex

Given a round name (ie number), returns the ordinal position in which this round was played, with the first round numbered 0. Returns undef if the round was not played.

=cut

	method roundIndex (Int $round) {
		my $rounds = $self->rounds;
		my $n = 0;
		for ( @$rounds ) {
			return $n if $_ eq $round;
			$n++;
		}
	}

=head3 roundfiles

An hashref of the files with data for the rounds for which there are homework grades for players in the league, keyed on rounds.

=cut

	has 'roundfiles', (is => 'ro', isa => 'HashRef[ArrayRef]', lazy_build => 1);
	method _build_roundfiles {
		my $hwdir = $self->hwdir;
		my @hw = glob "$hwdir/*.yaml";
		my @rounds = map m/^$hwdir\/(\d+)\.yaml$/, @hw;
		+{ map { $_ => [ glob "$hwdir/${_}*.yaml" ] } @rounds }
	}

=head3 hwbyround 

A hashref of the homework grades for players in the league for each round.

=cut

	has 'hwbyround', (is => 'ro', isa => RoundsResults, lazy_build => 1);
	method _build_hwbyround {
		my $hwdir = $self->hwdir;
		my $rounds = $self->rounds;
		my %results =
		    map { $_ => $self->inspect("$hwdir/$_.yaml") } @$rounds;
		my %grades = map { $_ => $results{$_}{grade} } @$rounds;
		return \%grades;
	}

=head3 hwMax

The highest possible score in the homework

=cut

	has 'hwMax' => (is => 'ro', isa => 'Int', lazy => 1, default =>
					sub { shift->league->yaml->{hwMax} } );

=head3 totalMax

The total maximum points that a Player could have gotten to this point in the whole season. There may be more (or fewer) rounds played than expected, so the actual top possible score returned by totalMax may be more (or less) than the figure planned.

=cut

	has 'totalMax' => (is => 'ro', isa => 'Int', lazy_build => 1);
	method _build_totalMax {
		my $rounds = $self->rounds;
		my $hwMax = $self->hwMax;
		$hwMax * @$rounds;
	}

=head3 rawscoresinRound

Given a round, returns a hashref of the raw scores for that round, keyed on the names of the exercises. These are in files in the hwdir with names of the form ^\d+[_.]\w+\.yaml$

=cut

	method rawscoresinRound (Int $round) {
		my $hwdir = $self->hwdir;
		my $files = $self->roundfiles->{$round};
		my @ex = map m/^$hwdir\/$round([_.]\w+)\.yaml$/, @$files;
		my $results = $self->inspect("$hwdir/$round.yaml");
		return { $results->{exercise} => $results->{points} };
	}

=head3 hwforid

Given a player's id, returns an array ref of the player's hw scores.

=cut

    method hwforid( PlayerId $id) {
	my $leagueId = $self->league->id;
        my $hw       = $self->hwbyround;
        my $rounds = $self->rounds;
        my @hwbyid;
        for my $round (@$rounds) {
            unless ( $hw->{$round} ) {
                warn "No homework results in Round $round in $leagueId league";
                next;
            }
            my $grade = $hw->{$round}->{$id};
	    if ( defined $grade and looks_like_number( $grade ) ) {
                push @hwbyid, $grade;
            }
            elsif ( defined $grade and $grade =~ m/transfer/i ) {
                my $oldleagueId = $self->league->transfer->{$id};
                my $league   = League->new( id => $oldleagueId );
                my $grades   = Grades->new({ league => $league });
                my $transfergrade    = $grades->hwbyround->{$round}->{$id};
                warn
"$id transfered from $oldleagueId league but no homework there in round $round"
                  unless defined $transfergrade;
                push @hwbyid, $transfergrade || 0;
            }
            else {
	warn "No homework result for $id in Round $round in $leagueId league\n";
            }
        }
        \@hwbyid;
    }

=head3 hwforidasHash

Given a player's id, returns an hashref of the player's hw grades, keyed on the rounds.

=cut

	method hwforidasHash (PlayerId  $id) {
		my $hw = $self->hwforid( $id );
		my $rounds = $self->rounds;
		my %hwbyid;
		for my $i ( 0 .. $#$rounds ) {
			my $round = $rounds->[$i];
			$hwbyid{$round} = $hw->[$i];
			if ( not defined $hw->[$i] ) { warn
				"No homework result for $id in Round $round\n";}
		}
		\%hwbyid;
	}

=head3 homework

Running total homework scores of the league.

=cut

	method homework {
		my $league = $self->league;
		my $leagueId = $league->id;
		my $players = $league->members;
		my %players = map { $_->{id} => $_ } @$players;
		my %idtotals;
		for my $player ( keys %players ) {
		    my $homework = $self->hwforid( $player );
		    my $total = sum @$homework;
		    $idtotals{$player} = $total;
		}
		+{ map { $_ => $idtotals{$_} || 0 } keys %idtotals };
	}

=head3 homeworkPercent

Running total homework scores of the league as percentages of the totalMax to that point, with a maximum of 100.

=cut

	method homeworkPercent {
		my $league = $self->league->id;
		my $totalMax = $self->totalMax;
		my $idtotals = $self->homework;
		my %percent;
		if ( $totalMax == 0 ) {
		    $percent{$_} = 0  for keys %$idtotals;
		}
		else {
		    %percent = map {
			$_ => min( 100, 100 * $idtotals->{$_} / $totalMax )
				|| 0 } keys %$idtotals;
		}
		return \%percent;
	}
}


=head2 Grades' Jigsaw Methods

The jigsaw is a cooperative learning activity where all the players in a group get different information that together produces the 'big picture', and where they are each held responsible for the understanding of each of the other individual members of this big picture.

=cut

role Jigsaw {
    use List::MoreUtils qw/any all/;
    use Try::Tiny;
    use Moose::Autobox;

=head3 jigsawdirs

The directory where the jigsaws are.

=cut

    has 'jigsawdirs' => (is => 'ro', isa => 'Str', lazy_build => 1);
    method _build_jigsawdirs {
	my $league = $self->league->id;
	my $leaguedir = $self->league->leagues . "/" . $league;
	my $basename = shift->league->yaml->{jigsaw} || "exam";
	my $jigsawdir = $leaguedir .'/' . $basename;
	}

=head3 config

The round.yaml file with data about the jigsaw activity in the given round (directory.)

=cut

    method config( Str $round) {
	my $jigsaws = $self->jigsawdirs;
        my $config;
	try { $config = $self->inspect("$jigsaws/$round/round.yaml") }
	    catch { warn "No config file for $jigsaws/$round jigsaw" };
	return $config;
    }

=head3 topic

The topic of the quiz in the given jigsaw for the given group.

=cut

    method topic ( Str $jigsaw, Str $group ) {
	my $config = $self->config('Jigsaw', $jigsaw);
	my $activity = $config->{activity};
	for my $topic ( keys %$activity ) {
	    my $forms = $activity->{$topic};
	    for my $form ( keys %$forms ) {
		my $tables = $forms->{$form};
		return $topic if any { $_ eq $group } @$tables;
	    }
	}
	return;
}

=head3 form

The form of the quiz in the given jigsaw for the given group.

=cut

    method form ( Str $jigsaw, Str $group ) {
	my $config = $self->config('Jigsaw', $jigsaw);
	my $activity = $config->{activity};
	for my $topic ( keys %$activity ) {
	    my $forms = $activity->{$topic};
	    for my $form ( keys %$forms ) {
		my $tables = $forms->{$form};
		return $form if any { $_ eq $group } @$tables;
	    }
	}
	return;
    }

=head3 quizfile

The file system location of the file with the quiz questions and answers for the given jigsaw.

=cut

    method quizfile ( Str $jigsaw ) {
	my $config = $self->config('Jigsaw', $jigsaw);
	return $config->{text};
    }

=head3 quiz

The quiz questions (as an anon array) in the given jigsaw for the given group.

=cut

    method quiz ( Str $jigsaw, Str $group ) {
	my $quizfile = $self->quizfile($jigsaw);
	my $activity;
	try { $activity = $self->inspect( $quizfile ) }
	    catch { warn "No $quizfile jigsaw content file" };
	my $topic = $self->topic( $jigsaw, $group );
	my $form = $self->form( $jigsaw, $group );
	my $quiz = $activity->{$topic}->{jigsaw}->{$form}->{quiz};
    }

=head3 options

    $grades->options( '2/1', 'Purple', 0 ) # [ qw/Deborah Don Dovonna Sue/ ]

The options (as an anon array) to the given question in the given jigsaw for the given group.

=cut

    method options ( Str $jigsaw, Str $group, Int $question ) {
	my $quiz = $self->quiz( $jigsaw, $group );
	my $options = $quiz->[$question]->{option};
	return $options || '';
    }

=head3 qn

The number of questions in the given jigsaw for the given group.

=cut

    method qn ( Str $jigsaw, Str $group ) {
	my $quiz = $self->quiz( $jigsaw, $group );
	warn "No quiz for $group group in jigsaw $jigsaw," unless $quiz;
	return scalar @$quiz;
    }

=head3 responses

The responses of the members of the given group in the given jigsaw (as an anon hash keyed on the ids of the members). In a file in the jigsaw directory called 'response.yaml'.

=cut


    method responses ( Str $jigsaw, Str $group ) {
	my $jigsaws = $self->jigsawdirs;
	my $responses = $self->inspect( "$jigsaws/$jigsaw/response.yaml" );
	return $responses->{$group};
    }

=head3 jigsawGroups

A hash ref of all the groups in the given jigsaw and the names of members of the groups, keyed on groupnames. There may be duplicated names if one player did the activity twice as an 'assistant' for a group with not enough players, and missing names if a player did not do the quiz.

=cut

	method jigsawGroups (Str $jigsaw ) {
		my $config = $self->config('Jigsaw', $jigsaw );
		$config->{group};
	}

=head3 jigsawGroupMembers

An array (was hash ref) of the names of the members of the given group in the given jigsaw, in order of the roles, A..D.

=cut

	method jigsawGroupMembers (Str $jigsaw, Str $group) {
		my $groups = $self->jigsawGroups( $jigsaw );
		my $members = $groups->{$group};
	}

=head3 roles

At the moment, just A .. D.

=cut

	has 'roles' => (is => 'ro', isa => 'ArrayRef[Str]',
	    default => sub { [ qw/A B C D/ ] } );


=head3 idsbyRole

Ids in array, in A-D role order

=cut


    method idsbyRole ( Str $jigsaw, Str $group ) {
	my $members = $self->league->members;
	my %namedMembers = map { $_->{name} => $_ } @$members;
	my $namesbyRole = $self->jigsawGroupMembers( $jigsaw, $group );
	my @idsbyRole = map { $namedMembers{$_}->{id} } @$namesbyRole;
	return \@idsbyRole;
    }

=head3 assistants

A array ref of all the players in the (sub)jigsaw who did the the activity twice to 'assist' groups with not enough (or absent) players, or individuals with no groups, or people who arrived late.

=cut

	method assistants (Str $jigsaw) {
		my $round = $self->config( $jigsaw );
		$round->{assistants};
	}

=head3 jigsawGroupRole

An hash ref of the roles of the members of the given group in the given jigsaw, keyed on the name of the player.

=cut

	method jigsawGroupRole (Str $jigsaw, Str $group) {
		my $members = $self->jigsawGroupMembers( $jigsaw, $group );
		my %roles;
		@roles{ @$members } = $self->roles->flatten;
		return \%roles;
	}

=head3 id2jigsawGroupRole

An hash ref of the roles of the members of the given group in the given jigsaw, keyed on the id of the player.

=cut

	method id2jigsawGroupRole (Str $jigsaw, Str $group) {
		my $members = $self->jigsawGroupMembers( $jigsaw, $group );
		my @ids = map { $self->league->ided($_) } @$members;
		my $roles = $self->roles;
		my %id2role; @id2role{@ids} = @$roles;
		return \%id2role;
	}

=head3 name2jigsawGroup

An array ref of the group(s) to which the given name belonged in the given jigsaw. Normally, the array ref has only one element. But if the player was an assistant an array ref of more than one group is returned. If the player did not do the jigsaw, no groups are returned.

=cut

	method name2jigsawGroup (Str $jigsaw, Str $name) {
		my $groups = $self->jigsawGroups( $jigsaw );
		my @memberships;
		for my $id ( keys %$groups ) {
			my $group = $groups->{$id};
			push @memberships, $id if any { $_ eq $name } @$group;
		}
		return \@memberships;
	}

=head3 rawJigsawScores

The individual scores on the given quiz of each member of the given group, keyed on their roles, no, ids, from the file called 'scores.yaml' in the given jigsaw dir. If the scores in that file have a key which is a role, handle that, but, yes, the keys of the hashref returned here are the players' ids.

=cut

    method rawJigsawScores (Str $round, Str $group) {
        my $data;
	my $jigsaws = $self->jigsawdirs;
	try { $data = $self->inspect( "$jigsaws/$round/scores.yaml"); }
	    catch { warn "No scores for $group group in jigsaw $round."; };
	my $groupdata = $data->{letters}->{$group};
	my $ids       = $self->idsbyRole( $round, $group );
	my $roles     = $self->roles;
	my @keys;
	if (
	    any { my $key = $_; any { $_ eq $key } @$roles; } keys %$groupdata
	) {
	    @keys = @$roles;
	}
        else {
            @keys = grep { my $id = $_; any { $_ eq $id } @$ids }
		    keys %$groupdata;
        }
        my %scores;
	@scores{@keys} = @{$groupdata}{@keys};
	return \%scores;
    }

=head3 chinese

The number of times Chinese was used in the given round by all the groups. If there is no record of Chinese use, returns values of 0.

=cut

    method chinese (Str $round) {
        my $data;
	my $jigsaws = $self->jigsawdirs;
	try { $data = $self->inspect( "$jigsaws/$round/scores.yaml"); }
	    catch { warn "No scores in jigsaw $round."; };
	my $chinese = $data->{Chinese};
	my $groups = $self->jigsawGroups( $round );
	$chinese->{ $_ } ||= 0 for keys %$groups;
	return $chinese;
    }

=head3 jigsawDeduction

Points deducted for undesirable performance elements (ie Chinese use) on the quiz of the given group in the given exam.

=cut

    method jigsawDeduction (Str $jigsaw, Str $group) {
	my $data;
	my $jigsaws = $self->jigsawdirs;
	try { $data = $self->inspect( "$jigsaws/$jigsaw/scores.yaml" ); }
	    catch { warn
		"Deductions for $group group in $jigsaw jigsaw?" };
	my $demerits = $data->{Chinese}->{$group};
	return $demerits;
    }

}


=head2 Grades' Classwork Methods

Classwork is work done in class with everyone and the teacher present. Two classwork approaches are Compcomp and Groupwork. Others are possible. Depending on the league's approach accessor, the methods are delegated to the appropriate Approach object.

=cut

class Classwork {
	use Grades::Types qw/Results/;

=head3 approach

Delegatee handling classwork_total, classworkPercent

=cut

    has 'approach' => ( is => 'ro', isa => 'Approach', required => 1,
	    handles => [ qw/
		series beancans
		all_events points
		classwork_total classworkPercent / ] );

}

=head2 Classwork Approach

Handles Classwork's classwork_total and classworkPercent methods. Calls the total or totalPercent methods of the class whose name is in the 'type' accessor.

=cut

class Approach {

=head3 league

The league (object) whose approach this is.

=cut

    has 'league' => (is =>'ro', isa => 'League', required => 1,
				handles => [ 'inspect' ] );

=head3 groupworkdirs

The directory under which there are subdirectories containing data for the group/pair-work sessions. Look first in 'groupwork', then 'compcomp' mappings, else use 'classwork' dir.

=cut

    has 'groupworkdirs' => (is => 'ro', isa => 'Str', lazy_build => 1);
    method _build_groupworkdirs {
	my $league = $self->league;
	my $id = $league->id;
	my $leaguedir = $self->league->leagues . "/" . $id;
	my $basename = $league->yaml->{groupwork} ||
			$league->yaml->{compcomp} || "classwork";
	my $groupworkdirs = $leaguedir .'/' . $basename;
	}

=head3 series

The sessions (weeks) over the series (semester) in each of which there was a different grouping and results of players. This method returns an arrayref of the names (numbers) of the sessions, in numerical order, of the form, [1, 3 .. 7, 9, 10 .. 99 ]. Results are in sub directories of the same name, under groupworkdirs.

=cut

    has 'series' =>
      ( is => 'ro', isa => 'Maybe[ArrayRef[Int]]', lazy_build => 1 );
    method _build_series {
        my $dir = $self->groupworkdirs;
        my @subdirs = grep { -d } glob "$dir/*";
        [ sort { $a <=> $b } map m/^$dir\/(\d+)$/, @subdirs ];
    }

#=head3 all_events
#
#All the weeks, or sessions or lessons for which grade data is being assembled from for the grade component.
#
#=cut
#
#    method all_events {
#	my $league = $self->league;
#	my $type = $league->approach;
#	my $meta = $type->meta;
#	my $total = $type->new( league => $league )->all_events;
#    }
#
#=head3 points
#
#Week-by-weeks, or session scores for the individual players in the league.
#
#=cut
#
#    method points (Str $week) {
#	my $league = $self->league;
#	my $type = $league->approach;
#	my $meta = $type->meta;
#	my $total = $type->new( league => $league )->points( $week );
#    }
#
#=head3 classwork_total
#
#Calls the pluginned approach's classwork_total.
#
#=cut
#
#    method classwork_total {
#	my $league = $self->league;
#	my $type = $league->approach;
#	my $total = $type->new( league => $league )->total;
#    }
#
=head3 classworkPercent

Calls the pluginned approach's classworkPercent.

=cut

    method classworkPercent {
	my $league = $self->league;
	my $type = $league->approach;
	my $total = $type->new( league => $league )->totalPercent;
    }
}


=head2 Grades' Compcomp Methods

The comprehension question competition is a Swiss tournament regulated 2-partner conversation competition where players try to understand more of their opponent's information than their partners understand of theirs.

=cut

class Compcomp extends Approach {
    use Try::Tiny;
    use Moose::Autobox;
    use List::Util qw/max min/;
    use List::MoreUtils qw/any all/;
    use Carp qw/carp/;
    use Grades::Types qw/Results/;

=head3 compcompdirs

The directory under which there are subdirectories containing data for the Compcomp rounds.

=cut

    has 'compcompdirs' => (is => 'ro', isa => 'Str', lazy_build => 1 );
    method _build_compcompdirs { 
	my $leaguedir = $self->league->leagues . "/" . $self->league->id;
	my $compcompdir = $leaguedir .'/' . shift->league->yaml->{compcomp};
    }

=head3 all_events

The pair conversations over the series (semester). This method returns an arrayref of the numbers of the conversations, in numerical order, of the form, [1, 3 .. 7, 9, 10 .. 99 ]. Results are in sub directories of the same name, under compcompdirs.

=cut

    has 'all_events' =>
      ( is => 'ro', isa => 'Maybe[ArrayRef[Int]]', lazy_build => 1 );
    method _build_all_events {
        my $dir = $self->compcompdirs;
        my @subdirs = grep { -d } glob "$dir/*";
        [ sort { $a <=> $b } map m/^$dir\/(\d+)$/, @subdirs ];
    }

=head3 config

The round.yaml file with data about the Compcomp activity for the given conversation (directory.)

=cut

    method config( Str $round) {
	my $comp = $self->compcompdirs;
	my $file = "$comp/$round/round.yaml";
        my $config;
	try { $config = $self->inspect($file) }
	    catch { warn "No config file for Compcomp round $round at $file" };
	return $config;
    }

=head3 activities

The activities which individual tables did in the given round. Keys are topics, keyed are forms. These, in turn, are keys of tables doing those topics and those forms.

=cut

    method activities( Str $round ) {
	my $config = $self->config( $round );
	return $config->{activity};
    }

=head3 tables

The tables with players according to their roles for the given round, as an hash ref. In the 'group' or 'activities' mapping in the config file. Make sure each table has a unique table number. Some code here is same as in Swiss's round_table.pl and dblineup.rc.

activities:
  drbean:
    1:
      - U9931007
      - U9933022
  novak:
    1:
      - U9931028
      - U9933045

=cut

    method tables ( Str $round ) {
	my $config = $self->config($round);
	my (@pairs, %pairs, @dupes, $wantlist);
	my $groups = $config->{group};
	return $groups if $groups;
	my $activities = $config->{activity};
	for my $key ( keys %$activities ) {
	    my $topic = $activities->{$key};
	    for my $form ( keys %$topic ) {
		my $pairs = $topic->{$form};
		if ( ref( $pairs ) eq 'ARRAY' ) {
		    $wantlist = 1;
		    for my $pair ( @$pairs ) {
		    my @players = values %$pair;
		    my @roles = keys %$pair;
		    push @pairs, $pair unless
			any { my @previous = values %$_;
			    any { my $player=$_;
				any { $player eq $_ } @previous
			    } @players
			} @pairs;
		    }
		}
		else {
		    for my $n ( keys %$pairs ) {
			my $pair = $pairs->{$n};
			my @twoplayers = values %$pair;
			die "Table number $n with players @twoplayers is dupe" if
			    exists $pairs{$n} or
			    any { my $player = $_; any { $player eq $_ } @dupes
				} @twoplayers;
			push @dupes, @twoplayers;
			$pairs{ $n } = $pair;
		    }
		}
	    }
	}
	return \@pairs if $wantlist;
	return \%pairs;
    }

=head3 pair2table

A player and opponent mapped to a table number.

=cut

    method pair2table ( Str $player, Str $opponent, Str $round ) {
	my $table = $self->tables( $round );
	for my $n ( keys %$table ) {
	    my $table = $table->{$n};
	    my @pair = values %$table;
	    if ( any { $_ eq $player } @pair ) {
		if ( any { $_ eq $opponent } @pair ) {
		    return { $n => $table };
		}
	    }
	}
	die "No table with player $player, opponent $opponent in round $round";
    }

=head3 compQuizfile

The file system location of the file with the quiz questions and answers for the given Compcomp activity.

=cut

    method compQuizfile ( Str $round ) {
	my $config = $self->config($round);
	my $text = $config->{text};
	return $self->compcompdirs . "/../" . $text;
    }

=head3 topicNames

Returns the names of comp quiz topics as an arrayref.

=cut

    method topicNames ( Str $round ) {
	my $config = $self->config($round);
	my $activities = $config->{activity};
	my @topics = keys %$activities;
	return \@topics;
    }

=head3 compQuizAttempted

Returns the comp quiz topics and their associated forms attempted by the given group in the round, as an arrayref of hashrefs keyed on 'topic' and 'form'.

=cut

    method compQuizAttempted ( Str $round, Str $table ) {
	my $config = $self->config($round);
	my $activities = $config->{activity};
	my $selection = $self->compQuizSelection;
	my $attempted;
	for my $topic ( keys %$selection ) {
	    my $forms = $selection->{$topic};
	    for my $form ( keys %$forms ) {
		my $tables = $activities->{$topic}->{$form};
		push @$attempted, { topic => $topic, form => $form }
		    if any { $table == $_ } @$tables;
	    }
	}
	return $attempted;
    }

=head3 compQuiz

The compQuiz questions (as an anon array) in the given Compcomp activity for the given table.

=cut

    method compQuiz ( Str $round, Str $table ) {
	my $quizfile = $self->compQuizfile($round);
	my $activity;
	try { $activity = $self->inspect( $quizfile ) }
	    catch { warn "No $quizfile Compcomp content file" };
	my $topic = $self->compTopic( $round, $table );
	my $form = $self->compForm( $round, $table );
	my $quiz = $activity->{$topic}->{compcomp}->{$form}->{quiz};
	carp "No $topic, $form quiz in $quizfile," unless $quiz;
	return $quiz;
    }

=head3 compTopic

The topic of the quiz in the given Compcomp round for the given table. Each table has one and only one quiz.

=cut

    method compTopic ( Str $round, Str $table ) {
	my $config = $self->config($round);
	my $activity = $config->{activity};
	for my $topic ( keys %$activity ) {
	    my $forms = $activity->{$topic};
	    for my $form ( keys %$forms ) {
		my $tables = $forms->{$form};
		return $topic if any { $_ eq $table } @$tables;
	    }
	}
	carp "Topic? No quiz at table $table in round $round,";
	return;
    }

=head3 compTopics

The topics of the quiz in the given Compcomp round for the given table, as an array ref.

=cut

    method compTopics ( Str $round, Str $table ) {
	my $config = $self->config($round);
	my $activity = $config->{activity};
	my %topics;
	for my $topic ( keys %$activity ) {
	    my $forms = $activity->{$topic};
	    for my $form ( keys %$forms ) {
		my $tables = $forms->{$form};
		$topics{ $topic } += 1 if any { $_ eq $table } @$tables;
	    }
	}
	carp "Topic? No quiz at table $table in round $round," unless %topics;
	my @topics = keys %topics;
	return \@topics;
    }

=head3 compForm

The form of the quiz in the given Compcomp round for the given table. Each table has one and only one quiz.

=cut

    method compForm ( Str $round, Str $table ) {
	my $config = $self->config($round);
	my $activity = $config->{activity};
	for my $topic ( keys %$activity ) {
	    my $forms = $activity->{$topic};
	    for my $form ( keys %$forms ) {
		my $tables = $forms->{$form};
		return $form if any { $_ eq $table } @$tables;
	    }
	}
	carp "Form? No quiz at table $table in round $round,";
	return;
    }

=head3 compForms

The forms in the given Compcomp round for the given table, in the given quiz (topic), as an array ref.

=cut

    method compForms ( Str $round, Str $table, Str $topic ) {
	my $config = $self->config($round);
	my $activity = $config->{activity};
	my $forms = $activity->{$topic};
	my @forms;
	for my $form ( keys %$forms ) {
	    my $tables = $forms->{$form};
	    push @forms, $form if any { $_ eq $table } @$tables;
	}
	carp "Form? No quiz at table $table in round $round," unless @forms;
	return \@forms;
    }

=head3 compqn

The number of questions in the given Compcomp quiz for the given pair.

=cut

    method compqn ( Str $round, Str $table ) {
	my $quiz = $self->compQuiz( $round, $table );
	return scalar @$quiz;
    }

=head3 idsbyCompRole

Ids in array, in White, Black role order

=cut


    method idsbyCompRole ( Str $round, Str $table ) {
	my $members = $self->league->members;
	my %namedMembers = map { $_->{name} => $_ } @$members;
	my $config = $self->config( $round );
	my $pair = $config->{group}->{$table};
	my @idsbyRole = @$pair{qw/White Black/};
	return \@idsbyRole;
    }

=head3 scores

The scores at the tables of the tournament in the given round (as an anon hash keyed on the ids of the members). In a file in the Compcomp round directory called 'result.yaml'.

=cut


    method scores ( Str $round ) {
	my $comp = $self->compcompdirs;
	my $file = "$comp/$round/scores.yaml";
	my $results = $self->inspect( $file );
	return $results;
    }

=head3 compResponses

The responses of the members of the given pair in the given round (as an anon hash keyed on the ids of the members). In a file in the Compcomp round directory called 'response.yaml'.

=cut


    method compResponses ( Str $round, Str $table ) {
	my $comp = $self->compcompdirs;
	my $file = "$comp/$round/response.yaml";
	my $responses = $self->inspect( $file );
	return { free => $responses->{free}->{$table},
		 set => $responses->{set}->{$table} };
    }

=head3 freeTotals

The number of free questions each asked by White and Black.

=cut


    method freeTotals ( Str $round, Str $table ) {
	my $response = $self->compResponses( $round, $table );
	my $player = $self->idsbyCompRole( $round, $table );
	my $topics = $self->compTopics( $round, $table );
	my @qn = (0,0);
	for my $topic ( @$topics ) {
	    my $forms = $self->compForms( $round, $table, $topic );
	    for my $form ( @$forms ) {
		for my $n ( 0,1 ) {
		    my $points =
			$response->{free}->{$topic}->{$form}->{$player->[$n]}->{point};
		    $qn[$n] += max ( grep { $points->{$_} ne 'Nil' } 
				    keys %$points ) || 0;
		}
	    }
	}
	return \@qn;
    }
		
=head3 lowerFreeTotal

The lesser of the 2 numbers of free questions asked by either White and Black.

=cut

    method lowerFreeTotal ( Str $round, Str $table ) {
	my $totals = $self->freeTotals( $round, $table );
	return min @$totals;
    }
		
=head3 byer

The id of the player with the Bye, or the empty string.

=cut

    method byer ( Str $round ) {
	my $config = $self->config( $round );
	my $byer = $config->{bye};
	return $byer if $byer;
	return '';
    }


=head3 transfer

An array ref of the ids of the players who were playing in another league in the round, or the empty string.

=cut

    method transfer ( Str $round ) {
	my $config = $self->config( $round );
	my $transfers = $config->{transfer} || '';
	return $transfers;
    }


=head3 opponents

The ids of opponents of the players in the given conversation.

=cut

    method opponents ( Str $round ) {
	my $tables = $self->tables( $round );
	my %opponent;
	for my $n ( keys %$tables ) {
	    $opponent{$tables->{$n}->{White}} = $tables->{$n}->{Black};
	    $opponent{$tables->{$n}->{Black}} = $tables->{$n}->{White};
	}
	my $byer = $self->byer( $round );
	$opponent{ $byer } = 'bye' if $byer;
	my $transfers = $self->transfer( $round );
	@opponent{ @$transfers } = ( 'transfer' ) x @$transfers
	   if ( $transfers and ref( $transfers ) eq 'ARRAY' );
	my $league = $self->league;
	my $members = $league->members;
	$opponent{$_->{id}} ||= 'unpaired' for @$members;
	return \%opponent;
    }


=head3 correct

The number of questions correct in the given conversation.

=cut

    method correct ( Str $round ) {
	my $comp = $self->compcompdirs;
	my $file = "$comp/$round/scores.yaml";
	my $tables = $self->inspect( $file );
	my %correct;
	for my $table ( keys %$tables ) {
	    my $scores = $tables->{$table};
	    @correct{keys %$scores} = values %$scores;
	}
	return \%correct;
    }


=head3 assistantPoints

Assistants points are from config->{assistant} of form { Black => { U9933002 => 3, U9933007 => 4}, Yellow => { U9931007 => 4, U9933022 => 4 } }, and are the points for examiners with other responsibilities who are not participating in the round.

=cut

    method assistantPoints ( Str $round ) {
	my $config = $self->config( $round );
	my $assistants = $config->{assistant};
	if ( $assistants ) {
	    my %assistantPoints = map { %{ $assistants->{$_} } } keys %$assistants;
	     # my %assistantPoints = map { $assistants->{$_}->flatten } keys %$assistants;
	     die "@{ [keys %$assistants] }: assistant member mistakes." if any
		{ not $self->league->is_member($_) } keys %assistantPoints;
	    return \%assistantPoints;
	}
    }

=head3 dispensation

Dispensation points are from config->{dispensation} of same form as assistantPoints, { Black => { U9933002 => 3, U9933007 => 4}, Yellow => { U9931007 => 4, U9933022 => 4 } }.

=cut

    method dispensation ( Str $round ) {
	my $config = $self->config( $round );
	my $dispensation = $config->{dispensation};
	if ( $dispensation ) {
	    my %dispensation = map { %{ $dispensation->{$_} } } keys %$dispensation;
	     # my %assistantPoints = map { $assistants->{$_}->flatten } keys %$assistants;
	     die "@{ [keys %$dispensation] }: members?" if any
		{ not $self->league->is_member($_) } keys %dispensation;
	    return \%dispensation;
	}
    }

=head3 payout

If payprotocol field is 'meritPay', 1 question each: 0,1 or 2 pts. 2 question each: 1,2 or 3 pts. 3 question each: 2,3 or 4 pts. 4 question each: 3,4 or 5 pts. 

If the 'meritPay' payprotocol field ends in a number the specified number of questions each is required for the maximum points.
=cut

    method payout ( Str $player, Str $opponent, Str $round ) {
	my $protocol = $self->config($round)->{payprotocol};
	my ($loss, $draw, $win) = (3,4,5);
	if ( defined $protocol and $protocol =~ m/^meritPay/ ) {
	    (my $top_number = $protocol ) =~ s/^\D*(\d*)$/$1/;
	    my $required = $top_number? $top_number: 4;
	    my $table = $self->pair2table( $player, $opponent, $round );
	    my $tableN = (keys %$table)[0];
	    my $questionN = $self->lowerFreeTotal( $round, $tableN );
	    my $unfulfilled = $required - $questionN;
	    if ( $unfulfilled > 0 ) {
		$_ -= $unfulfilled for ($loss, $draw, $win);
		if ( $loss < 0 ) {
		    $loss = 0; $draw = 0; $win = 1;
		}
	    }
	}
	return { loss => $loss, draw => $draw, win => $win };
    }


=head3 points

The points of the players in the given conversation. 5 for a Bye, 1 for Late, 0 for Unpaired, 1 for a non-numerical number correct result, 5 for more correct, 3 for less correct, 4 for the same number correct. Transfers' results are computed from their results in the same round in their old league. Assistants points are from round.yaml, points for non-paired helpers.

=cut

    method points ( Str $round ) {
	my $config = $self->config( $round );
	my $opponents = $self->opponents( $round );
	my $correct = $self->correct( $round );
	my $points;
	my $late; $late = $config->{late} if exists $config->{late};
	my $forfeit; $forfeit = $config->{forfeit} if exists $config->{forfeit};
	my $assists = $self->assistantPoints( $round );
	my $dispensed = $self->dispensation( $round );
	my $byer = $self->byer( $round );
	PLAYER: for my $player ( keys %$opponents ) {
	    if ( defined $assists and any { $_ eq $player } keys %$assists){
		$points->{$player} = $assists->{$player};
		next PLAYER;
	    }
	    if ( defined $dispensed and any { $_ eq $player } keys %$dispensed){
		$points->{$player} = $dispensed->{$player};
		next PLAYER;
	    }
	    if ( any { defined } @$forfeit and any { $_ eq $player } @$forfeit){
		$points->{$player} = 0;
		next PLAYER;
	    }
	    if ( any { defined } @$late and any { $_ eq $player } @$late ) {
		$points->{$player} = 1;
		next PLAYER;
	    }
	    if ( $byer and $player eq $byer ) {
		$points->{$player} = 5;
		next PLAYER;
	    }
	    if ( $opponents->{$player} =~ m/unpaired/i ) {
		$points->{$player} = 0;
		next PLAYER;
	    }
	    if ( $opponents->{$player} =~ m/transfer/i ) {
		my $oldleagueId = $self->league->transfer->{$player};
		my $oldleague = League->new( id => $oldleagueId );
		my $oldgrades = Grades->new({ league => $oldleague });
		my $oldclasswork = $oldgrades->classwork;
		$points->{$player} = $oldclasswork->points($round)->{$player};
		next PLAYER;
	    }
	    my $other = $opponents->{$player};
	    my $alterego = $opponents->{$other};
	    die
"${player}'s opponent is $other, but ${other}'s opponent is $alterego"
		unless $other and $alterego and $player eq $alterego;
	    die "No $player quiz card in round $round?" unless exists
		$correct->{$player};
	    my $ourcorrect = $correct->{$player};
	    die "No $other card against $player in round $round?" unless
		exists $correct->{$other};
	    my $theircorrect = $correct->{$other};
	    if ( not defined $ourcorrect ) {
		$points->{$player} = 0;
		next PLAYER;
	    }
	    if ( $correct->{$player} !~ m/^\d+$/ ) {
		$points->{$player} = 1;
		next PLAYER;
	    }
	    if ( any { defined } @$forfeit and any { $_ eq $other } @$forfeit) {
		$points->{$player} = 5;
		next PLAYER;
	    }
	    my $grade = $self->payout( $player, $other, $round );
	    $points->{$player} = $ourcorrect > $theircorrect? $grade->{win}:
		$ourcorrect < $theircorrect? $grade->{loss}: $grade->{draw};
	}
	return $points;
    }


=head3 total

The total over the conversations over the series.

=cut

    has 'total' => ( is => 'ro', isa => Results, lazy_build => 1 );
    method _build_total {
	my $rounds = $self->all_events;
	my $members = $self->league->members;
	my @ids = map { $_->{id} } @$members;
	my $totals;
	@$totals{ @ids } = (0) x @ids;
	for my $round ( @$rounds ) {
	    my $points = $self->points( $round );
	    for my $id ( @ids ) {
		    next unless defined $points->{$id};
		$totals->{$id} += $points->{$id};
	    }
	}
	return $totals;
    }


=head3 totalPercent

The total over the conversations over the series expressed as a percentage of the possible score. The average should be 80 percent if every player participates in every comp.

=cut

    has 'totalPercent' => ( is => 'ro', isa => Results, lazy_build => 1 );
    method _build_totalPercent {
	my $rounds = $self->all_events;
	my $n = scalar @$rounds;
	my $totals = $self->total;
	my %percentages = $n? 
	    map { $_ => $totals->{$_} * 100 / (5*$n) } keys %$totals:
	    map { $_ => 0 } keys %$totals;
	return \%percentages;
    }

}


=head2 Grades' Exams Methods
=cut

role Exams {
	use List::Util qw/max sum/;
	use List::MoreUtils qw/any all/;
	use Carp;
	use Grades::Types qw/Exam/;

=head3 examdirs

The directory where the exams are.

=cut

    has 'examdirs' => (is => 'ro', isa => 'Str', lazy_build => 1);
    method _build_examdirs {
	my $league = $self->league->id;
	my $leaguedir = $self->league->leagues . "/" . $league;
	my $basename = $self->league->yaml->{jigsaw} ||
			$self->league->yaml->{exams} || "exams";
	my $examdirs = $leaguedir .'/' . $basename;
    }

=head3 examids

An arrayref of the ids of the exams for which there are grades for players in the league, in numerical order, of the form, [1, 3 .. 7, 9, 10 .. 99 ]. Results are in sub directories of the same name, under examdir.

=cut

    has 'examids',
      ( is => 'ro', isa => 'Maybe[ArrayRef[Int]]', lazy_build => 1 );
    method _build_examids {
        my $examdirs = $self->examdirs;
        my @exams   = grep { -d } glob "$examdirs/[0-9] $examdirs/[1-9][0-9]";
        [ sort { $a <=> $b } map m/^$examdirs\/(\d+)$/, @exams ];
    }

=head3 examrounds

The rounds over which the given exam was conducted. Should be an array ref. If there were no rounds, ie the exam was conducted in one round, a null anonymous array is returned. The results for the rounds are in sub directories underneath the 'examid' directory named, in numerical order, 1 .. 99.

=cut

    method examrounds( Str $exam ) {
	my $examdirs = $self->examdirs;
        my $examids = $self->examids;
        carp "No exam $exam in exams @$examids"
	    unless any { $_ eq $exam } @$examids;
        my @rounds = glob "$examdirs/$exam/[0-9] $examdirs/$exam/[0-9][0-9]";
        [ sort { $a <=> $b } map m/^$examdirs\/$exam\/(\d+)$/, @rounds ];
      }

=head3 examMax

The maximum score possible in each individual exam. That is, what the exam is out of.

=cut

	has 'examMax' => (is => 'ro', isa => 'Int', lazy => 1, required => 1,
			default => sub { shift->league->yaml->{examMax} } );

=head3 exam

    $grades->exam($id)

The scores of the players on an individual (round of an) exam (in a 'g.yaml file in the $id subdir of the league dir.

=cut

	method exam ( Str $id ) {
	    my $examdirs = $self->examdirs;
	    my $exam = $self->inspect( "$examdirs/$id/g.yaml" );
	    if ( is_Exam($exam) ) {
		return $exam ;
	    }
	    else {
		croak
"Exam $id probably has undefined or non-numeric Exam scores, or possibly illegal PlayerIds." ;
	    }
	}

=head3 examResults

A hash ref of the ids of the players and arrays of their results over the exam series, ie examids, in files named 'g.yaml', TODO but only if such a file exists in all examdirs. Otherwise, calculate from raw 'response.yaml' files. Croak if any result is larger than examMax.

=cut

    has 'examResults' => ( is => 'ro', isa => 'HashRef', lazy_build => 1 );
    method _build_examResults {
        my $examids = $self->examids;
	my $members = $self->league->members;
	my @playerids = map { $_->{id} } @$members;
	my %results;
	for my $id  ( @$examids ) {
	    my $exam    = $self->exam( $id );
	    my $max      = $self->examMax;
	    for my $playerid ( @playerids ) {
		my $result = $exam->{$playerid};
		carp "No exam $id results for $playerid,"
		  unless defined $result;
		croak "${playerid}'s $result greater than exam max, $max"
		  if defined $result and $result > $max;
		my $results = $results{$playerid};
		push @$results, $result;
		$results{$playerid} = $results;
	    }
	}
	return \%results;
    }

=head3 examResultHash

A hash ref of the ids of the players and hashrefs of their results for each exam. Croak if any result is larger than examMax.

=cut

	has 'examResultHash' => (is => 'ro', isa => 'HashRef', lazy_build => 1);
	method _build_examResultHash {
		my $examids = $self->examids;
		my $examResults = $self->examResults;
		my %examResults;
		for my $id ( keys %$examResults ) {
			my $results = $examResults->{$id};
			my %results;
			@results{@$examids} = @$results;
			$examResults{$id} = \%results;
		}
		return \%examResults;
	}

=head3 examResultsasPercent

A hashref of the ids of the players and arrays of their results over the exams expressed as percentages of the maximum possible score for the exams.

=cut

	has 'examResultsasPercent' => (is=>'ro', isa=>'HashRef', lazy_build=>1);
	method _build_examResultsasPercent {
		my $scores = $self->examResults;
		my @ids = keys %$scores;
		my $max = $self->examMax;
		my %percent =  map { my $id = $_; my $myscores = $scores->{$id};
		    $id => [ map { ($_||0) * (100/$max) } @$myscores ] } @ids;
		return \%percent;
	}

=head3 examGrade

A hash ref of the ids of the players and their total scores on exams.

=cut

	has 'examGrade' => (is => 'ro', isa => 'HashRef', lazy_build => 1);
	method _build_examGrade {
		my $grades = $self->examResults;
		+{ map { my $numbers=$grades->{$_};
			$_ => sum(@$numbers) }
					keys %$grades };
	}

=head3 examPercent

A hash ref of the ids of the players and their total score on exams, expressed as a percentage of the possible exam score. This is the average of their exam scores.

=cut

    has 'examPercent' => (is => 'ro', isa => 'HashRef', lazy_build => 1);
    method _build_examPercent {
	my $grades = $self->examResultsasPercent;
	my %totals = map {
		my $numbers=$grades->{$_};
		$_ => sum(@$numbers)/@{$numbers} } keys %$grades;
	return \%totals;
    }

}


=head2 Grades' Core Methods

=cut

class Grades with Homework with Exams with Jigsaw

{
#    with 'Jigsaw'
#	=> { -alias => { config => 'jigsaw_config' }, -excludes => 'config' };
    require Grades::Groupwork;
    use Carp;
    use Grades::Types qw/Weights/;

=head3 BUILDARGS

Have Moose find out the classwork approach the league has adopted and create an object of that approach for the classwork accessor. This is preferable to requiring the user to create the object and pass it at construction time.

=cut

    around BUILDARGS (ClassName $class: HashRef $args) {
        my $league = $args->{league} or die "$args->{league} league?";
        my $approach = $league->approach or die "approach?";
        my $classwork = $approach->new( league => $league ) or die "classwork?";
        $args->{classwork} = $classwork;
        return $class->$orig({ league => $league, classwork => $classwork });
    }
    # around BUILDARGS(@args) { $self->$orig(@args) }

=head3 classwork

An accessor for the object that handles classwork methods. Required at construction time.

=cut

	has 'classwork' => ( is => 'ro', isa => 'Approach', required => 1,
		handles => [ 'series', 'beancans',
			    'points', 'all_events',
		    'classwork_total', 'classworkPercent' ] );

=head3 config

The possible grades config files. Including Jigsaw, Compcomp.

=cut

	method config ( $role, $round ) {
	    my $config = "${role}::config"; $self->$config( $round );
	}

=head3 league

The league (object) whose grades these are.

=cut

	has 'league' => (is =>'ro', isa => 'League', required => 1,
				handles => [ 'inspect' ] );

=head3 weights

An hash ref of the weights (expressed as a percentage) accorded to the three components, classwork, homework, and exams in the final grade.

=cut

	has 'weights' => (is => 'ro', isa => Weights, lazy_build => 1 );
	method _build_weights { my $weights = $self->league->yaml->{weights}; }


=head3 sprintround

sprintf( '%.0f', $number). sprintf warns if $number is undef.

=cut

	method sprintround (Maybe[Num] $number) {
		sprintf '%.0f', $number;
	}

=head3 grades

A hashref of student ids and final grades.

=cut

	method grades {
		my $league = $self->league;
		my $members = $league->members;
		my $homework = $self->homeworkPercent;
		my $classcomponent = $league->approach;
		my $classwork = $self->classworkPercent;
		my $exams = $self->examPercent;
		my @ids = map { $_->{id} } @$members;
		my $weights = $self->weights;
		my %grades = map { $_ => $self->sprintround(
			$classwork->{$_} * $weights->{classwork} /100 +
			$homework->{$_} * $weights->{homework} /100 +
			$exams->{$_}    * $weights->{exams} /100 )
				} @ids;
		\%grades;
	}

}

no Moose;

__PACKAGE__->meta->make_immutable;

1;    # End of Grades

=head1 AUTHOR

Dr Bean, C<< <drbean, followed by the at mark (@), cpan, then a dot, and finally, org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-grades at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Grades>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Grades

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Grades>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Grades>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Grades>

=item * Search CPAN

L<http://search.cpan.org/dist/Grades>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


# vim: set ts=8 sts=4 sw=4 noet:
__END__
